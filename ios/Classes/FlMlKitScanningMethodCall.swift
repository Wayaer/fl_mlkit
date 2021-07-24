import Flutter
import Foundation

public class FlMlKitScanningMethodCall: FlCameraMethodCall {
    var registrar: FlutterPluginRegistrar?

    init(_ _registrar: FlutterPluginRegistrar) {
        super.init()
        registrar = _registrar
    }

    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {}
}
