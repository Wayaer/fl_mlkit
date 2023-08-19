import Flutter
import Foundation

public class FlCameraEvent: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    var eventChannel: FlutterEventChannel?

    init(_ messenger: FlutterBinaryMessenger) {
        super.init()
        eventChannel = FlutterEventChannel(name: "fl.camera.event", binaryMessenger: messenger)
        eventChannel!.setStreamHandler(self)
    }

    public func sendEvent(_ arguments: Any?) {
        eventSink?(arguments)
    }

    func dispose() {
        eventSink = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
    }

    public func onListen(withArguments arguments: Any?, eventSink event: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = event
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        dispose()
        return nil
    }
}
