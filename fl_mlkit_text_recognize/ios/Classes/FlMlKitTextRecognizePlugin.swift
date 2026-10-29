import fl_camera
import fl_channel
import Flutter
import MLKitTextRecognition
import MLKitTextRecognitionChinese
import MLKitTextRecognitionDevanagari
import MLKitTextRecognitionJapanese
import MLKitTextRecognitionKorean
import MLKitVision
import UIKit

/// 文字识别插件。
///
/// 相机帧来自 fl_camera 的图像数据流，图片识别直接使用 UIImage，
/// 识别结果通过 MethodChannel 或事件通道返回。
public class FlMlKitTextRecognizePlugin: NSObject, FlutterPlugin {
    /// 识别结果事件通道，与相机通道区分。
    private static let eventChannelName = "fl.camera.ocr.event"

    private var channel: FlutterMethodChannel?
    private var options: CommonTextRecognizerOptions = TextRecognizerOptions()
    private var lastCurrentTime: TimeInterval = 0
    private var frequency: Double = 500
    private var canRecognize = true
    private var recognizer: TextRecognizer?
    private var bufferHandler: FlDataStreamHandlerCancel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.text.recognize", binaryMessenger: registrar.messenger())
        let instance = FlMlKitTextRecognizePlugin(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setParams":
            let arguments = call.arguments as? [String: Any]
            frequency = (arguments?["frequency"] as? NSNumber)?.doubleValue ?? 500
            canRecognize = arguments?["canRecognize"] as? Bool ?? true
            ensureBufferListener()
            result(true)
        case "setRecognizedLanguage":
            setRecognizedLanguage(call)
            recognizer = nil
            result(true)
        case "recognizeImageByte":
            let arguments = call.arguments as? [String: Any]
            guard let typedData = arguments?["byte"] as? FlutterStandardTypedData,
                  let image = UIImage(data: typedData.data) else {
                result(nil)
                return
            }
            analysis(image, result)
        case "dispose":
            releaseResources()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
        releaseResources()
    }

    /// 仅注册一次相机帧监听，参数变化时无需反复注册。
    private func ensureBufferListener() {
        guard bufferHandler == nil else { return }
        bufferHandler = FlCamera.shared.listenImageBuffer { [weak self] buffer in
            guard let self, self.canRecognize else { return }
            let currentTime = Date().timeIntervalSince1970 * 1000
            guard currentTime - self.lastCurrentTime >= self.frequency,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(buffer),
                  let image = pixelBuffer.image else { return }
            self.lastCurrentTime = currentTime
            self.analysis(image, nil, FlCamera.shared.cameraTexture?.imageOrientation() ?? .up)
        }
    }

    private func releaseResources() {
        bufferHandler?()
        bufferHandler = nil
        recognizer = nil
        lastCurrentTime = 0
    }

    private func setRecognizedLanguage(_ call: FlutterMethodCall) {
        switch call.arguments as? String {
        case "chinese":
            options = ChineseTextRecognizerOptions()
        case "japanese":
            options = JapaneseTextRecognizerOptions()
        case "korean":
            options = KoreanTextRecognizerOptions()
        case "devanagari":
            options = DevanagariTextRecognizerOptions()
        default:
            options = TextRecognizerOptions()
        }
    }

    private func getTextRecognition() -> TextRecognizer {
        if let recognizer { return recognizer }
        let newRecognizer = TextRecognizer.textRecognizer(options: options)
        recognizer = newRecognizer
        return newRecognizer
    }

    private func analysis(_ image: UIImage, _ result: FlutterResult? = nil, _ orientation: UIImage.Orientation? = nil) {
        let imageOrientation = orientation ?? image.imageOrientation
        let visionImage = VisionImage(image: image)
        visionImage.orientation = imageOrientation
        getTextRecognition().process(visionImage) { visionText, error in
            if error != nil {
                result?(nil)
                return
            }
            guard let visionText else {
                result?(nil)
                return
            }
            // ML Kit 的坐标基于旋转后的图片，需要按 EXIF 方向互换宽高。
            let rotated = imageOrientation == .left || imageOrientation == .right ||
                imageOrientation == .leftMirrored || imageOrientation == .rightMirrored
            var map = visionText.data
            map.updateValue(rotated ? image.size.width : image.size.height, forKey: "height")
            map.updateValue(rotated ? image.size.height : image.size.width, forKey: "width")
            if let result {
                result(map)
            } else {
                _ = FlChannelPlugin.getEventChannel(Self.eventChannelName)?.send(map)
            }
        }
    }
}

private let flTextCIContext = CIContext()

extension CVPixelBuffer {
    /// 把相机像素缓冲区转为 UIImage。
    var image: UIImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        guard let cgImage = flTextCIContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension CGRect {
    var data: [String: Any?] {
        [
            "x": origin.x,
            "y": origin.y,
            "width": width,
            "height": height,
        ]
    }
}

extension Text {
    var data: [String: Any?] {
        ["text": text, "textBlocks": blocks.map { $0.data }]
    }
}

extension TextBlock {
    var data: [String: Any?] {
        [
            "text": text,
            "recognizedLanguages": recognizedLanguages.map { $0.languageCode },
            "boundingBox": frame.data,
            "lines": lines.map { $0.data },
            "corners": cornerPoints.map { $0.cgPointValue.data },
        ]
    }
}

extension TextLine {
    var data: [String: Any?] {
        [
            "text": text,
            "recognizedLanguages": recognizedLanguages.map { $0.languageCode },
            "elements": elements.map { $0.data },
            "boundingBox": frame.data,
            "corners": cornerPoints.map { $0.cgPointValue.data },
        ]
    }
}

extension TextElement {
    var data: [String: Any?] {
        [
            "text": text,
            "boundingBox": frame.data,
            "corners": cornerPoints.map { $0.cgPointValue.data },
        ]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        ["x": NSNumber(value: x.native), "y": NSNumber(value: y.native)]
    }
}
