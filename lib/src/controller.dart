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

  /// 当前间隔时间
  double currentFrequency = 500;

  bool _canScan = false;

  /// 是否可以扫描
  bool get canScan => _canScan;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.all];

  /// The currently BarcodeFormat
  List<BarcodeFormat> get currentBarcodeFormats => _barcodeFormats;

  /// 初始化消息通道和基础配置
  /// Initialize the message channel and basic configuration
  @override
  Future<bool> initialize({CameraEventListen? listen}) =>
      super.initialize(listen: _eventListen);

  /// 开始预览
  /// start Preview
  /// [camerId] 需要预览的相机 Camera ID to preview
  /// [frequency] 解析频率 Analytical frequency
  /// [resolution] 预览相机支持的分辨率 Preview the resolution supported by the camera
  @override
  Future<FlCameraOptions?> startPreview(CameraInfo camera,
      {CameraResolution? resolution,
      Map<String, dynamic>? options,
      double? frequency}) {
    if (frequency != null) currentFrequency = frequency;
    final arguments = <String, dynamic>{'frequency': currentFrequency};
    if (options != null) arguments.addAll(options);
    return super
        .startPreview(camera, resolution: resolution, options: arguments);
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
    final bool? state = await channel.invokeMethod<bool?>(
        'setBarcodeFormat',
        barcodeFormats
            .map((BarcodeFormat e) => e.toString().split('.')[1])
            .toSet()
            .toList());
    if (state == true) _barcodeFormats = barcodeFormats;
    return state ?? false;
  }

  @protected
  void _eventListen(dynamic data) {
    super.eventListen(data);
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

  @protected
  Future<bool> _scanncing(bool scan) async {
    if (!_supportPlatform || _canScan == scan) return false;
    _canScan = scan;
    notifyListeners();
    final bool? state = await channel.invokeMethod<bool?>('scan', scan);
    if (state != true) {
      _canScan = !_canScan;
      notifyListeners();
    }
    return state ?? false;
  }
}
