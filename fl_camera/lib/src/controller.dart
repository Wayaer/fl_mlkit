part of '../fl_camera.dart';

enum FlashState {
  /// Supports Android and IOS
  off,
  on,

  /// IOS only , off in Android
  auto
}

enum CameraResolution {
  /// android QUALITY_QVGA   ios 288*352
  low,

  /// android 480*640  ios 480*640
  medium,

  /// android 720*1280  ios 720*1280
  high,

  /// android 1080*1920  ios 1080*1920
  veryHigh,

  /// android 2160*3840  ios 2160*3840
  ultraHigh,

  /// android QUALITY_HIGH  ios max
  max
}

/// Camera position
enum CameraLensFacing { back, front, external }

class FlCameraController extends CameraController {
  factory FlCameraController() => _singleton ??= FlCameraController._();

  FlCameraController._();

  static FlCameraController? _singleton;
}

abstract class CameraController {
  final MethodChannel _channel = const MethodChannel('fl.camera');

  bool _isInitialize = false;

  /// 所有可用的摄像头
  /// all available Cameras
  List<CameraInfo>? _cameras;

  List<CameraInfo>? get cameras => _cameras;

  /// 相机配置信息
  /// Camera configuration information
  /// FlCameraOptions? cameraOptions;
  final ValueNotifier<FlCameraOptions?> cameraOptions = ValueNotifier(null);

  /// 上一次初始化的Camera
  /// Last initialized Camera
  CameraInfo? _previousCamera;

  CameraInfo? get previousCamera => _previousCamera;

  /// 相机缩放状态
  /// Camera zoom status
  CameraZoomState? _cameraZoom;

  CameraZoomState? get cameraZoom => _cameraZoom;

  /// 闪光灯状态
  /// Flash status
  FlashState? _cameraFlash;

  FlashState? get cameraFlash => _cameraFlash;

  CameraResolution cameraResolution = CameraResolution.high;

  /// 闪光灯变化
  /// Flash change
  FlCameraFlashStateChanged? onFlashChanged;

  /// 缩放变化
  /// zoom ratio
  FlCameraCameraZoomStateChanged? onZoomChanged;

  FlEvent? _flEvent;

