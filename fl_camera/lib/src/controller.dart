part of '../fl_camera.dart';

/// 闪光灯状态。
enum FlashState {
  /// 关闭闪光灯，Android 与 iOS 均支持。
  off,

  /// 常亮闪光灯，Android 与 iOS 均支持。
  on,

  /// 自动闪光灯，仅 iOS 支持；Android 会按 [off] 处理。
  auto,
}

/// 相机预览分辨率。
///
/// 具体尺寸由原生层按设备能力就近选择，不保证完全一致。
enum CameraResolution {
  /// Android：QUALITY_QVGA；iOS：288 x 352。
  low,

  /// Android 与 iOS：480 x 640。
  medium,

  /// Android 与 iOS：720 x 1280。
  high,

  /// Android 与 iOS：1080 x 1920。
  veryHigh,

  /// Android 与 iOS：2160 x 3840。
  ultraHigh,

  /// Android 使用 QUALITY_HIGH 档位，iOS 使用设备支持的最大尺寸。
  max,
}

/// 相机位置。
enum CameraLensFacing {
  /// 后置摄像头。
  back,

  /// 前置摄像头。
  front,

  /// 外置摄像头。
  external,
}

/// 相机控制器单例。
///
/// 预览、闪光灯、缩放等操作均通过该单例完成：
///
/// ```dart
/// final controller = FlCameraController();
/// await controller.initialize();
/// final cameras = await controller.availableCameras();
/// await controller.startPreview(cameras!.first);
/// ```
class FlCameraController extends CameraController {
  factory FlCameraController() => _instance;

  FlCameraController._();

  static final FlCameraController _instance = FlCameraController._();

  /// 全局单例。
  static FlCameraController get instance => _instance;
}

/// 相机初始化或预览的失败原因。
///
/// 原生层通过 `FlutterError.code` 返回枚举名（驼峰命名），Dart 侧统一映射为该枚举，
/// 可通过 [FlCameraController.errorNotifier] 监听最近一次失败原因。
enum FlCameraErrorCode {
  /// 当前平台不支持相机。
  platformUnsupported,

  /// 用户拒绝相机权限，或系统限制了相机访问。
  permissionDenied,

  /// 权限申请被 Activity 销毁或重复请求打断。
  permissionRequestInterrupted,

  /// 未完成初始化就调用预览，或原生相机实例已被释放。
  notInitialized,

  /// 摄像头 ID、分辨率等参数缺失或非法。
  invalidArguments,

  /// 指定的摄像头不存在。
  cameraNotFound,

  /// 相机绑定、输入输出、纹理创建或采集会话启动失败。
  cameraInitFailed,

  /// 未分类异常。
  unknown;

  /// 将原生错误码（枚举 [name]）转换为枚举，未知错误码返回 [unknown]。
  static FlCameraErrorCode fromCode(String? code) =>
      values.firstWhere((FlCameraErrorCode value) => value.name == code, orElse: () => FlCameraErrorCode.unknown);
}

/// 相机能力抽象，所有具体实现均为单例。
abstract class CameraController {
  final MethodChannel _channel = const MethodChannel('fl.camera');

  bool _isInitialize = false;

  /// 是否已完成原生初始化。
  ///
  /// 初始化成功后才能调用 [startPreview] 等方法。
  bool get isInitialized => _isInitialize;

  /// 最近一次初始化 / 预览失败的原因，失败后可据此展示对应引导。
  ///
  /// 成功后会被清空；权限授予并重新初始化成功后同样会清空。
  final ValueNotifier<FlCameraErrorCode?> errorNotifier = ValueNotifier<FlCameraErrorCode?>(null);

  /// 最近一次失败是否为相机权限被拒绝。
  bool get permissionDenied => errorNotifier.value == FlCameraErrorCode.permissionDenied;

  /// 所有可用的摄像头。
  ///
  /// 首次 [initialize] 或 [availableCameras] 后会被自动赋值。
  List<CameraInfo>? _cameras;

  /// 所有可用的摄像头。
  List<CameraInfo>? get cameras => _cameras;

  /// 相机配置信息。
  ///
  /// 预览成功时保存当前相机输出的纹理与尺寸，停止预览后为 null。
  final ValueNotifier<FlCameraOptions?> cameraOptions = ValueNotifier<FlCameraOptions?>(null);

