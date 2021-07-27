import AVFoundation
import fl_camera
import Flutter
import Foundation
import MLKitBarcodeScanning
import MLKitVision

class FlMlKitScanningMethodCall: FlCameraMethodCall {
    var options = BarcodeScannerOptions(formats: .qrCode)

    override init(_ _registrar: FlutterPluginRegistrar) {
        super.init(_registrar)
    }

    override func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startPreview":
            startPreview(nil, call: call, result: result)
        case "setBarcodeFormat":
            setBarcodeFormat(call)
            result(true)
        case "scanImageByte":
            break
        default:
            super.handle(call: call, result: result)
        }
    }

    func setBarcodeFormat(_ call: FlutterMethodCall) {
        let arguments = call.arguments as! [String: Any?]
        let barcodeFormats = arguments["barcodeFormats"] as! [String]

        if !barcodeFormats.isEmpty {
            var formats = BarcodeFormat()
            for barcodeFomat in barcodeFormats {
                switch barcodeFomat {
                case "unknown":
                    break
                case "all":
                    formats.insert(.all)
                case "code128":
                    formats.insert(.code128)
                case "code39":
                    formats.insert(.code39)
                case "code93":
                    formats.insert(.code93)
                case "code_bar":
                    formats.insert(.codaBar)
                case "data_matrix":
                    formats.insert(.dataMatrix)
                case "ean13":
                    formats.insert(.EAN13)
                case "ean8":
                    formats.insert(.EAN8)
                case "itf":
                    formats.insert(.ITF)
                case "qr_code":
                    formats.insert(.qrCode)
                case "upc_a":
                    formats.insert(.UPCA)
                case "upc_e":
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

    func analysis(image: UIImage) {
//        let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = VisionImage(image: image)
        let scanner = BarcodeScanner.barcodeScanner(options: options)
        scanner.process(image) { [self] barcodes, error in
            if error == nil, barcodes != nil {
                var list = [[String: Any?]]()
                for barcode in barcodes! {
                    list.append(barcode.data)
                }
                flCameraEvent?.sendEvent(list)
            }
        }
    }
}

extension Barcode {
    var data: [String: Any?] {
        return ["cornerPoints": cornerPoints?.map { $0.cgPointValue.data }, "format": format.rawValue, "bytes": rawData, "value": rawValue, "type": valueType.rawValue, "calendarEvent": calendarEvent?.data, "contactInfo": contactInfo?.data, "driverLicense": driverLicense?.data, "email": email?.data, "geoPoint": geoPoint?.data, "phone": phone?.data, "sms": sms?.data, "url": url?.data, "wifi": wifi?.data]
    }
}

extension CGPoint {
    var data: [String: Any?] {
        return ["x": NSNumber(value: x.native), "y": NSNumber(value: y.native)]
    }
}

extension BarcodeCalendarEvent {
    var data: [String: Any?] {
        return ["description": eventDescription, "end": end?.rawValue, "location": location, "organizer": organizer, "start": start?.rawValue, "status": status, "summary": summary]
    }
}

extension Date {
    var rawValue: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

extension BarcodeContactInfo {
    var data: [String: Any?] {
        return ["addresses": addresses?.map { $0.data }, "emails": emails?.map { $0.data }, "name": name?.data, "organization": organization, "phones": phones?.map { $0.data }, "title": jobTitle, "urls": urls]
    }
}

extension BarcodeAddress {
    var data: [String: Any?] {
        return ["addressLines": addressLines, "type": type.rawValue]
    }
}

extension BarcodePersonName {
    var data: [String: Any?] {
        return ["first": first, "formattedName": formattedName, "last": last, "middle": middle, "prefix": prefix, "pronunciation": pronunciation, "suffix": suffix]
    }
}

extension BarcodeDriverLicense {
    var data: [String: Any?] {
        return ["addressCity": addressCity, "addressState": addressState, "addressStreet": addressStreet, "addressZip": addressZip, "birthDate": birthDate, "documentType": documentType, "expiryDate": expiryDate, "firstName": firstName, "gender": gender, "issueDate": issuingDate, "issuingCountry": issuingCountry, "lastName": lastName, "licenseNumber": licenseNumber, "middleName": middleName]
    }
}

extension BarcodeEmail {
    var data: [String: Any?] {
        return ["address": address, "body": body, "subject": subject, "type": type.rawValue]
    }
}

extension BarcodeGeoPoint {
    var data: [String: Any?] {
        return ["latitude": latitude, "longitude": longitude]
    }
}

extension BarcodePhone {
    var data: [String: Any?] {
        return ["number": number, "type": type.rawValue]
    }
}

extension BarcodeSMS {
    var data: [String: Any?] {
        return ["message": message, "phoneNumber": phoneNumber]
    }
}

extension BarcodeURLBookmark {
    var data: [String: Any?] {
        return ["title": title, "url": url]
    }
}

extension BarcodeWifi {
    var data: [String: Any?] {
        return ["encryptionType": type.rawValue, "password": password, "ssid": ssid]
    }
}