  /// 获取可用摄像机
  /// 通常在第一次加载 Camera 后自动获取设备的可用相机，并且赋值给了[cameras]，所以后续可以不用再调用这个方法，可直接使用[cameras]
  ///
  /// get available Cameras
  /// Generally, after the Camera is loaded for the first time, the controller
  /// automatically obtains the available cameras of the device and assigns
  /// the value to the [cameras]. Therefore, we can use the cameras directly
  /// instead of calling the method.
  Future<List<CameraInfo>?> availableCameras() async {
    try {
      final List<Map<dynamic, dynamic>>? cameras = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('availableCameras');
      if (cameras == null) return <CameraInfo>[];
      _cameras = cameras
          .map((Map<dynamic, dynamic> camera) => CameraInfo(
              name: camera['name'] as String,
              lensFacing: _getCameraLensFacing(camera['lensFacing'] as String)))
          .toList();
      return _cameras;
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  /// 初始化所有相机 camera 和 event
  /// initialize all Including camera and event
  Future<bool> initialize() async {
    if (!_supportPlatform) return false;
    _flEvent ??= FlEvent('fl.camera.event');
    bool? result = await _channel.invokeMethod<bool?>('initialize');
    if (result == true) result = _flEvent!.listen(onDataListen);
    _isInitialize = result == true;
    await availableCameras();
    return result ?? false;
  }

  /// 消息回调监听
  FlEventListenData get onDataListen => (dynamic data) {
        if (data is Map) {
          if (data.containsKey('flash')) {
            /// flash state
            final int? flashState = data['flash'] as int?;
            if (flashState != null) {
              _cameraFlash = FlashState.values[flashState];
              onFlashChanged?.call(_cameraFlash!);
              return;
            }
          } else if (data.containsKey('zoomRatio') &&
              data.containsKey('maxZoomRatio')) {
            /// zoom ratio state
            final double? zoomRatio = data['zoomRatio'] as double?;
            final double? maxZoomRatio = data['maxZoomRatio'] as double?;
            if (zoomRatio != null && maxZoomRatio != null) {
              _cameraZoom = CameraZoomState(
                  maxZoomRatio: maxZoomRatio, zoomRatio: zoomRatio);
              onZoomChanged?.call(_cameraZoom!);
              return;
            }
          }
        }
      };

  /// 开始预览
  /// start Preview
  /// [camera] 需要预览的相机 Camera to preview
  /// [resolution] 预览相机支持的分辨率 Preview the resolution supported by the camera
  Future<FlCameraOptions?> startPreview(CameraInfo camera,
      {CameraResolution? resolution}) async {
    if (!_supportPlatform) return null;
    assert(_isInitialize, 'Call initialize first');
    if (resolution != null) cameraResolution = resolution;
    final arguments = <String, dynamic>{
      'cameraId': camera.name,
      'resolution': cameraResolution.name
    };
    final Map<dynamic, dynamic>? map = await _channel
        .invokeMethod<Map<dynamic, dynamic>?>('startPreview', arguments);
    if (map != null) {
      cameraOptions.value = FlCameraOptions.fromMap(map);
      if (_previousCamera != camera) _previousCamera = camera;
      return cameraOptions.value!;
    }
    return null;
  }

  /// 暂停预览
  /// stop Preview
  Future<bool> stopPreview() async {
    assert(_isInitialize, 'Call initialize first');
    if (cameraOptions.value == null) return false;
    final bool? state = await _channel.invokeMethod<bool?>('stopPreview');
    if (state == true) cameraOptions.value = null;
    return state ?? false;
  }

  /// 重新预览相机
  /// Reset the camera
  Future<bool> resetCamera() async {
    assert(_isInitialize, 'Call initialize first');
    if (previousCamera == null) return false;
    await stopPreview();
    final options = await startPreview(previousCamera!);
    return options != null;
  }

  /// 切换摄像头
  /// Switch Camera
  Future<bool> switchCamera(CameraInfo camera) async {
    assert(_isInitialize, 'Call initialize first');
    await stopPreview();
    final options = await startPreview(camera);
    return options != null;
  }

  /// 打开/关闭 闪光灯
  /// Turn flash on / off
  Future<bool> setFlashMode(FlashState status) async {
    if (!_supportPlatform || cameraOptions.value == null) return false;
    assert(_isInitialize, 'Call initialize first');
    final bool? state =
        await _channel.invokeMethod<bool?>('setFlashMode', status.index);
    return state ?? false;
  }

  /// 相机缩放
  /// Camera zoom
  Future<bool> setZoomRatio(double ratio) async {
    if (!_supportPlatform || cameraOptions.value == null) return false;
    assert(_isInitialize, 'Call initialize first');
    assert(ratio >= 1, 'ratio must be greater than or equal to 1');
    final bool? state =
        await _channel.invokeMethod<bool?>('setZoomRatio', ratio);
    return state ?? false;
  }

  /// dispose  all
  Future<bool> dispose() async {
    if (!_supportPlatform) return false;
    await _flEvent?.dispose();
    _flEvent = null;
    bool? state = await _channel.invokeMethod<bool?>('dispose');
    cameraOptions.value = null;
    _cameraFlash = null;
    _cameraZoom = null;
    return state ?? false;
  }

  CameraLensFacing _getCameraLensFacing(String lensFacing) {
    switch (lensFacing) {
      case 'back':
        return CameraLensFacing.back;
      case 'front':
        return CameraLensFacing.front;
      case 'external':
        return CameraLensFacing.external;
      default:
        return CameraLensFacing.external;
    }
  }
}

class CameraInfo {
  CameraInfo({required this.name, required this.lensFacing});

  /// camera name
  String name;

  /// Camera position
  CameraLensFacing lensFacing;
}

class FlCameraOptions {
  FlCameraOptions.fromMap(Map<dynamic, dynamic> map) {
    textureId = map['textureId'] as int?;
    width = map['width'] as double?;
    height = map['height'] as double?;
  }

  /// Unique ID
  int? textureId;

  /// Camera preview width
  double? width;

  /// Camera preview height
  double? height;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'textureId': textureId,
        'width': width,
        'height': height
      };
}

class CameraZoomState {
  CameraZoomState({this.maxZoomRatio, this.zoomRatio});

  CameraZoomState.fromMap(Map<String, dynamic> map)
      : maxZoomRatio = map['maxZoomRatio'] as double?,
        zoomRatio = map['maxZoomRatio'] as double?;

  /// 最大缩放比例
  /// Camera max zoom ratio
  double? maxZoomRatio;

  /// 当前缩放比例
  /// Current zoom ratio
  double? zoomRatio;
}