  /// 上一次预览的相机。
  ///
  /// 用于 [resetCamera] 以及切换相机后恢复预览。
  CameraInfo? _previousCamera;

  /// 上一次预览的相机。
  CameraInfo? get previousCamera => _previousCamera;

  /// 当前的缩放状态。
  CameraZoomState? _cameraZoom;

  /// 当前的缩放状态，由原生层回调更新。
  CameraZoomState? get cameraZoom => _cameraZoom;

  /// 当前的闪光灯状态。
  FlashState? _cameraFlash;

  /// 当前的闪光灯状态，由原生层回调更新。
  FlashState? get cameraFlash => _cameraFlash;

  /// 预览分辨率，[startPreview] 未指定时使用该值。
  CameraResolution cameraResolution = CameraResolution.high;

  /// 相机事件通道名称。
  ///
  /// 每个控制器使用独立的事件通道（相机 / 扫码 / OCR），原生会把闪光灯、
  /// 缩放、预览尺寸与相机释放事件广播给所有已注册的通道，避免多个控制器
  /// 共用同一通道时监听被覆盖。
  String get eventChannelName => 'fl.camera.event';

  /// 是否让 iOS 预览跟随设备方向旋转，Android 由 CameraX 自动处理。
  ///
  /// 默认 false（固定竖屏）。仅在宿主自行控制屏幕方向（`lockPortrait: false`）
  /// 时置为 true，否则设备旋转会导致预览方向错误。
  bool followDeviceOrientation = false;

  /// 闪光灯状态变化回调。
  FlCameraFlashStateChanged? onFlashChanged;

  /// 缩放状态变化回调。
  FlCameraCameraZoomStateChanged? onZoomChanged;

  /// 原生层主动释放相机（例如 Android Activity 重建）时触发。
  ///
  /// 触发时相机已不可用，宿主或预览组件应重新 [initialize] 并 [startPreview]。
  VoidCallback? onNativeDisposed;

  /// 原生事件通道。
  FlEventChannel? _flEventChannel;

  /// 正在执行的释放流程，用于避免 dispose 与 initialize / startPreview 并发。
  Future<bool>? _disposing;

  /// 正在执行的初始化流程，用于避免 dispose 与 initialize 并发。
  Future<bool>? _initializing;

  /// 预览请求序号，新的 [startPreview] 或 [dispose] 会让旧请求的结果失效。
  int _previewId = 0;

  /// 正在执行的预览启动流程，[stopPreview] 需要等待它结束。
  Future<FlCameraOptions?>? _starting;

