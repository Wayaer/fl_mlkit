import AVFoundation
import Flutter
import Foundation
import MLKitBarcodeScanning
import MLKitVision

public class FlMlKitScanningMethodCall: NSObject {
    var registrar: FlutterPluginRegistrar?

    init(_ _registrar: FlutterPluginRegistrar) {
        super.init()
        registrar = _registrar
    }

    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {}

//    let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//    let image = VisionImage(image: buffer!.image)
//    let scanner = BarcodeScanner.barcodeScanner()
//    scanner.process(image) { [self] barcodes, error in
//        if error == nil && barcodes != nil {
//            for barcode in barcodes! {
//                let event: [String: Any?] = ["name": "barcode", "data": barcode.data]
//                sink?(event)
//            }
//        }
//        analyzing = false
//    }
}

extension Barcode {
    var data: [String: Any?] {
        return ["cornerPoints": cornerPoints?.map({ $0.cgPointValue.data }), "format": format.rawValue, "bytes": rawData, "value": rawValue, "type": valueType.rawValue, "calendarEvent": calendarEvent?.data, "contactInfo": contactInfo?.data, "driverLicense": driverLicense?.data, "email": email?.data, "geoPoint": geoPoint?.data, "phone": phone?.data, "sms": sms?.data, "url": url?.data, "wifi": wifi?.data]
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
        return ["addresses": addresses?.map({ $0.data }), "emails": emails?.map({ $0.data }), "name": name?.data, "organization": organization, "phones": phones?.map({ $0.data }), "title": jobTitle, "urls": urls]
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
