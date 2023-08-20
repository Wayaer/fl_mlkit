import AVFoundation
import fl_camera
import fl_channel
import Flutter
import Foundation
import MLKitBarcodeScanning
import MLKitVision
import UIKit

public class FlMlKitScanningPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?

    private var options = BarcodeScannerOptions(formats: .all)
    private var lastCurrentTime: TimeInterval = 0
    private var scanner: BarcodeScanner?
    private var bufferHandler: FlDataStreamHandlerCancel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.scanning",
                                           binaryMessenger: registrar.messenger())
        let instance = FlMlKitScanningPlugin(channel)
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
            let canScanning = arguments["canScanning"] as! Bool
            bufferHandler?()
            bufferHandler = nil
            bufferHandler = FlCamera.shared.flDataStream.listen { [self] buffer in
                let currentTime = Date().timeIntervalSince1970 * 1000
                if currentTime - lastCurrentTime >= frequency, canScanning {
                    let buffer = CMSampleBufferGetImageBuffer(buffer)
                    analysis(buffer!.image, nil)
                    lastCurrentTime = currentTime
                }
            }
            result(true)
        case "setBarcodeFormat":
            setBarcodeFormat(call)
            scanner = nil
            result(true)
        case "scanningImageByte":
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
            result(nil)
        case "dispose":
            scanner = nil
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

    func setBarcodeFormat(_ call: FlutterMethodCall) {
        let barcodeFormats = call.arguments as! [String]
        if !barcodeFormats.isEmpty {
            var formats = BarcodeFormat()
            for barcodeFormat in barcodeFormats {
                switch barcodeFormat {
                case "unknown":
                    formats.insert(.all)
                case "all":
                    formats.insert(.all)
                case "code128":
                    formats.insert(.code128)
                case "code39":
                    formats.insert(.code39)
                case "code93":
                    formats.insert(.code93)
                case "codaBar":
                    formats.insert(.codaBar)
                case "dataMatrix":
                    formats.insert(.dataMatrix)
                case "ean13":
                    formats.insert(.EAN13)
                case "ean8":
                    formats.insert(.EAN8)
                case "itf":
                    formats.insert(.ITF)
                case "qrCode":
                    formats.insert(.qrCode)
                case "upcA":
                    formats.insert(.UPCA)
                case "upcE":
                    formats.insert(.UPCE)
                case "pdf417":
                    formats.insert(.PDF417)
                case "aztec":
                    formats.insert(.aztec)
                default:
                    break
                }
            }
            options = BarcodeScannerOptions(formats: formats)
        }
    }

    private func getBarcodeScanner() -> BarcodeScanner {
        if scanner == nil {
            scanner = BarcodeScanner.barcodeScanner(options: options)
        }
        return scanner!
    }

    func analysis(_ image: UIImage, _ result: FlutterResult?) {
        let visionImage = VisionImage(image: image)
        if FlCamera.shared.cameraTexture == nil {
            visionImage.orientation = .up
        } else {
            visionImage.orientation = FlCamera.shared.cameraTexture!.imageOrientation()
        }
        getBarcodeScanner().process(visionImage) { barcodes, error in
            if error == nil, barcodes != nil {
                var list = [[String: Any?]]()
                for barcode in barcodes! {
                    list.append(barcode.data)
                }
                let map = [
                    "height": image.size.height,
                    "width": image.size.width,
                    "barcodes": list
                ] as [String: Any?]
                if result == nil {
                    if !list.isEmpty {
                        FlEvent.shared.send(map)
                    }
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
            "height": height
        ]
    }
}

extension Barcode {
    var data: [String: Any?] {
        ["corners": cornerPoints?.map {
            $0.cgPointValue.data
        },
        "format": format.rawValue,
        "bytes": rawData,
        "value": rawValue,
        "type": valueType.rawValue,
        "calendarEvent": calendarEvent?.data,
        "contactInfo": contactInfo?.data,
        "driverLicense": driverLicense?.data,
        "email": email?.data,
        "geoPoint": geoPoint?.data,
        "phone": phone?.data,
        "sms": sms?.data,
        "url": url?.data,
        "wifi": wifi?.data,
        "displayValue": displayValue,
        "boundingBox": frame.data]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        ["x": NSNumber(value: x.native), "y": NSNumber(value: y.native)]
    }
}

extension BarcodeCalendarEvent {
    var data: [String: Any?] {
        ["description": eventDescription, "end": end?.rawValue, "location": location, "organizer": organizer, "start": start?.rawValue, "status": status, "summary": summary]
    }
}

extension Date {
    var rawValue: String {
        ISO8601DateFormatter().string(from: self)
    }
}

extension BarcodeContactInfo {
    var data: [String: Any?] {
        ["addresses": addresses?.map {
            $0.data
        }, "emails": emails?.map {
            $0.data
        }, "name": name?.data, "organization": organization, "phones": phones?.map {
            $0.data
        }, "title": jobTitle, "urls": urls]
    }
}

extension BarcodeAddress {
    var data: [String: Any?] {
        ["addressLines": addressLines, "type": type.rawValue]
    }
}

extension BarcodePersonName {
    var data: [String: Any?] {
        ["first": first, "formattedName": formattedName, "last": last, "middle": middle, "prefix": prefix, "pronunciation": pronunciation, "suffix": suffix]
    }
}

extension BarcodeDriverLicense {
    var data: [String: Any?] {
        ["addressCity": addressCity, "addressState": addressState, "addressStreet": addressStreet, "addressZip": addressZip, "birthDate": birthDate, "documentType": documentType, "expiryDate": expiryDate, "firstName": firstName, "gender": gender, "issueDate": issuingDate, "issuingCountry": issuingCountry, "lastName": lastName, "licenseNumber": licenseNumber, "middleName": middleName]
    }
}

extension BarcodeEmail {
    var data: [String: Any?] {
        ["address": address, "body": body, "subject": subject, "type": type.rawValue]
    }
}

extension BarcodeGeoPoint {
    var data: [String: Any?] {
        ["latitude": latitude, "longitude": longitude]
    }
}

extension BarcodePhone {
    var data: [String: Any?] {
        ["number": number, "type": type.rawValue]
    }
}

extension BarcodeSMS {
    var data: [String: Any?] {
        ["message": message, "phoneNumber": phoneNumber]
    }
}

extension BarcodeURLBookmark {
    var data: [String: Any?] {
        ["title": title, "url": url]
    }
}

extension BarcodeWifi {
    var data: [String: Any?] {
        ["encryptionType": type.rawValue, "password": password, "ssid": ssid]
    }
}