  /// 获取设备可用的摄像头。
  ///
  /// 通常在第一次初始化后会自动获取并赋值给 [cameras]，后续可直接读取 [cameras]，
  /// 无需再次调用该接口。发生平台异常或当前平台不支持时返回 null。
  Future<List<CameraInfo>?> availableCameras() async {
    if (!_supportPlatform) return null;
    try {
      final List<Map<dynamic, dynamic>>? cameras = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'availableCameras',
      );
      if (cameras == null) return _cameras;
      _cameras = cameras
          .map(
            (Map<dynamic, dynamic> camera) => CameraInfo(
              name: camera['name'] as String,
              lensFacing: _getCameraLensFacing(camera['lensFacing'] as String?),
            ),
          )
          .toList(growable: false);
      return _cameras;
    } catch (error) {
      debugPrint('availableCameras error: $error');
      return null;
    }
  }

  /// 初始化相机与原生事件通道。
  ///
  /// 同一实例重复调用是安全的：进行中的初始化会被复用，避免并发触发多次权限弹窗。
  /// 返回 true 表示初始化成功，可以继续调用 [startPreview]；返回 false 通常意味着
  /// 权限被拒绝或平台不受支持。
  Future<bool> initialize() async {
    if (!_supportPlatform) {
      _setError(FlCameraErrorCode.platformUnsupported);
      return false;
    }
    final Future<bool>? initializing = _initializing;
    if (initializing != null) return initializing;
    final Future<bool> future = _initializeAfterDispose();
    _initializing = future;
    try {
      return await future;
    } finally {
      if (identical(_initializing, future)) _initializing = null;
    }
  }

  /// 等待正在进行的释放流程结束后再初始化，避免与 dispose 并发。
  Future<bool> _initializeAfterDispose() async {
    final Future<void>? disposing = _disposing;
    if (disposing != null) await disposing;
    return _initialize();
  }

  Future<bool> _initialize() async {
    try {
      final FlEventChannel? eventChannel = _flEventChannel ?? await FlChannel().create(eventChannelName);
      if (eventChannel == null) {
        _setError(FlCameraErrorCode.cameraInitFailed);
        return false;
      }
      _flEventChannel = eventChannel;
      bool? result = await _channel.invokeMethod<bool>('initialize', <String, dynamic>{
        'eventChannelName': eventChannelName,
      });
      if (result != true) {
        _isInitialize = false;
        _setError(FlCameraErrorCode.cameraInitFailed);
        return false;
      }
      if (!eventChannel.isListening && !eventChannel.listen(onDataListen)) {
        // 通道已被释放（例如被其他实例 dispose），清空缓存，下次初始化重新创建。
        _flEventChannel = null;
        result = false;
      }
      _isInitialize = result == true;
      if (!_isInitialize) {
        _setError(FlCameraErrorCode.cameraInitFailed);
        return false;
      }
      await availableCameras();
      _setError(null);
      return true;
    } catch (error) {
      debugPrint('initialize error: $error');
      _isInitialize = false;
      _setError(_errorCodeOf(error));
      return false;
    }
  }

  /// 将原生 / 通道异常转换为枚举原因。
  FlCameraErrorCode _errorCodeOf(Object error) =>
      error is PlatformException ? FlCameraErrorCode.fromCode(error.code) : FlCameraErrorCode.cameraInitFailed;

  /// 原生事件回调：闪光灯、缩放状态与原生相机释放通知。
  FlEventChannelListenData get onDataListen => (dynamic data) {
    if (data is! Map) return;
    if (data.containsKey('disposed')) {
      // Activity 重建等场景下原生已释放相机，Flutter 侧同步失效并通知外层重新初始化。
      _releasePreviewState();
      onNativeDisposed?.call();
      return;
    }
    if (data.containsKey('previewWidth') && data.containsKey('previewHeight')) {
      // 设备旋转后原生会重新计算预览宽高（横竖屏互换），同步给 Flutter 层。
      final FlCameraOptions? options = cameraOptions.value;
      final double? width = (data['previewWidth'] as num?)?.toDouble();
      final double? height = (data['previewHeight'] as num?)?.toDouble();
      if (options != null && width != null && height != null) {
        cameraOptions.value = FlCameraOptions(textureId: options.textureId, width: width, height: height);
      }
      return;
    }
    if (data.containsKey('flash')) {
      final int? index = (data['flash'] as num?)?.toInt();
      if (index != null && index >= 0 && index < FlashState.values.length) {
        _cameraFlash = FlashState.values[index];
        onFlashChanged?.call(_cameraFlash!);
        return;
      }
    }
    if (data.containsKey('zoomRatio') && data.containsKey('maxZoomRatio')) {
      final CameraZoomState state = CameraZoomState.fromMap(data);
      if (state.zoomRatio != null && state.maxZoomRatio != null) {
        _cameraZoom = state;
        onZoomChanged?.call(state);
      }
    }
  };

  /// 开始预览。
  ///
  /// [camera] 为需要预览的摄像头，通常来自 [cameras]；
  /// [resolution] 指定分辨率，不传则使用 [cameraResolution]。
  /// 预览成功返回 [FlCameraOptions]，失败返回 null 并清空旧的预览状态。
  Future<FlCameraOptions?> startPreview(CameraInfo camera, {CameraResolution? resolution}) {
    final Future<FlCameraOptions?> future = _startPreview(camera, resolution: resolution);
    _starting = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_starting, future)) _starting = null;
      }),
    );
    return future;
  }

  Future<FlCameraOptions?> _startPreview(CameraInfo camera, {CameraResolution? resolution}) async {
    if (!_supportPlatform) {
      _setError(FlCameraErrorCode.platformUnsupported);
      return null;
    }
    final Future<bool>? disposing = _disposing;
    if (disposing != null) await disposing;
    if (!_isInitialize) {
      _setError(FlCameraErrorCode.notInitialized);
      return null;
    }
    if (resolution != null) cameraResolution = resolution;
    final int previewId = ++_previewId;
    try {
      final Map? map = await _channel.invokeMethod<Map>('startPreview', {
        'cameraId': camera.name,
        'resolution': cameraResolution.name,
        'followDeviceOrientation': followDeviceOrientation,
      });
      // 等待原生结果期间可能已被新的预览请求或 dispose 取代，避免写入过期状态。
      if (previewId != _previewId || !_isInitialize) return null;
      final FlCameraOptions? options = map == null ? null : FlCameraOptions.fromMap(map);
      if (options?.textureId == null) {
        // 原生已释放旧纹理但未能创建新纹理，必须清空否则界面会停留在失效纹理上。
        cameraOptions.value = null;
        _setError(FlCameraErrorCode.cameraInitFailed);
        return null;
      }
      _setError(null);
      cameraOptions.value = options;
      _previousCamera = camera;
      return options;
    } catch (error) {
      debugPrint('startPreview error: $error');
      if (previewId == _previewId) {
        cameraOptions.value = null;
        _setError(_errorCodeOf(error));
      }
      return null;
    }
  }

  /// 停止预览。
  ///
  /// 当前没有预览时直接返回 false；若有正在启动的预览，会等待启动结束再停止，
  /// 避免首帧返回前调用“停止”被忽略。
  Future<bool> stopPreview() async {
    if (!_supportPlatform || !_isInitialize) return false;
    final Future<FlCameraOptions?>? starting = _starting;
    if (starting != null) {
      await starting;
      if (!_isInitialize) return false;
    }
    if (cameraOptions.value == null) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('stopPreview');
      if (state == true) cameraOptions.value = null;
      return state ?? false;
    } catch (error) {
      debugPrint('stopPreview error: $error');
      return false;
    }
  }

  /// 重置相机：停止当前预览并重新打开 [previousCamera]。
  Future<bool> resetCamera() async {
    if (!_supportPlatform || !_isInitialize || previousCamera == null) return false;
    await stopPreview();
    final FlCameraOptions? options = await startPreview(previousCamera!);
    return options != null;
  }

  /// 切换到指定相机。
  Future<bool> switchCamera(CameraInfo camera) async {
    if (!_supportPlatform || !_isInitialize) return false;
    await stopPreview();
    final FlCameraOptions? options = await startPreview(camera);
    return options != null;
  }

  /// 设置闪光灯状态。
  ///
  /// [FlashState.auto] 仅 iOS 生效，Android 会按关闭处理。
  Future<bool> setFlashMode(FlashState status) async {
    if (!_supportPlatform || !_isInitialize || cameraOptions.value == null) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('setFlashMode', status.index);
      return state ?? false;
    } catch (error) {
      debugPrint('setFlashMode error: $error');
      return false;
    }
  }

  /// 设置相机缩放比例。
  ///
  /// [ratio] 必须大于等于 1；超过设备最大缩放值时会被限制到最大值。
  Future<bool> setZoomRatio(double ratio) async {
    if (!_supportPlatform || !_isInitialize || cameraOptions.value == null) return false;
    assert(ratio >= 1, 'ratio must be greater than or equal to 1');
    final double maxZoomRatio = cameraZoom?.maxZoomRatio ?? ratio;
    final double zoomRatio = ratio.clamp(1, maxZoomRatio).toDouble();
    try {
      final bool? state = await _channel.invokeMethod<bool>('setZoomRatio', zoomRatio);
      return state ?? false;
    } catch (error) {
      debugPrint('setZoomRatio error: $error');
      return false;
    }
  }

  /// 释放相机、事件通道以及原生资源。
  ///
  /// 释放后可再次调用 [initialize] 重新初始化。重复调用会复用同一次释放流程，
  /// 返回值为原生相机释放的结果。
  Future<bool> dispose() async {
    if (!_supportPlatform) return false;
    final Future<bool>? disposing = _disposing;
    if (disposing != null) return disposing;
    final Future<bool> future = _disposeAfterInitialize();
    _disposing = future;
    try {
      return await future;
    } finally {
      if (identical(_disposing, future)) _disposing = null;
    }
  }

  /// 释放子类（扫码 / 文字识别等）额外的原生资源。
  ///
  /// 该步骤在 [dispose] 的互斥流程内执行，覆写后无需再处理 dispose 与
  /// initialize / startPreview 的并发。
  @protected
  Future<void> releaseNativeResources() async {}

  /// 控制器占用序号，用于区分同一控制器上的多次页面生命周期。
  int _ownerId = 0;

  /// 预览组件挂载时占用控制器，返回占用标识。
  ///
  /// 页面退出存在过渡动画，旧页面可能在新页面初始化完成之后才销毁；
  /// 通过占用标识保证只有最新的页面才会真正释放相机。
  @protected
  int takeOwner() => ++_ownerId;

  /// 当前控制器是否仍由 [owner] 占用。
  @protected
  bool isOwner(int owner) => owner == _ownerId;

  /// 预览组件销毁时释放占用。
  ///
  /// 已被更新的页面接管时不会释放，返回 false；返回 true 表示已开始执行 [dispose]。
  @protected
  bool releaseOwner(int owner) {
    if (!isOwner(owner)) return false;
    unawaited(dispose());
    return true;
  }

  Future<bool> _disposeAfterInitialize() async {
    final Future<bool>? initializing = _initializing;
    if (initializing != null) await initializing;
    return _dispose();
  }

  Future<bool> _dispose() async {
    // 让仍在等待的 startPreview 结果失效。
    _previewId++;
    final FlEventChannel? eventChannel = _flEventChannel;
    _flEventChannel = null;
    try {
      await releaseNativeResources();
    } catch (error) {
      debugPrint('release native resources error: $error');
    }
    try {
      await eventChannel?.dispose();
    } catch (error) {
      debugPrint('dispose event channel error: $error');
    }
    try {
      final bool? state = await _channel.invokeMethod<bool>('dispose', <String, dynamic>{
        'eventChannelName': eventChannelName,
      });
      return state ?? false;
    } catch (error) {
      debugPrint('dispose error: $error');
      return false;
    } finally {
      _cameras = null;
      _releasePreviewState();
    }
  }

  /// 清空与当前预览相关的状态，保留 [cameras]。
  void _releasePreviewState() {
    _isInitialize = false;
    _previousCamera = null;
    _cameraFlash = null;
    _cameraZoom = null;
    _setError(null);
    cameraOptions.value = null;
  }

  /// 更新失败原因，避免相同值反复触发监听。
  void _setError(FlCameraErrorCode? code) {
    if (errorNotifier.value != code) errorNotifier.value = code;
  }

  CameraLensFacing _getCameraLensFacing(String? lensFacing) {
    switch (lensFacing) {
      case 'back':
        return CameraLensFacing.back;
      case 'front':
        return CameraLensFacing.front;
      default:
        return CameraLensFacing.external;
    }
  }
}

