import Flutter
import UIKit

public class FlMlKitTextRecognizePlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?
    var methodCall: FlMlKitTextRecognizeMethodCall?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.mlkit.text.recognize",
                binaryMessenger: registrar.messenger())
        let instance = FlMlKitTextRecognizePlugin(registrar, channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ _registrar: FlutterPluginRegistrar, _ _channel: FlutterMethodChannel) {
        channel = _channel
        methodCall = FlMlKitTextRecognizeMethodCall(_registrar)
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
