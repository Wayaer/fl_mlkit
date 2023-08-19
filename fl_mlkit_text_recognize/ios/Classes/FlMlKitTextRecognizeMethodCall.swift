import AVFoundation
import fl_camera
import Flutter
import Foundation
import MLKitTextRecognition
import MLKitTextRecognitionChinese
import MLKitTextRecognitionDevanagari
import MLKitTextRecognitionJapanese
import MLKitTextRecognitionKorean
import MLKitVision

class FlMlKitTextRecognizeMethodCall: FlCameraMethodCall {
    private var options: CommonTextRecognizerOptions = TextRecognizerOptions()
    private var canScan: Bool = false
    private var frequency: Double = 0
    private var lastCurrentTime: TimeInterval = 0
    private var recognizer: TextRecognizer?

    override init(_ _registrar: FlutterPluginRegistrar) {
        super.init(_registrar)
    }

    override func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startPreview":
            frequency = (call.arguments as! [String: Any?])["frequency"] as! Double
            startPreview({ [self] sampleBuffer in
                let currentTime = Date().timeIntervalSince1970 * 1000
                if currentTime - lastCurrentTime >= frequency, canScan {
                    let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                    analysis(buffer!.image, nil)
                    lastCurrentTime = currentTime
                }
            }, call: call, result)
        case "setRecognizedLanguage":
            setRecognizedLanguage(call)
            recognizer = nil
            result(true)
        case "scanImageByte":
            let arguments = call.arguments as! [AnyHashable: Any?]
            let useEvent = arguments["useEvent"] as! Bool
            let uint8list = arguments["byte"] as! FlutterStandardTypedData?
            if uint8list != nil {
                let image = UIImage(data: uint8list!.data)
                if image != nil {
                    analysis(image!, useEvent ? nil : result)
                    return
                }
            }
            result([])
        case "scan":
            canScan = call.arguments as! Bool
            result(true)
        case "dispose":
            dispose()
            result(true)
        default:
            super.handle(call: call, result: result)
        }
    }

    override func dispose() {
        super.dispose()
        recognizer = nil
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

    private func analysis(_ image: UIImage, _ result: FlutterResult?) {
        let visionImage = VisionImage(image: image)
        if flCamera == nil {
            visionImage.orientation = .up
        } else {
            visionImage.orientation = flCamera!.imageOrientation()
        }
        getTextRecognition().process(visionImage) { [self] visionText, error in
            if error == nil, visionText != nil {
                var map = visionText!.data
                map.updateValue(image.size.height, forKey: "height")
                map.updateValue(image.size.width, forKey: "width")
                if result == nil {
                    flCameraEvent?.sendEvent(map)
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
