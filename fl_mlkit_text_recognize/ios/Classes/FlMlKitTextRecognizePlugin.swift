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

public class FlMlKitTextRecognizePlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?

    private var options: CommonTextRecognizerOptions = TextRecognizerOptions()
    private var lastCurrentTime: TimeInterval = 0
    private var recognizer: TextRecognizer?
    private var bufferHandler: FlDataStreamHandlerCancel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.text.recognize",
                                           binaryMessenger: registrar.messenger())
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
            let arguments = call.arguments as! [AnyHashable: Any?]
            let frequency = arguments["frequency"] as! Double
            let canRecognize = arguments["canRecognize"] as! Bool
            bufferHandler?()
            bufferHandler = nil
            bufferHandler = FlCamera.shared.flDataStream.listen { [self] buffer in
                let currentTime = Date().timeIntervalSince1970 * 1000
                if currentTime - lastCurrentTime >= frequency, canRecognize {
                    let buffer = CMSampleBufferGetImageBuffer(buffer)
                    analysis(buffer!.image)
                    lastCurrentTime = currentTime
                }
            }
            result(true)
        case "setRecognizedLanguage":
            setRecognizedLanguage(call)
            recognizer = nil
            result(true)
        case "recognizeImageByte":
            let arguments = call.arguments as! [AnyHashable: Any?]
            let uint8list = arguments["byte"] as! FlutterStandardTypedData?
            if uint8list != nil {
                let image = UIImage(data: uint8list!.data)
                if image != nil {
                    analysis(image!, result)
                    return
                }
            }
            result(nil)
        case "dispose":
            recognizer = nil
            bufferHandler?()
            bufferHandler = nil
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
    }

    private func setRecognizedLanguage(_ call: FlutterMethodCall) {
        let type = call.arguments as! String
        switch type {
        case "latin":
            options = TextRecognizerOptions()
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
        if recognizer == nil {
            recognizer = TextRecognizer.textRecognizer(options: options)
        }
        return recognizer!
    }

    private func analysis(_ image: UIImage, _ result: FlutterResult? = nil) {
        let visionImage = VisionImage(image: image)
        if FlCamera.shared.cameraTexture == nil {
            visionImage.orientation = .up
        } else {
            visionImage.orientation = FlCamera.shared.cameraTexture!.imageOrientation()
        }
        getTextRecognition().process(visionImage) { visionText, error in
            if error == nil, visionText != nil {
                var map = visionText!.data
                map.updateValue(image.size.height, forKey: "height")
                map.updateValue(image.size.width, forKey: "width")
                if result == nil {
                    _ = FlCamera.shared.flEvent?.send(map)
                } else {
                    result!(map)
                }
            }
        }
    }
}

extension CVBuffer {
    var image: UIImage {
        let ciImage = CIImage(cvPixelBuffer: self)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        return UIImage(cgImage: cgImage!)
    }

    var image1: UIImage {
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        // let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage()
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Create an image object from the Quartz image
        return UIImage(cgImage: quartzImage!)
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
        ["text": text,
         "textBlocks": blocks.map {
             $0.data
         }]
    }
}

extension TextBlock {
    var data: [String: Any?] {
        ["text": text,
         "recognizedLanguages": recognizedLanguages.map {
             $0.languageCode
         },
         "boundingBox": frame.data,
         "lines": lines.map {
             $0.data
         },
         "corners": cornerPoints.map {
             $0.cgPointValue.data
         }]
    }
}

extension TextLine {
    var data: [String: Any?] {
        ["text": text,
         "recognizedLanguages": recognizedLanguages.map {
             $0.languageCode
         },
         "elements": elements.map {
             $0.data
         },
         "boundingBox": frame.data,
         "corners": cornerPoints.map {
             $0.cgPointValue.data
         }]
    }
}

extension TextElement {
    var data: [String: Any?] {
        ["text": text,
         "boundingBox": frame.data,
         "corners": cornerPoints.map {
             $0.cgPointValue.data
         }]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        ["x": NSNumber(value: x.native), "y": NSNumber(value: y.native)]
    }
}
