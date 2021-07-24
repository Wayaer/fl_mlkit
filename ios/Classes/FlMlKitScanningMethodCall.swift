import Flutter
import Foundation

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
