import fl_camera
import Flutter
import UIKit

public class FlMlKitScanningPlugin: NSObject, FlutterPlugin {
    var flMlKitScanningChannel: FlutterMethodChannel?
    var flMlKitScanningMethodCall: FlMlKitScanningMethodCall?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.scanning",
                                           binaryMessenger: registrar.messenger())
        let instance = FlMlKitScanningPlugin(registrar, channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ _registrar: FlutterPluginRegistrar, _ _channel: FlutterMethodChannel) {
        flMlKitScanningChannel = _channel
        flMlKitScanningMethodCall = FlMlKitScanningMethodCall(_registrar)
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flMlKitScanningMethodCall?.handle(call: call, result: result)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        flMlKitScanningChannel?.setMethodCallHandler(nil)
        flMlKitScanningChannel = nil
    }
}
