import fl_camera
import Flutter
import UIKit

public class FlMlKitScanningPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?
    var methodCall: FlMlKitScanningMethodCall?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.scanning",
                binaryMessenger: registrar.messenger())
        let instance = FlMlKitScanningPlugin(registrar, channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ _registrar: FlutterPluginRegistrar, _ _channel: FlutterMethodChannel) {
        channel = _channel
        methodCall = FlMlKitScanningMethodCall(_registrar)
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        methodCall?.handle(call: call, result: result)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
    }
}
