import AVFoundation
import Flutter
import Foundation

public class FlCamera: NSObject {
    public var registrar: FlutterPluginRegistrar?
    public var cameraTexture: FlCameraTexture?

    public var captureOutputCallBack: ((_ buffer: CMSampleBuffer) -> Void)?

    public static let shared = FlCamera()

    public func binding(_ registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    public func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "availableCameras":
            availableCameras(result)
        case "initialize":
            if cameraTexture == nil {
                cameraTexture = FlCameraTexture(registrar!.textures())
            }
            result(cameraTexture != nil)
        case "startPreview":
            startPreview(call: call, result)
        case "stopPreview":
            cameraTexture?.dispose()
            result(cameraTexture != nil)
        case "setFlashMode":
            cameraTexture?.setFlashMode(status: call.arguments as! Int)
            result(cameraTexture != nil)
        case "setZoomRatio":
            cameraTexture?.setZoomRatio(ratio: call.arguments as! Double)
            result(cameraTexture != nil)
        case "dispose":
            cameraTexture?.dispose()
            cameraTexture = nil
            result(cameraTexture == nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func startPreview(call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [String: Any?]
        let cameraId = arguments["cameraId"] as! String
        let resolution = arguments["resolution"] as! String
        if cameraTexture == nil || AVCaptureDevice.authorizationStatus(for: .video) != AVAuthorizationStatus.authorized {
            result(nil)
            return
        }
        cameraTexture!.initCamera(resolution, cameraId, result, captureOutputCallBack)
    }

    func dispose() {
        cameraTexture?.dispose()
        cameraTexture = nil
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
