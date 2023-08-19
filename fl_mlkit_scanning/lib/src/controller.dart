part of '../fl_mlkit_scanning.dart';

class FlMlKitScanningController extends CameraController {
  factory FlMlKitScanningController() =>
      _singleton ??= FlMlKitScanningController._();

  FlMlKitScanningController._();

  static FlMlKitScanningController? _singleton;

  final MethodChannel _channel = const MethodChannel('fl.mlkit.scanning');

  /// 解析出来的数据回调
  /// barCode data onChanged
  EventBarcodeListen? onDataChanged;

  /// 解析出来的数据
  /// barCode data
  AnalysisImageModel? data;

  /// 当前间隔时间
  double _frequency = 500;

  bool _canScan = true;

  bool get canScan => _canScan;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.all];

  /// The currently BarcodeFormat
  List<BarcodeFormat> get currentBarcodeFormats => _barcodeFormats;

  /// 初始化消息通道和基础配置
  /// Initialize the message channel and basic configuration
  @override
  Future<bool> initialize([FlEventListenData? onData]) =>
      super.initialize(onData ?? _onData);

  /// 开始预览
  /// start Preview
  /// [camera] 需要预览的相机 Camera to preview
  /// [frequency] 解析频率 Analytical frequency
  /// [resolution] 预览相机支持的分辨率 Preview the resolution supported by the camera
  @override
  Future<FlCameraOptions?> startPreview(CameraInfo camera,
      {CameraResolution? resolution}) {
    return super.startPreview(camera, resolution: resolution);
  }

  /// 设置 frequency
  /// Set params
  Future<bool> setParams({double? frequency, bool? canScan}) async {
    if (!_supportPlatform) return false;
    if (frequency != null) _frequency = frequency;
    if (canScan != null) _canScan = canScan;
    final bool? state = await _channel.invokeMethod<bool?>('setParams', {
      'frequency': _frequency,
      'canScan': _canScan,
    });
    if (state == true) notifyListeners();
    return state ?? false;
  }

  /// 设置设别码类型
  /// Set type
  Future<bool> setBarcodeFormat(List<BarcodeFormat> barcodeFormats) async {
    if (!_supportPlatform) return false;
    if (barcodeFormats.contains(BarcodeFormat.all) &&
        barcodeFormats.length > 1) {
      barcodeFormats = [BarcodeFormat.all];
    }
    if (barcodeFormats.isEmpty) barcodeFormats = [BarcodeFormat.all];
    final bool? state = await _channel.invokeMethod<bool?>(
        'setBarcodeFormat',
        barcodeFormats
            .map((BarcodeFormat e) => e.toString().split('.')[1])
            .toSet()
            .toList());
    if (state == true) _barcodeFormats = barcodeFormats;
    return state ?? false;
  }

  @protected
  void _onData(dynamic data) {
    super.onData(data);
    if (!_canScan) return;
    if (data is Map) {
      final List<dynamic>? barcodes = data['barcodes'] as List<dynamic>?;
      if (barcodes != null) {
        data = AnalysisImageModel.fromMap(data);
        onDataChanged?.call(data);
      }
    }
  }

  /// 识别图片字节
  /// Identify picture bytes
  /// [useEvent] 返回消息使用 [FlCameraEvent]
  /// The return message uses [FlCameraEvent]
  /// [rotationDegrees] Only Android is supported
  Future<AnalysisImageModel?> scanImageByte(Uint8List uint8list,
      {int rotationDegrees = 0, bool useEvent = false}) async {
    if (!_supportPlatform) return null;
    final dynamic map = await _channel.invokeMethod<dynamic>(
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
  Future<bool> pauseScan() => setParams(canScan: false);

  /// 开始扫描
  /// Start scanning
  Future<bool> startScan() => setParams(canScan: true);
}
