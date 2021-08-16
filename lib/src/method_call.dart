part of '../fl_mlkit_scanning.dart';

class FlMlKitScanningMethodCall {
  factory FlMlKitScanningMethodCall() => _getInstance();

  FlMlKitScanningMethodCall._internal();

  static FlMlKitScanningMethodCall get instance => _getInstance();
  static FlMlKitScanningMethodCall? _instance;

  static FlMlKitScanningMethodCall _getInstance() {
    _instance ??= FlMlKitScanningMethodCall._internal();
    return _instance!;
  }

  final MethodChannel _channel = _flMlKitScanningChannel;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.qr_code];

  MethodChannel get channel => _channel;

  /// 设置设别码类型
  /// Set type
  Future<bool> setBarcodeFormat(List<BarcodeFormat> barcodeFormats) async {
    if (!_supportPlatform) return false;
    _barcodeFormats = barcodeFormats;
    final bool? state = await _channel
        .invokeMethod<bool?>('setBarcodeFormat', <String, dynamic>{
      'barcodeFormats': _barcodeFormats
          .map((BarcodeFormat e) => e.toString().split('.')[1])
          .toSet()
          .toList()
    });
    return state ?? false;
  }

  /// 识别图片字节
  /// Identify picture bytes
  /// [useEvent] 返回消息使用 FLCameraEvent
  /// The return message uses flcameraevent
  /// [rotationDegrees] Only Android is supported
  Future<AnalysisImageModel?> scanImageByte(Uint8List uint8list,
      {int rotationDegrees = 0, bool useEvent = false}) async {
    if (!_supportPlatform) return null;
    if (useEvent) {
      assert(
          FlCameraEvent.instance.isPaused, 'Please initialize FLCameraEvent');
    }
    final dynamic map = await _channel.invokeMethod<dynamic>(
        'scanImageByte', <String, dynamic>{
      'byte': uint8list,
      'useEvent': useEvent,
      'rotationDegrees': rotationDegrees
    });
    if (map != null && map is Map) return AnalysisImageModel.fromMap(map);
    return null;
  }

  /// 打开\关闭 闪光灯
  /// Turn flash on / off
  Future<bool> setFlashMode(bool status) =>
      FlCameraMethodCall.instance.setFlashMode(status);

  /// 相机缩放
  /// Camera zoom
  Future<bool> setZoomRatio(double ratio) =>
      FlCameraMethodCall.instance.setZoomRatio(ratio);

  /// 获取可用摄像头
  /// get available Cameras
  Future<List<CameraInfo>?> availableCameras() =>
      FlCameraMethodCall.instance.availableCameras();

  /// 暂停扫描
  /// Pause scanning
  Future<bool> pause() => _scanncing(false);

  /// 开始扫描
  /// Start scanncing
  Future<bool> start() => _scanncing(true);

  /// 获取识别状态
  /// get scan state
  Future<bool?> getScanState() async {
    if (!_supportPlatform) return null;
    return await _channel.invokeMethod<bool?>('getScanState');
  }

  Future<bool> _scanncing(bool scan) async {
    if (!_supportPlatform) return false;
    final bool? state = await _channel.invokeMethod<bool?>('scan', scan);
    return state ?? false;
  }
}
