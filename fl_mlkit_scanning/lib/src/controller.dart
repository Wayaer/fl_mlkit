part of '../fl_mlkit_scanning.dart';

/// 扫码控制器单例。
///
/// 在相机预览的基础上提供条码格式、扫描频率、暂停/继续等控制能力：
///
/// ```dart
/// final controller = FlMlKitScanningController();
/// await controller.initialize();
/// await controller.setBarcodeFormat(<BarcodeFormat>[BarcodeFormat.qrCode]);
/// await controller.startPreview(cameras!.first);
/// ```
class FlMlKitScanningController extends CameraController {
  factory FlMlKitScanningController() => _instance;

  FlMlKitScanningController._();

  static final FlMlKitScanningController _instance = FlMlKitScanningController._();

  /// 全局单例。
  static FlMlKitScanningController get instance => _instance;

  final MethodChannel _channel = const MethodChannel('fl.mlkit.scanning');

  /// 扫码使用独立的事件通道，避免与相机 / OCR 控制器共用同一通道导致监听被覆盖。
  @override
  String get eventChannelName => 'fl.camera.scanning.event';

  /// 解析结果回调，相机扫描与图片扫描均会触发。
  EventBarcodeListen? onDataChanged;

  /// 最近一次解析结果。
  AnalysisImageModel? data;

  double _frequency = 500;

  bool _canScanning = true;

  /// 当前是否允许扫描。
  bool get canScanning => _canScanning;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.all];

  /// 当前识别的条码格式列表。
  List<BarcodeFormat> get barcodeFormats => _barcodeFormats;

  /// 设置扫描参数。
  ///
  /// [frequency] 为两次解析的最小间隔，单位毫秒，建议 500 ~ 1500；
  /// [canScanning] 为 false 时暂停扫描，相机帧会被直接丢弃。
  Future<bool> setParams({double? frequency, bool? canScanning}) async {
    if (!_supportPlatform) return false;
    if (frequency != null) _frequency = frequency;
    if (canScanning != null) _canScanning = canScanning;
    try {
      final bool? state = await _channel.invokeMethod<bool>('setParams', <String, dynamic>{
        'frequency': _frequency,
        'canScanning': _canScanning,
      });
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('setParams error: $error');
      return false;
    }
  }

  /// 设置识别的条码格式。
  ///
  /// 传入 [BarcodeFormat.all] 或空列表时，会识别所有支持的格式。
  Future<bool> setBarcodeFormat(List<BarcodeFormat> barcodeFormats) async {
    if (!_supportPlatform) return false;
    // unknown 不是可识别格式，直接忽略；全空或包含 all 时按识别全部处理。
    List<BarcodeFormat> formats = barcodeFormats
        .where((BarcodeFormat format) => format != BarcodeFormat.unknown)
        .toList();
    if (formats.isEmpty || (formats.contains(BarcodeFormat.all) && formats.length > 1)) {
      formats = <BarcodeFormat>[BarcodeFormat.all];
    }
    formats = formats.toSet().toList(growable: false);
    try {
      final bool? state = await _channel.invokeMethod<bool>(
        'setBarcodeFormat',
        formats.map((BarcodeFormat format) => format.name).toList(growable: false),
      );
      if (state == true) _barcodeFormats = formats;
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('setBarcodeFormat error: $error');
      return false;
    }
  }

  @override
  FlEventChannelListenData get onDataListen => (dynamic event) {
    super.onDataListen(event);
    if (!_canScanning || event is! Map) return;
    final List<dynamic>? barcodes = event['barcodes'] as List<dynamic>?;
    if (barcodes == null) return;
    final AnalysisImageModel model = AnalysisImageModel.fromMap(event);
    data = model;
    onDataChanged?.call(model);
  };

  /// 识别图片字节。
  ///
  /// [uint8list] 为图片原始字节；[rotationDegrees] 仅 Android 生效。
  /// 识别结果同时会通过 [onDataChanged] 回调。
  Future<AnalysisImageModel?> scanningImageByte(Uint8List uint8list, {int rotationDegrees = 0}) async {
    if (!_supportPlatform) return null;
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'scanningImageByte',
        <String, dynamic>{'byte': uint8list, 'rotationDegrees': rotationDegrees},
      );
      if (map == null) return null;
      final AnalysisImageModel model = AnalysisImageModel.fromMap(map);
      data = model;
      onDataChanged?.call(model);
      return model;
    } on PlatformException catch (error) {
      debugPrint('scanningImageByte error: $error');
      return null;
    }
  }

  @override
  Future<FlCameraOptions?> startPreview(CameraInfo camera, {CameraResolution? resolution}) async {
    // 直接使用控制器时不会经过组件的 setParams，这里确保原生已注册相机帧监听。
    await setParams(frequency: _frequency, canScanning: _canScanning);
    return super.startPreview(camera, resolution: resolution);
  }

  /// 暂停扫描。
  Future<bool> pauseScanning() => setParams(canScanning: false);

  /// 继续扫描。
  Future<bool> startScanning() => setParams(canScanning: true);

  @override
  Future<void> releaseNativeResources() async {
    try {
      await _channel.invokeMethod<bool>('dispose');
    } on PlatformException catch (error) {
      debugPrint('scanning dispose error: $error');
    } finally {
      data = null;
    }
  }
}
