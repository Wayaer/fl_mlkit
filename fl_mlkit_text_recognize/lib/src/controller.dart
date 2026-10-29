part of '../fl_mlkit_text_recognize.dart';

/// 文字识别支持的语言。
enum RecognizedLanguage {
  /// 拉丁语系，包括英语等 26 个字母的语言。
  latin,

  /// 中文。
  chinese,

  /// 日语。
  japanese,

  /// 韩语。
  korean,

  /// 天城文（印地语、梵语等）。
  devanagari,
}

/// 文字识别控制器单例。
///
/// ```dart
/// final controller = FlMlKitTextRecognizeController();
/// await controller.initialize();
/// await controller.setRecognizedLanguage(RecognizedLanguage.chinese);
/// await controller.startPreview(cameras!.first);
/// await controller.startRecognize();
/// ```
class FlMlKitTextRecognizeController extends CameraController {
  factory FlMlKitTextRecognizeController() => _instance;

  FlMlKitTextRecognizeController._();

  static final FlMlKitTextRecognizeController _instance = FlMlKitTextRecognizeController._();

  /// 全局单例。
  static FlMlKitTextRecognizeController get instance => _instance;

  final MethodChannel _channel = const MethodChannel('fl.mlkit.text.recognize');

  /// OCR 使用独立的事件通道，避免与相机 / 扫码控制器共用同一通道导致监听被覆盖。
  @override
  String get eventChannelName => 'fl.camera.ocr.event';

  /// 识别结果回调，相机识别与图片识别均会触发。
  EventRecognizedListen? onDataChanged;

  /// 最近一次识别结果。
  AnalysisTextModel? data;

  double _frequency = 500;

  bool _canRecognize = false;

  /// 当前是否允许识别。
  bool get canRecognize => _canRecognize;

  RecognizedLanguage _recognizedLanguage = RecognizedLanguage.latin;

  /// 当前识别的语言。
  RecognizedLanguage get recognizedLanguage => _recognizedLanguage;

  /// 设置识别参数。
  ///
  /// [frequency] 为两次识别的最小间隔，单位毫秒，建议 500 ~ 1500；
  /// [canRecognize] 为 false 时会暂停识别，相机帧会被直接丢弃。
  Future<bool> setParams({double? frequency, bool? canRecognize}) async {
    if (!_supportPlatform) return false;
    if (frequency != null) _frequency = frequency;
    if (canRecognize != null) _canRecognize = canRecognize;
    try {
      final bool? state = await _channel.invokeMethod<bool>('setParams', <String, dynamic>{
        'frequency': _frequency,
        'canRecognize': _canRecognize,
      });
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('setParams error: $error');
      return false;
    }
  }

  /// 设置识别的语言。
  ///
  /// 原生识别器会按语言重新创建，切换后建议等待返回再继续识别。
  Future<bool> setRecognizedLanguage(RecognizedLanguage recognizedLanguage) async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('setRecognizedLanguage', recognizedLanguage.name);
      if (state == true) _recognizedLanguage = recognizedLanguage;
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('setRecognizedLanguage error: $error');
      return false;
    }
  }

  @override
  FlEventChannelListenData get onDataListen => (dynamic event) {
    super.onDataListen(event);
    if (!_canRecognize || event is! Map) return;
    if (event['text'] is! String) return;
    final AnalysisTextModel model = AnalysisTextModel.fromMap(event);
    data = model;
    onDataChanged?.call(model);
  };

  /// 识别图片字节。
  ///
  /// [uint8list] 为图片原始字节；[rotationDegrees] 仅 Android 生效。
  /// 识别结果同时会通过 [onDataChanged] 回调。
  Future<AnalysisTextModel?> recognizeImageByte(Uint8List uint8list, {int rotationDegrees = 0}) async {
    if (!_supportPlatform) return null;
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'recognizeImageByte',
        <String, dynamic>{'byte': uint8list, 'rotationDegrees': rotationDegrees},
      );
      if (map == null) return null;
      final AnalysisTextModel model = AnalysisTextModel.fromMap(map);
      data = model;
      onDataChanged?.call(model);
      return model;
    } on PlatformException catch (error) {
      debugPrint('recognizeImageByte error: $error');
      return null;
    }
  }

  @override
  Future<FlCameraOptions?> startPreview(CameraInfo camera, {CameraResolution? resolution}) async {
    // 直接使用控制器时不会经过组件的 setParams，这里确保原生已注册相机帧监听。
    await setParams(frequency: _frequency, canRecognize: _canRecognize);
    return super.startPreview(camera, resolution: resolution);
  }

  /// 暂停识别。
  Future<bool> pauseRecognize() => setParams(canRecognize: false);

  /// 继续识别。
  Future<bool> startRecognize() => setParams(canRecognize: true);

  @override
  Future<void> releaseNativeResources() async {
    try {
      await _channel.invokeMethod<bool>('dispose');
    } on PlatformException catch (error) {
      debugPrint('recognize dispose error: $error');
    } finally {
      data = null;
    }
  }
}