/// 摄像头信息。
class CameraInfo {
  /// 创建摄像头信息。
  const CameraInfo({required this.name, required this.lensFacing});

  /// 原生层使用的摄像头唯一标识。
  final String name;

  /// 摄像头位置。
  final CameraLensFacing lensFacing;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CameraInfo && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CameraInfo(name: $name, lensFacing: ${lensFacing.name})';
}

/// 相机预览配置。
class FlCameraOptions {
  /// 创建预览配置。
  const FlCameraOptions({this.textureId, this.width, this.height});

  /// 从原生返回的 Map 创建预览配置。
  FlCameraOptions.fromMap(Map<dynamic, dynamic> map)
    : textureId = (map['textureId'] as num?)?.toInt(),
      width = (map['width'] as num?)?.toDouble(),
      height = (map['height'] as num?)?.toDouble();

  /// 原生纹理 ID，用于 [Texture] 组件。
  final int? textureId;

  /// 预览宽度（像素）。
  final double? width;

  /// 预览高度（像素）。
  final double? height;

  /// 转为 Map。
  Map<String, dynamic> toMap() => <String, dynamic>{'textureId': textureId, 'width': width, 'height': height};

  @override
  String toString() => 'FlCameraOptions(textureId: $textureId, width: $width, height: $height)';
}

/// 相机缩放状态。
class CameraZoomState {
  /// 创建缩放状态。
  const CameraZoomState({this.maxZoomRatio, this.zoomRatio});

  /// 从原生返回的 Map 创建缩放状态。
  factory CameraZoomState.fromMap(Map<dynamic, dynamic> map) => CameraZoomState(
    maxZoomRatio: (map['maxZoomRatio'] as num?)?.toDouble(),
    zoomRatio: (map['zoomRatio'] as num?)?.toDouble(),
  );

  /// 设备支持的最大缩放比例。
  final double? maxZoomRatio;

  /// 当前缩放比例。
  final double? zoomRatio;

  @override
  String toString() => 'CameraZoomState(maxZoomRatio: $maxZoomRatio, zoomRatio: $zoomRatio)';
}
