import AVFoundation
import fl_camera
import fl_channel
import Flutter
import Foundation
import MLKitBarcodeScanning
import MLKitVision
import UIKit

/// 条码扫描插件。
///
/// 相机帧来自 fl_camera 的图像数据流，图片扫描直接使用 UIImage，
/// 识别结果通过 MethodChannel 或事件通道返回。
public class FlMlKitScanningPlugin: NSObject, FlutterPlugin {
    /// 扫码结果事件通道，与相机通道区分。
    private static let eventChannelName = "fl.camera.scanning.event"

    private var channel: FlutterMethodChannel?
    private var options = BarcodeScannerOptions(formats: .all)
    private var lastCurrentTime: TimeInterval = 0
    private var frequency: Double = 500
    private var canScanning = true
    private var scanner: BarcodeScanner?
    private var bufferHandler: FlDataStreamHandlerCancel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.scanning", binaryMessenger: registrar.messenger())
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
            let arguments = call.arguments as? [String: Any]
            frequency = (arguments?["frequency"] as? NSNumber)?.doubleValue ?? 500
            canScanning = arguments?["canScanning"] as? Bool ?? true
            ensureBufferListener()
            result(true)
        case "setBarcodeFormat":
            setBarcodeFormat(call)
            scanner = nil
            result(true)
        case "scanningImageByte":
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
            guard let self, self.canScanning else { return }
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
        scanner = nil
        lastCurrentTime = 0
    }

    private func setBarcodeFormat(_ call: FlutterMethodCall) {
        // 空列表与 Android 保持一致：识别全部格式。
        let barcodeFormats = call.arguments as? [String] ?? []
        var formats = BarcodeFormat()
        for barcodeFormat in barcodeFormats {
            switch barcodeFormat {
            case "unknown", "all":
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
        options = formats.isEmpty ? BarcodeScannerOptions(formats: .all) : BarcodeScannerOptions(formats: formats)
    }

    private func getBarcodeScanner() -> BarcodeScanner {
        if let scanner { return scanner }
        let newScanner = BarcodeScanner.barcodeScanner(options: options)
        scanner = newScanner
        return newScanner
    }

    private func analysis(_ image: UIImage, _ result: FlutterResult? = nil, _ orientation: UIImage.Orientation? = nil) {
        let imageOrientation = orientation ?? image.imageOrientation
        let visionImage = VisionImage(image: image)
        visionImage.orientation = imageOrientation
        getBarcodeScanner().process(visionImage) { barcodes, error in
            if error != nil {
                result?(nil)
                return
            }
            guard let barcodes else {
                result?(nil)
                return
            }
            var list = [[String: Any?]]()
            for barcode in barcodes {
                list.append(barcode.data)
            }
            // ML Kit 的坐标基于旋转后的图片，需要按 EXIF 方向互换宽高。
            let rotated = imageOrientation == .left || imageOrientation == .right ||
                imageOrientation == .leftMirrored || imageOrientation == .rightMirrored
            let map: [String: Any?] = [
                "height": rotated ? image.size.width : image.size.height,
                "width": rotated ? image.size.height : image.size.width,
                "barcodes": list,
            ]
            if let result {
                result(map)
            } else if !list.isEmpty {
                _ = FlChannelPlugin.getEventChannel(Self.eventChannelName)?.send(map)
            }
        }
    }
}

private let flBarcodeCIContext = CIContext()

extension CVPixelBuffer {
    /// 把相机像素缓冲区转为 UIImage。
    var image: UIImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        guard let cgImage = flBarcodeCIContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
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

extension Barcode {
    var data: [String: Any?] {
        [
            "corners": cornerPoints?.map { $0.cgPointValue.data },
            "format": format.rawValue,
            // Flutter 只支持 FlutterStandardTypedData，直接传 Data 会在编码时断言失败。
            "bytes": rawData.map { FlutterStandardTypedData(bytes: $0) },
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
            "boundingBox": frame.data,
        ]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        ["x": NSNumber(value: x.native), "y": NSNumber(value: y.native)]
    }
}

extension BarcodeCalendarEvent {
    var data: [String: Any?] {
        [
            "description": eventDescription,
            "end": end?.rawValue,
            "location": location,
            "organizer": organizer,
            "start": start?.rawValue,
            "status": status,
            "summary": summary,
        ]
    }
}

extension Date {
    var rawValue: String {
        ISO8601DateFormatter().string(from: self)
    }
}

extension BarcodeContactInfo {
    var data: [String: Any?] {
        [
            "addresses": addresses?.map { $0.data },
            "emails": emails?.map { $0.data },
            "name": name?.data,
            "organization": organization,
            "phones": phones?.map { $0.data },
            "title": jobTitle,
            "urls": urls,
        ]
    }
}

extension BarcodeAddress {
    var data: [String: Any?] {
        ["addressLines": addressLines, "type": type.rawValue]
    }
}

extension BarcodePersonName {
    var data: [String: Any?] {
        [
            "first": first,
            "formattedName": formattedName,
            "last": last,
            "middle": middle,
            "prefix": prefix,
            "pronunciation": pronunciation,
            "suffix": suffix,
        ]
    }
}

extension BarcodeDriverLicense {
    var data: [String: Any?] {
        [
            "addressCity": addressCity,
            "addressState": addressState,
            "addressStreet": addressStreet,
            "addressZip": addressZip,
            "birthDate": birthDate,
            "documentType": documentType,
            "expiryDate": expiryDate,
            "firstName": firstName,
            "gender": gender,
            "issueDate": issuingDate,
            "issuingCountry": issuingCountry,
            "lastName": lastName,
            "licenseNumber": licenseNumber,
            "middleName": middleName,
        ]
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
