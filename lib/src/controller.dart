part of '../fl_mlkit_scanning.dart';

class FlMlKitScanningController extends CameraController {
  factory FlMlKitScanningController() =>
      _singleton ??= FlMlKitScanningController._();

  FlMlKitScanningController._() {
    channel = _flMlKitScanningChannel;
    cameraEvent.setMethodChannel(channel);
  }

  static FlMlKitScanningController? _singleton;

  /// 解析出来的数据回调
  /// barCode data onChanged
  EventBarcodeListen? onDataChanged;

  /// 解析出来的数据
  /// barCode data
  AnalysisImageModel? data;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.qrCode];

  @override
  Future<bool> initialize({CameraEventListen? listen}) =>
      super.initialize(listen: eventListen);

  /// 设置设别码类型
  /// Set type
  Future<bool> setBarcodeFormat(List<BarcodeFormat> barcodeFormats) async {
    if (!_supportPlatform) return false;
    _barcodeFormats = barcodeFormats;
    final bool? state = await channel.invokeMethod<bool?>(
        'setBarcodeFormat',
        _barcodeFormats
            .map((BarcodeFormat e) => e.toString().split('.')[1])
            .toSet()
            .toList());
    return state ?? false;
  }

  @override
  void eventListen(dynamic data) {
    super.eventListen(data);
    if (data is Map) {
      final List<dynamic>? barcodes = data['barcodes'] as List<dynamic>?;
      if (barcodes != null) {
        data = AnalysisImageModel.fromMap(data);
        if (onDataChanged != null) onDataChanged!(data);
      }
    }
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
      assert(FlCameraEvent().isPaused, 'Please initialize FLCameraEvent');
    }
    final dynamic map = await channel.invokeMethod<dynamic>(
        'scanImageByte', <String, dynamic>{
      'byte': uint8list,
      'useEvent': useEvent,
      'rotationDegrees': rotationDegrees
    });
    if (map != null && map is Map) return AnalysisImageModel.fromMap(map);
    return null;
  }

  /// 暂停扫描
  /// Pause scanning
  Future<bool> pauseScan() => _scanncing(false);

  /// 开始扫描
  /// Start scanncing
  Future<bool> startScan() => _scanncing(true);

  /// 获取识别状态
  /// get scan state
  Future<bool?> getScanState() async {
    if (!_supportPlatform) return null;
    return await channel.invokeMethod<bool?>('getScanState');
  }

  Future<bool> _scanncing(bool scan) async {
    if (!_supportPlatform) return false;
    final bool? state = await channel.invokeMethod<bool?>('scan', scan);
    return state ?? false;
  }
}