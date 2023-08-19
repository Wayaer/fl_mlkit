import AVFoundation
import Flutter
import Foundation

open class FlCameraMethodCall: NSObject {
    public var flCameraEvent: FlCameraEvent?
    public var registrar: FlutterPluginRegistrar?
    public var flCamera: FlCamera?

    public init(_ _registrar: FlutterPluginRegistrar) {
        super.init()
        registrar = _registrar
    }

    open func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "availableCameras":
            availableCameras(result)
        case "initialize":
            if flCamera == nil, flCameraEvent != nil, registrar != nil {
                flCamera = FlCamera(flCameraEvent!, registrar!.textures())
            }
            result(flCamera != nil)
        case "startPreview":
            startPreview(nil, call: call, result)
        case "stopPreview":
            flCamera?.dispose()
            result(flCamera != nil)
        case "setFlashMode":
            flCamera?.setFlashMode(status: call.arguments as! Int)
            result(flCamera != nil)
        case "setZoomRatio":
            flCamera?.setZoomRatio(ratio: call.arguments as! Double)
            result(flCamera != nil)
        case "dispose":
            flCamera?.dispose()
            flCamera = nil
            result(flCamera == nil)
        case "startEvent":
            if flCameraEvent == nil, registrar != nil {
                flCameraEvent = FlCameraEvent(registrar!.messenger())
            }
            result(flCameraEvent != nil)
        case "sendEvent":
            flCameraEvent?.sendEvent(call.arguments)
            result(flCameraEvent != nil)
        case "stopEvent":
            disposeEvent()
            result(flCameraEvent == nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    open func startPreview(_ captureOutputCallBack: ((_ buffer: CMSampleBuffer) -> Void)?, call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [String: Any?]
        let cameraId = arguments["cameraId"] as! String
        let resolution = arguments["resolution"] as! String
        if flCamera == nil || AVCaptureDevice.authorizationStatus(for: .video) != AVAuthorizationStatus.authorized {
            result(nil)
            return
        }
        flCamera!.initCamera(resolution, cameraId, result, captureOutputCallBack)
    }

    func disposeEvent() {
        if flCameraEvent != nil {
            flCameraEvent!.dispose()
            flCameraEvent = nil
        }
    }

    open func dispose() {
        disposeEvent()
        flCamera?.dispose()
        flCamera = nil
    }

    func availableCameras(_ result: @escaping FlutterResult) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified)
        let devices = discoverySession.devices
        var reply = [[String: Any?]]()
        for device in devices {
            var lensFacing: String?
            switch device.position {
            case .back:
                lensFacing = "back"
            case .front:
                lensFacing = "front"
            case .unspecified:
                lensFacing = "external"
            @unknown default:
                lensFacing = "external"
            }
            reply.append([
                "name": device.uniqueID,
                "lensFacing": lensFacing,
            ])
        }
        result(reply)
    }
}
