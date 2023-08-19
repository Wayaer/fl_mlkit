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

  FlMlKitTextRecognizeController._() {
    channel = _flMlKitTextRecognizeChannel;
    cameraEvent.setMethodChannel(channel);
  }

  static FlMlKitTextRecognizeController? _singleton;

  /// 解析出来的数据回调
  /// Recognized data onChanged
  EventRecognizedListen? onDataChanged;

  /// 解析出来的数据
  /// Recognized data
  AnalysisTextModel? data;

  /// 当前间隔时间
  double currentFrequency = 500;

  bool _canScan = false;

  /// 是否可以扫描
  bool get canScan => _canScan;

  RecognizedLanguage _recognizedLanguage = RecognizedLanguage.latin;

  /// The currently recognized language
  RecognizedLanguage get currentRecognizedLanguage => _recognizedLanguage;

  /// 初始化消息通道和基础配置
  /// Initialize the message channel and basic configuration
  @override
  Future<bool> initialize({CameraEventListen? listen}) =>
      super.initialize(listen: _eventListen);

  /// 开始预览
  /// start Preview
  /// [camera] 需要预览的相机 Camera to preview
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

  /// 设置设别的语言
  /// Set recognized language
  Future<bool> setRecognizedLanguage(
      RecognizedLanguage recognizedLanguage) async {
    if (!_supportPlatform) return false;
    _recognizedLanguage = recognizedLanguage;
    final bool? state = await channel.invokeMethod<bool?>(
        'setRecognizedLanguage', _recognizedLanguage.toString().split('.')[1]);
    return state ?? false;
  }

  @protected
  void _eventListen(dynamic data) {
    super.eventListen(data);
    if (!_canScan) return;
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
  /// [useEvent] 返回消息使用 [FlCameraEvent]
  /// The return message uses [FlCameraEvent]
  /// [rotationDegrees] Only Android is supported
  Future<AnalysisTextModel?> scanImageByte(Uint8List uint8list,
      {int rotationDegrees = 0, bool useEvent = false}) async {
    if (!_supportPlatform) return null;
    if (useEvent) {
      assert(FlCameraEvent().isPaused, 'Please initialize FlCameraEvent');
    }
    final dynamic map = await channel.invokeMethod<dynamic>(
        'scanImageByte', <String, dynamic>{
      'byte': uint8list,
      'useEvent': useEvent,
      'rotationDegrees': rotationDegrees
    });
    if (map != null && map is Map) return AnalysisTextModel.fromMap(map);
    return null;
  }

  /// 暂停扫描
  /// Pause scanning
  Future<bool> pauseScan() => _scanning(false);

  /// 开始扫描
  /// Start scanning
  Future<bool> startScan() => _scanning(true);

  @protected
  Future<bool> _scanning(bool scan) async {
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
