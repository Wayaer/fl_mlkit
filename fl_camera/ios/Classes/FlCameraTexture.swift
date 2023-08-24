import AVFoundation
import CoreMotion
import fl_channel
import Flutter
import Foundation

public class FlCameraTexture: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    // 链接相机用的
    var _captureSession: AVCaptureSession?
    // 获取相机设备
    var _device: AVCaptureDevice?
    // 视频输出
    var _videoOutput: AVCaptureVideoDataOutput?

    var _latestPixelBuffer: CVPixelBuffer?

    var _registry: FlutterTextureRegistry

    var _previewSize: CGSize?

    var textureId: Int64?

    var _cameraPosition: AVCaptureDevice.Position?

    var _captureOutputCallBack: ((_ buffer: CMSampleBuffer) -> Void)?

    init(_ registry: FlutterTextureRegistry) {
        _registry = registry
        super.init()
    }

    func initCamera(_ resolution: String, _ cameraId: String, _ result: @escaping FlutterResult, _ captureOutputCallBack: ((_ buffer: CMSampleBuffer) -> Void)? = nil) {
        _captureOutputCallBack = captureOutputCallBack
        _device = AVCaptureDevice(uniqueID: cameraId)
        _cameraPosition = _device!.position
        _device!.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode), options: .new, context: nil)
        _device!.addObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor), options: .new, context: nil)
        _captureSession = AVCaptureSession()
        _captureSession!.beginConfiguration()
        var videoInput: AVCaptureInput
        do {
            videoInput = try AVCaptureDeviceInput(device: _device!)
        } catch {
            result(nil)
            return
        }
        _videoOutput = AVCaptureVideoDataOutput()
        _videoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        _videoOutput!.alwaysDiscardsLateVideoFrames = true
        _videoOutput!.setSampleBufferDelegate(self, queue: .main)

        if _captureSession!.canAddInput(videoInput) {
            _captureSession!.addInput(videoInput)
        }

        if _captureSession!.canAddOutput(_videoOutput!) {
            _captureSession!.addOutput(_videoOutput!)
        }

        for connection in _videoOutput!.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if _device?.position == .front, connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        setCaptureSessionPreset(resolution)
        _captureSession!.commitConfiguration()
        textureId = _registry.register(self)
        result([
            "textureId": textureId!,
            "width": _previewSize!.width,
            "height": _previewSize!.height,
        ] as [String: Any])
        DispatchQueue.global(qos: .background).async {
            self._captureSession?.startRunning()
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == _videoOutput {
            _latestPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            _registry.textureFrameAvailable(textureId!)
            _captureOutputCallBack?(sampleBuffer)
        }
    }

    public func imageOrientation() -> UIImage.Orientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return _cameraPosition! == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return _cameraPosition! == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return _cameraPosition! == .front ? .rightMirrored : .left
        case .landscapeRight:
            return _cameraPosition! == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        default:
            return .up
        }
    }

    // 打开/关闭 闪光灯
    func setFlashMode(status: Int) {
        if _device != nil {
            try? _device!.lockForConfiguration()
            if _device!.hasTorch {
                _device!.torchMode = .init(rawValue: status)!
            }
            _device!.unlockForConfiguration()
        }
    }

    // 相机缩放
    func setZoomRatio(ratio: Double) {
        if _device != nil {
            try? _device!.lockForConfiguration()

            var ratioF = CGFloat(ratio)
            if ratioF > _device!.activeFormat.videoMaxZoomFactor {
                ratioF = _device!.activeFormat.videoMaxZoomFactor
            }
            _device!.videoZoomFactor = CGFloat(ratioF)
            _device!.unlockForConfiguration()
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if change != nil, _device != nil {
            if keyPath == #keyPath(AVCaptureDevice.torchMode) {
                // off = 0; on = 1; auto = 2;
                let state = change![.newKey] as? Int
                _ = FlCamera.shared.flEvent?.send(["flash": state])
            } else if keyPath == #keyPath(AVCaptureDevice.videoZoomFactor) {
                let zoom = (change![.newKey] as? Double) ?? 1.0
                _ = FlCamera.shared.flEvent?.send(["zoomRatio": zoom, "maxZoomRatio": _device!.activeFormat.videoMaxZoomFactor])
            }
        }
    }

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if _latestPixelBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(_latestPixelBuffer!)
    }

    func dispose() {
        if _captureSession != nil, _captureSession!.isRunning {
            _captureSession!.stopRunning()
        }
        _device?.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.torchMode))
        _device?.removeObserver(self, forKeyPath: #keyPath(AVCaptureDevice.videoZoomFactor))
        if textureId != nil {
            _registry.unregisterTexture(textureId!)
        }
        if _captureSession != nil {
            for input in _captureSession!.inputs {
                _captureSession!.removeInput(input)
            }
            for output in _captureSession!.outputs {
                _captureSession!.removeOutput(output)
            }
        }
        _device = nil
        _captureSession = nil
        _videoOutput = nil
        _latestPixelBuffer = nil
    }

    private func setCaptureSessionPreset(_ resolution: String) {
        switch resolution {
        case "max":
            if _captureSession!.canSetSessionPreset(.high) {
                _captureSession!.sessionPreset = .high
                let height = _device!.activeFormat.highResolutionStillImageDimensions.width
                let width = _device!.activeFormat.highResolutionStillImageDimensions.height
                _previewSize = CGSize(width: Int(width), height: Int(height))
            }

        case "ultraHigh":
            if _captureSession!.canSetSessionPreset(.hd4K3840x2160) {
                _captureSession!.sessionPreset = .hd4K3840x2160
                _previewSize = CGSize(width: 2160, height: 3840)
            }
        case "veryHigh":
            if _captureSession!.canSetSessionPreset(.hd1920x1080) {
                _captureSession!.sessionPreset = .hd1920x1080
                _previewSize = CGSize(width: 1080, height: 1920)
            }
        case "high":
            if _captureSession!.canSetSessionPreset(.hd1280x720) {
                _captureSession!.sessionPreset = .hd1280x720
                _previewSize = CGSize(width: 720, height: 1280)
            }
        case "medium":
            if _captureSession!.canSetSessionPreset(.vga640x480) {
                _captureSession!.sessionPreset = .vga640x480
                _previewSize = CGSize(width: 480, height: 640)
            }
        case "low":
            if _captureSession!.canSetSessionPreset(.cif352x288) {
                _captureSession!.sessionPreset = .cif352x288
                _previewSize = CGSize(width: 288, height: 352)
            }
        default: break
        }
    }
}
