import Flutter
import UIKit

public class FlCameraPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.camera", binaryMessenger: registrar.messenger())
        let instance = FlCameraPlugin(channel)
        FlCamera.shared.binding(registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        FlCamera.shared.handle(call, result)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
    }
}
