import AVFoundation
import Flutter
import Foundation
import UIKit

/// 相机纹理。
///
/// 使用 AVCaptureSession + AVCaptureVideoDataOutput 采集画面，
/// 通过 FlutterTexture 把每一帧交给 Flutter 渲染。
public class FlCameraTexture: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var videoOutput: AVCaptureVideoDataOutput?

    private var latestPixelBuffer: CVPixelBuffer?
    private var registry: FlutterTextureRegistry
    private var previewSize: CGSize?
    private var textureId: Int64?
    private var captureOutputCallBack: ((CMSampleBuffer) -> Void)?
    private var isObservingDevice = false
    private var wasInterrupted = false

    /// 是否让预览跟随设备方向旋转（仅宿主自行控制屏幕方向时开启）。
    private var followsDeviceOrientation = false

    /// 当前采集连接方向，用于设备方向无效（平放 / 未知）时保持上一次方向。
    private var currentVideoOrientation: AVCaptureVideoOrientation = .portrait

    private var deviceOrientationObserver: NSObjectProtocol?

    /// 预览尺寸变化回调，设备旋转导致横竖屏切换时触发。
    public var onPreviewSizeChanged: ((CGSize) -> Void)?

    /// 保护 [latestPixelBuffer] 与 [textureId]：采集在 [captureQueue]，释放与 Flutter 取帧在其他线程。
    private let stateLock = NSLock()

    /// 采集与图像回调队列，避免占用主线程。
    private let captureQueue = DispatchQueue(label: "fl.camera.capture")

    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        super.init()
    }

    /// 初始化相机并注册纹理。
    ///
    /// - Parameters:
    ///   - resolution: 分辨率预设名。
    ///   - cameraId: 摄像头唯一标识。
    ///   - result: Flutter 回调，成功返回纹理与尺寸，失败返回 nil。
    ///   - captureOutputCallBack: 每一帧的图像回调。
    public func initCamera(
        _ resolution: String,
        _ cameraId: String,
        _ result: @escaping FlutterResult,
        _ captureOutputCallBack: ((CMSampleBuffer) -> Void)? = nil
    ) {
        dispose()
        stateLock.lock()
        self.captureOutputCallBack = captureOutputCallBack
        stateLock.unlock()
        guard let device = AVCaptureDevice(uniqueID: cameraId) else {
            result(FlCamera.error("cameraNotFound", "Camera device is unavailable."))
            return
        }
        stateLock.lock()
        self.device = device
        stateLock.unlock()
        let session = AVCaptureSession()
        captureSession = session
        session.beginConfiguration()
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch {
            session.commitConfiguration()
            dispose()
            result(FlCamera.error("cameraInitFailed", "Failed to create camera input: \(error.localizedDescription)"))
            return
        }
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: captureQueue)
        stateLock.lock()
        videoOutput = output
        stateLock.unlock()
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            session.commitConfiguration()
            dispose()
            result(FlCamera.error("cameraInitFailed", "Unable to add camera input."))
            return
        }
        guard session.canAddOutput(output) else {
            // 加不了输出就会出现「返回成功但永远没有画面」的黑屏，必须视为失败。
            session.commitConfiguration()
            dispose()
            result(FlCamera.error("cameraInitFailed", "Unable to add camera output."))
            return
        }
        session.addOutput(output)
        for connection in output.connections where device.position == .front && connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        setCaptureSessionPreset(resolution)
        session.commitConfiguration()
        updateOrientationObservation()
        updateConnectionOrientation()
        let registeredTextureId = registry.register(self)
        stateLock.lock()
        textureId = registeredTextureId
        stateLock.unlock()
        guard let previewSize else {
            dispose()
            result(FlCamera.error("cameraInitFailed", "Unsupported preview resolution."))
            return
        }
        addDeviceObservers()
        addSessionObservers(session)
        let displaySize = orientedPreviewSize(currentVideoOrientation) ?? previewSize
        let payload: [String: Any] = [
            "textureId": registeredTextureId,
            "width": displaySize.width,
            "height": displaySize.height,
        ]
        captureQueue.async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                guard let self, self.captureSession === session else {
                    result(nil)
                    return
                }
                if session.isRunning {
                    result(payload)
                } else {
                    self.dispose()
                    result(FlCamera.error("cameraInitFailed", "Capture session failed to start."))
                }
            }
        }
    }

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // 一次性在同一把锁内取出输出、纹理与回调，避免 dispose 并发时读到已释放的状态。
        stateLock.lock()
        guard output == videoOutput, let currentTextureId = textureId else {
            stateLock.unlock()
            return
        }
        latestPixelBuffer = pixelBuffer
        let callback = captureOutputCallBack
        stateLock.unlock()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentTextureId() == currentTextureId else { return }
            self.registry.textureFrameAvailable(currentTextureId)
        }
        callback?(sampleBuffer)
    }

    /// 线程安全地读取当前纹理 ID。
    private func currentTextureId() -> Int64? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return textureId
    }

    /// 当前相机画面的 ML Kit 方向。
    ///
    /// `AVCaptureVideoDataOutput` 会按 `videoOrientation` 物理旋转像素缓冲区，
    /// 缓冲区始终与界面方向一致，因此送入 ML Kit 时不需要再次旋转。
    public func imageOrientation() -> UIImage.Orientation {
        .up
    }

    /// 设置预览是否跟随设备方向旋转。
    ///
    /// 仅在宿主自行控制屏幕方向（`lockPortrait: false`）时开启；关闭时固定竖屏。
    public func setFollowDeviceOrientation(_ follow: Bool) {
        guard followsDeviceOrientation != follow else { return }
        followsDeviceOrientation = follow
        updateOrientationObservation()
        updateConnectionOrientation()
    }

    /// 根据当前设置注册或移除设备方向监听。
    private func updateOrientationObservation() {
        guard followsDeviceOrientation else {
            removeDeviceOrientationObserver()
            return
        }
        guard deviceOrientationObserver == nil else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        deviceOrientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateConnectionOrientation()
        }
    }

    private func removeDeviceOrientationObserver() {
        guard let observer = deviceOrientationObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        deviceOrientationObserver = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    /// 更新采集连接方向，并在横竖屏切换时通知 Flutter 层新的预览尺寸。
    private func updateConnectionOrientation() {
        guard let connection = videoOutput?.connection(with: .video), connection.isVideoOrientationSupported else {
            currentVideoOrientation = .portrait
            return
        }
        let orientation: AVCaptureVideoOrientation
        if followsDeviceOrientation {
            // 设备方向无效（平放 / 未知）时保持上一次方向，避免画面跳动。
            orientation = videoOrientation(for: UIDevice.current.orientation) ?? currentVideoOrientation
        } else {
            orientation = .portrait
        }
        let changed = connection.videoOrientation != orientation
        if changed {
            connection.videoOrientation = orientation
        }
        currentVideoOrientation = orientation
        if changed, let size = orientedPreviewSize(orientation) {
            onPreviewSizeChanged?(size)
        }
    }

    /// 把设备方向映射为采集连接方向，规则与系统相机一致。
    private func videoOrientation(for deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return nil
        }
    }

    /// 预览尺寸会随横竖屏切换互换宽高。
    private func orientedPreviewSize(_ orientation: AVCaptureVideoOrientation) -> CGSize? {
        guard let previewSize else { return nil }
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: previewSize.height, height: previewSize.width)
        default:
            return previewSize
        }
    }

    /// 设置闪光灯。
    ///
    /// - Parameter status: 0 关闭，1 常亮，2 自动（仅 iOS 支持）。
    /// - Returns: 设备无闪光灯或设置失败时返回 false。
    @discardableResult
    public func setFlashMode(status: Int) -> Bool {
        guard let device, device.hasTorch, let mode = AVCaptureDevice.TorchMode(rawValue: status) else { return false }
        do {
            try device.lockForConfiguration()
            device.torchMode = mode
            device.unlockForConfiguration()
            return true
        } catch {
            print("fl_camera setFlashMode error: \(error)")
            return false
        }
    }

    /// 设置缩放比例，超出设备能力时自动收敛。
    ///
    /// - Returns: 相机未初始化或设置失败时返回 false。
    @discardableResult
    public func setZoomRatio(ratio: Double) -> Bool {
        guard let device else { return false }
        do {
            try device.lockForConfiguration()
            let maxRatio = min(CGFloat(ratio), device.maxAvailableVideoZoomFactor)
            let minRatio = max(1, device.minAvailableVideoZoomFactor)
            device.videoZoomFactor = min(max(maxRatio, minRatio), device.maxAvailableVideoZoomFactor)
            device.unlockForConfiguration()
            return true
        } catch {
            print("fl_camera setZoomRatio error: \(error)")
            return false
        }
    }

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let latestPixelBuffer else { return nil }
        return Unmanaged<CVPixelBuffer>.passRetained(latestPixelBuffer)
    }

    /// 释放相机与纹理。
    ///
    /// 会话停止在 [captureQueue] 上异步执行，与 `startRunning()` 串行，
    /// 避免阻塞主线程以及 start / stop 并发导致的会话状态错乱。
    public func dispose() {
        removeDeviceObservers()
        removeSessionObservers(captureSession)
        removeDeviceOrientationObserver()
        wasInterrupted = false
        stateLock.lock()
        let textureIdToUnregister = textureId
        textureId = nil
        latestPixelBuffer = nil
        captureOutputCallBack = nil
        videoOutput = nil
        device = nil
        stateLock.unlock()
        if let textureIdToUnregister {
            registry.unregisterTexture(textureIdToUnregister)
        }
        previewSize = nil
        let session = captureSession
        captureSession = nil
        guard let session else { return }
        captureQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
        }
    }

    private func addDeviceObservers() {
        stateLock.lock()
        let device = self.device
        let alreadyObserving = isObservingDevice
        if !alreadyObserving {
            isObservingDevice = true
        }
        stateLock.unlock()
        guard let device, !alreadyObserving else { return }
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        device.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor), options: .new, context: nil)
    }

    private func addSessionObservers(_ session: AVCaptureSession) {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: AVCaptureSession.wasInterruptedNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: AVCaptureSession.interruptionEndedNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: AVCaptureSession.runtimeErrorNotification,
            object: session
        )
    }

    private func removeSessionObservers(_ session: AVCaptureSession?) {
        guard let session else { return }
        let center = NotificationCenter.default
        center.removeObserver(self, name: AVCaptureSession.wasInterruptedNotification, object: session)
        center.removeObserver(self, name: AVCaptureSession.interruptionEndedNotification, object: session)
        center.removeObserver(self, name: AVCaptureSession.runtimeErrorNotification, object: session)
    }

    /// 会话被系统中断（来电、其他 App 占用摄像头等），恢复后自动重新启动。
    @objc private func sessionWasInterrupted(_ notification: Notification) {
        stateLock.lock()
        wasInterrupted = true
        stateLock.unlock()
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        stateLock.lock()
        let interrupted = wasInterrupted
        wasInterrupted = false
        stateLock.unlock()
        guard interrupted, let session = notification.object as? AVCaptureSession else { return }
        captureQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        guard let session = notification.object as? AVCaptureSession else { return }
        let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
        print("fl_camera session runtime error: \(String(describing: error))")
        // 系统媒体服务重置后需要重新启动会话，否则画面会一直黑屏。
        guard error?.code == .mediaServicesWereReset else { return }
        captureQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    private func removeDeviceObservers() {
        stateLock.lock()
        let device = self.device
        let wasObserving = isObservingDevice
        isObservingDevice = false
        stateLock.unlock()
        guard let device, wasObserving else { return }
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
        device.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor))
    }

    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        stateLock.lock()
        let device = self.device
        stateLock.unlock()
        guard let device, let newValue = change?[.newKey] as? NSNumber else { return }
        if keyPath == #keyPath(AVCaptureDevice.torchMode) {
            // off = 0; on = 1; auto = 2
            FlCamera.shared.sendEvent(["flash": newValue.intValue])
        } else if keyPath == #keyPath(AVCaptureDevice.videoZoomFactor) {
            FlCamera.shared.sendEvent([
                "zoomRatio": newValue.doubleValue,
                "maxZoomRatio": device.maxAvailableVideoZoomFactor,
            ])
        }
    }

    /// 应用分辨率预设；设备不支持时回退到 720P / VGA。
    private func setCaptureSessionPreset(_ resolution: String) {
        guard let session = captureSession, let device else { return }
        let presets: [(AVCaptureSession.Preset, CGSize)] = {
            switch resolution {
            case "max":
                return [
                    (.hd4K3840x2160, CGSize(width: 2160, height: 3840)),
                    (.hd1920x1080, CGSize(width: 1080, height: 1920)),
                    (.hd1280x720, CGSize(width: 720, height: 1280)),
                    (.vga640x480, CGSize(width: 480, height: 640)),
                ]
            case "ultraHigh":
                return [(.hd4K3840x2160, CGSize(width: 2160, height: 3840)), (.hd1920x1080, CGSize(width: 1080, height: 1920))]
            case "veryHigh":
                return [(.hd1920x1080, CGSize(width: 1080, height: 1920)), (.hd1280x720, CGSize(width: 720, height: 1280))]
            case "high":
                return [(.hd1280x720, CGSize(width: 720, height: 1280)), (.vga640x480, CGSize(width: 480, height: 640))]
            case "medium":
                return [(.vga640x480, CGSize(width: 480, height: 640)), (.cif352x288, CGSize(width: 288, height: 352))]
            case "low":
                return [(.cif352x288, CGSize(width: 288, height: 352))]
            default:
                return []
            }
        }()
        for (preset, size) in presets where session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
            previewSize = size
            return
        }
        session.sessionPreset = .high
        previewSize = CGSize(width: 1080, height: 1920)
    }
}
