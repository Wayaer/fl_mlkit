part of '../fl_mlkit_text_recognize.dart';

enum RecognizedLanguage {
  /// Including English
  /// A language of 26 letters
  latin,

  /// 中文
  chinese,

  /// 日本語
  japanese,

  /// 한국어
  korean,

  /// देवनागरी
  devanagari,
}

class FlMlKitTextRecognizeController extends CameraController {
  factory FlMlKitTextRecognizeController() =>
      _singleton ??= FlMlKitTextRecognizeController._();

  FlMlKitTextRecognizeController._();

  final MethodChannel _channel = const MethodChannel('fl.mlkit.text.recognize');

  static FlMlKitTextRecognizeController? _singleton;

  /// 解析出来的数据回调
  /// Recognized data onChanged
  EventRecognizedListen? onDataChanged;

  /// 解析出来的数据
  /// Recognized data
  AnalysisTextModel? data;

  /// 当前间隔时间
  double _frequency = 500;

  bool _canRecognize = false;

  bool get canRecognize => _canRecognize;

  RecognizedLanguage _recognizedLanguage = RecognizedLanguage.latin;

  /// The currently recognized language
  RecognizedLanguage get recognizedLanguage => _recognizedLanguage;

  /// 初始化消息通道和基础配置
  /// Initialize the message channel and basic configuration
  @override
  Future<bool> initialize([FlEventListenData? onData]) =>
      super.initialize(onData ?? _onData);

  /// 设置 params
  /// Set params
  Future<bool> setParams({double? frequency, bool? canRecognize}) async {
    if (!_supportPlatform) return false;
    if (frequency != null) _frequency = frequency;
    if (canRecognize != null) _canRecognize = canRecognize;
    final bool? state = await _channel.invokeMethod<bool?>('setParams', {
      'frequency': _frequency,
      'canRecognize': _canRecognize,
    });
    return state ?? false;
  }

  /// 设置设别的语言
  /// Set recognized language
  Future<bool> setRecognizedLanguage(
      RecognizedLanguage recognizedLanguage) async {
    if (!_supportPlatform) return false;
    _recognizedLanguage = recognizedLanguage;
    final bool? state = await _channel.invokeMethod<bool?>(
        'setRecognizedLanguage', _recognizedLanguage.toString().split('.')[1]);
    return state ?? false;
  }

  @protected
  void _onData(dynamic data) {
    super.onData(data);
    if (!_canRecognize) return;
    if (data is Map) {
      final String? barcodes = data['text'] as String?;
      if (barcodes != null) {
        data = AnalysisTextModel.fromMap(data);
        onDataChanged?.call(data);
      }
    }
  }

  /// 识别图片字节
  /// Identify picture bytes
  /// [useEvent] 返回消息使用 [FlEvent]
  /// The return message uses [FlEvent]
  /// [rotationDegrees] Only Android is supported
  Future<AnalysisTextModel?> recognizeImageByte(Uint8List uint8list,
      {int rotationDegrees = 0, bool useEvent = false}) async {
    if (!_supportPlatform) return null;
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>?>(
        'recognizeImageByte', {
      'byte': uint8list,
      'useEvent': useEvent,
      'rotationDegrees': rotationDegrees
    });
    if (map != null) return AnalysisTextModel.fromMap(map);
    return null;
  }

  /// 暂停扫描
  /// Pause recognize
  Future<bool> pauseRecognize() => setParams(canRecognize: false);

  /// 开始扫描
  /// Start recognize
  Future<bool> startRecognize() => setParams(canRecognize: true);

  @override
  Future<bool> dispose() async {
    await super.dispose();
    final state = await _channel.invokeMethod<bool?>('dispose');
    return state ?? false;
  }
}
