part of '../fl_mlkit_scanning.dart';

class FlMLKitScanningMethodCall {
  factory FlMLKitScanningMethodCall() => _getInstance();

  FlMLKitScanningMethodCall._internal();

  static FlMLKitScanningMethodCall get instance => _getInstance();
  static FlMLKitScanningMethodCall? _instance;

  static FlMLKitScanningMethodCall _getInstance() {
    _instance ??= FlMLKitScanningMethodCall._internal();
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
  Future<List<BarcodeModel>> scanImageByte(Uint8List uint8list,
      {int rotationDegrees = 0, bool useEvent = false}) async {
    if (!_supportPlatform) return <BarcodeModel>[];
    if (useEvent) {
      assert(
          FLCameraEvent.instance.isPaused, 'Please initialize FLCameraEvent');
    }
    final dynamic list = await _channel.invokeMethod<dynamic>(
        'scanImageByte', <String, dynamic>{
      'byte': uint8list,
      'useEvent': useEvent,
      'rotationDegrees': rotationDegrees
    });
    if (list != null && list is List) return getBarcodeModelList(list);
    return <BarcodeModel>[];
  }

  /// 打开\关闭 闪光灯
  /// Turn flash on / off
  Future<bool> setFlashMode(bool status) =>
      FlCameraMethodCall.instance.setFlashMode(status);

  /// 暂停扫描
  /// Pause scanning
  Future<bool> pause() => _scanncing(false);

  /// 开始扫描
  /// Start scanncing
  Future<bool> start() => _scanncing(true);

  Future<bool> _scanncing(bool scan) async {
    if (!_supportPlatform) return false;
    final bool? state = await _channel.invokeMethod<bool?>('scan', scan);
    return state ?? false;
  }
}
