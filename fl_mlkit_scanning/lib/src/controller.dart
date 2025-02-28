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

  bool _canScanning = true;

  bool get canScanning => _canScanning;

  List<BarcodeFormat> _barcodeFormats = [BarcodeFormat.all];

  /// The currently BarcodeFormat
  List<BarcodeFormat> get barcodeFormats => _barcodeFormats;

  /// 设置 params
  /// Set params
  Future<bool> setParams({double? frequency, bool? canScanning}) async {
    if (!_supportPlatform) return false;
    if (frequency != null) _frequency = frequency;
    if (canScanning != null) _canScanning = canScanning;
    final state = await _channel.invokeMethod<bool>('setParams', {
      'frequency': _frequency,
      'canScanning': _canScanning,
    });
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
    final state = await _channel.invokeMethod<bool>(
      'setBarcodeFormat',
      barcodeFormats
          .map((BarcodeFormat e) => e.toString().split('.')[1])
          .toSet()
          .toList(),
    );
    if (state == true) _barcodeFormats = barcodeFormats;
    return state ?? false;
  }

  @override
  FlEventChannelListenData get onDataListen => (dynamic data) {
        super.onDataListen(data);
        if (!_canScanning) return;
        if (data is Map) {
          final List<dynamic>? barcodes = data['barcodes'] as List<dynamic>?;
          if (barcodes != null) {
            data = AnalysisImageModel.fromMap(data);
            onDataChanged?.call(data);
          }
        }
      };

  /// 识别图片字节
  /// Identify picture bytes
  /// The return message uses [FlEvent]
  /// [rotationDegrees] Only Android is supported
  Future<AnalysisImageModel?> scanningImageByte(
    Uint8List uint8list, {
    int rotationDegrees = 0,
  }) async {
    if (!_supportPlatform) return null;
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'scanningImageByte',
      {'byte': uint8list, 'rotationDegrees': rotationDegrees},
    );
    if (map != null) return AnalysisImageModel.fromMap(map);
    return null;
  }

  /// 暂停扫描
  /// Pause scanning
  Future<bool> pauseScanning() => setParams(canScanning: false);

  /// 开始扫描
  /// Start scanning
  Future<bool> startScanning() => setParams(canScanning: true);

  @override
  Future<bool> dispose() async {
    await super.dispose();
    final state = await _channel.invokeMethod<bool>('dispose');
    return state ?? false;
  }
}
