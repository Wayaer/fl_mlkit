import AVFoundation
import fl_channel
import Flutter
import Foundation

/// fl_camera 原生实现入口。
///
/// 负责 MethodChannel 方法分发、摄像头枚举，并向下游插件暴露相机图像数据流。
public class FlCamera: NSObject {
    /// 默认事件通道名称。
    public static let defaultEventChannelName = "fl.camera.event"

    /// 当前 Flutter 插件注册器。
    public var registrar: FlutterPluginRegistrar?

    /// 当前相机纹理。
    public var cameraTexture: FlCameraTexture?

    /// 相机图像数据流，供扫码、文字识别等插件订阅。
    public var flDataStream = FlDataStream<CMSampleBuffer>()

    /// 各控制器注册的事件通道，按通道名区分相机 / 扫码 / OCR。
    private var eventChannels: [String: FlEventChannel] = [:]

    /// 保护 [eventChannels]：初始化在主线程，发送可能来自采集 / ML Kit 线程。
    private let eventChannelsLock = NSLock()

    private var imageListenerCount = 0

    /// 是否存在图像订阅者。
    public var hasImageListener: Bool { imageListenerCount > 0 }

    public static let shared = FlCamera()

    /// 构造统一格式的 Flutter 错误。
    static func error(_ code: String, _ message: String) -> FlutterError {
        FlutterError(code: code, message: message, details: nil)
    }

    /// 订阅相机图像帧，返回取消订阅的函数。
    public func listenImageBuffer(_ handler: @escaping FlDataStreamHandler<CMSampleBuffer>) -> FlDataStreamHandlerCancel {
        imageListenerCount += 1
        let cancel = flDataStream.listen(handler)
        var cancelled = false
        return { [weak self] in
            // 取消函数可能被下游重复调用，保证计数只减一次。
            guard !cancelled else { return }
            cancelled = true
            cancel()
            guard let self else { return }
            imageListenerCount = max(0, imageListenerCount - 1)
        }
    }

    /// 绑定 Flutter 插件注册器。
    public func binding(_ registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    /// 注册控制器的事件通道，供发送相机事件时广播。
    public func registerEventChannel(_ name: String) {
        guard let channel = FlChannelPlugin.getEventChannel(name) else { return }
        eventChannelsLock.lock()
        eventChannels[name] = channel
        eventChannelsLock.unlock()
    }

    /// 注销控制器的事件通道。
    public func unregisterEventChannel(_ name: String) {
        eventChannelsLock.lock()
        eventChannels.removeValue(forKey: name)
        eventChannelsLock.unlock()
    }

    /// 向所有已注册的事件通道发送事件。
    public func sendEvent(_ data: Any?) {
        eventChannelsLock.lock()
        let channels = Array(eventChannels.values)
        eventChannelsLock.unlock()
        for channel in channels {
            _ = channel.send(data)
        }
    }

    /// 向除 `excluded` 外的所有事件通道发送事件。
    public func sendEventExcept(_ excluded: String?, _ data: Any?) {
        eventChannelsLock.lock()
        let channels = eventChannels.filter { $0.key != excluded }.map { $0.value }
        eventChannelsLock.unlock()
        for channel in channels {
            _ = channel.send(data)
        }
    }

    /// 释放相机时清空所有事件通道（引擎 detach 使用）。
    public func clearEventChannels() {
        eventChannelsLock.lock()
        eventChannels.removeAll()
        eventChannelsLock.unlock()
    }

    /// 相机系统授权：未决定时弹窗申请，已拒绝或受限时直接返回 false。
    private func requestCameraAccess(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    /// 处理 Flutter 方法调用。
    public func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "availableCameras":
            availableCameras(result)
        case "initialize":
            // 每个控制器使用独立事件通道，初始化时重新注册。
            let arguments = call.arguments as? [String: Any]
            let eventChannelName = arguments?["eventChannelName"] as? String ?? FlCamera.defaultEventChannelName
            registerEventChannel(eventChannelName)
            if cameraTexture == nil, let registrar = registrar {
                let texture = FlCameraTexture(registrar.textures())
                texture.onPreviewSizeChanged = { [weak self] size in
                    self?.sendEvent(["previewWidth": size.width, "previewHeight": size.height])
                }
                cameraTexture = texture
            }
            // 未授权时由插件发起系统授权申请，拒绝后返回 permissionDenied。
            requestCameraAccess { [weak self] granted in
                guard let self else {
                    result(FlCamera.error("cameraInitFailed", "Camera is unavailable."))
                    return
                }
                if granted, self.cameraTexture != nil {
                    result(true)
                } else if granted {
                    result(FlCamera.error("cameraInitFailed", "Camera texture is unavailable."))
                } else {
                    result(FlCamera.error("permissionDenied", "Camera permission has not been granted."))
                }
            }
        case "startPreview":
            guard let arguments = call.arguments as? [String: Any],
                  let cameraId = arguments["cameraId"] as? String,
                  let resolution = arguments["resolution"] as? String else {
                result(FlCamera.error("invalidArguments", "cameraId and resolution are required."))
                return
            }
            guard let cameraTexture else {
                result(FlCamera.error("notInitialized", "Camera has not been initialized."))
                return
            }
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                result(FlCamera.error("permissionDenied", "Camera permission has not been granted."))
                return
            }
            cameraTexture.setFollowDeviceOrientation(arguments["followDeviceOrientation"] as? Bool ?? false)
            cameraTexture.initCamera(resolution, cameraId, result) { [weak self] buffer in
                self?.flDataStream.send(buffer)
            }
        case "stopPreview":
            cameraTexture?.dispose()
            result(true)
        case "setFlashMode":
            guard let index = call.arguments as? Int else {
                result(false)
                return
            }
            result(cameraTexture?.setFlashMode(status: index) ?? false)
        case "setZoomRatio":
            guard let ratio = call.arguments as? Double else {
                result(false)
                return
            }
            result(cameraTexture?.setZoomRatio(ratio: ratio) ?? false)
        case "dispose":
            let arguments = call.arguments as? [String: Any]
            let eventChannelName = arguments?["eventChannelName"] as? String ?? FlCamera.defaultEventChannelName
            // 原生相机只能有一个，释放后通知其他仍挂载的控制器重新初始化。
            sendEventExcept(eventChannelName, ["disposed": true])
            unregisterEventChannel(eventChannelName)
            cameraTexture?.dispose()
            cameraTexture = nil
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func availableCameras(_ result: @escaping FlutterResult) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        var reply = [[String: Any?]]()
        for device in discoverySession.devices {
            let lensFacing: String
            switch device.position {
            case .back:
                lensFacing = "back"
            case .front:
                lensFacing = "front"
            default:
                lensFacing = "external"
            }
            reply.append(["name": device.uniqueID, "lensFacing": lensFacing])
        }
        result(reply)
    }
}
