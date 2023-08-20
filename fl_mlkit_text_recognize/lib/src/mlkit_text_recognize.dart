part of '../fl_mlkit_text_recognize.dart';

typedef EventRecognizedListen = void Function(AnalysisTextModel text);
typedef FlMlKitTextRecognizeCreateCallback = void Function(
    FlMlKitTextRecognizeController controller);

class FlMlKitTextRecognize extends StatefulWidget {
  const FlMlKitTextRecognize({
    Key? key,
    this.onDataChanged,
    this.overlay,
    this.uninitialized,
    this.onFlashChanged,
    this.autoRecognize = true,
    this.onZoomChanged,
    this.camera,
    this.resolution = CameraResolution.high,
    this.updateReset = false,
    this.fit = BoxFit.fitWidth,
    this.recognizedLanguage = RecognizedLanguage.latin,
    this.frequency = 500,
  }) : super(key: key);

  /// 识别回调
  /// Identify callback
  final EventRecognizedListen? onDataChanged;

  /// 显示在预览框上面
  /// Display above preview box
  final Widget? overlay;

  /// 相机在未初始化时显示的UI
  /// The UI displayed when the camera is not initialized
  final Widget? uninitialized;

  /// Flash change
  final ValueChanged<FlashState>? onFlashChanged;

  /// 缩放变化
  /// zoom ratio
  final ValueChanged<CameraZoomState>? onZoomChanged;

  /// 更新组件时是否重置相机
  /// Reset camera when updating components
  final bool updateReset;

  /// 是否自动识别 默认为[true]
  /// Auto recognize defaults to [true]
  final bool autoRecognize;

  /// 需要预览的相机
  /// Camera ID to preview
  final CameraInfo? camera;

  /// 预览相机支持的分辨率
  /// Preview the resolution supported by the camera
  final CameraResolution resolution;

  /// How a camera box should be inscribed into another box.
  final BoxFit fit;

  /// 需要是别的语言类型
  /// Language to be recognized
  final RecognizedLanguage recognizedLanguage;

  /// 如果你设置为10, 2次解析数据间隔为10 毫秒，数字越小 在ios上cpu占有率越高，数字越大，识别速度会变慢，建议设置500-1500
  /// If you set it to 10, The interval between data parsing is 10 milliseconds
  /// The larger the number, the slower the parsing,If the number is too small, the CPU percentage will be too high on ios
  /// Therefore, the recommended setting range is 500 to 1500
  final double frequency;

  @override
  FlCameraState<FlMlKitTextRecognize> createState() =>
      _FlMlKitTextRecognizeState();
}

class _FlMlKitTextRecognizeState extends FlCameraState<FlMlKitTextRecognize> {
  late FlMlKitTextRecognizeController _controller;

  @override
  void initState() {
    _controller = FlMlKitTextRecognizeController();
    controller = _controller;
    super.initState();
    uninitialized = widget.uninitialized;
    WidgetsBinding.instance.addPostFrameCallback((Duration time) async {
      await _controller.initialize();
      initialize();
    });
    _controller.onFlashChanged = widget.onFlashChanged;
    _controller.onZoomChanged = widget.onZoomChanged;
  }

  Future<void> initialize() async {
    var camera = widget.camera;
    if (camera == null) {
      final List<CameraInfo>? cameras = _controller.cameras;
      if (cameras == null) return;
      for (final CameraInfo cameraInfo in cameras) {
        if (cameraInfo.lensFacing == CameraLensFacing.back) {
          camera = cameraInfo;
          break;
        }
      }
    }
    if (camera == null) return;

    await _controller.setRecognizedLanguage(widget.recognizedLanguage);
    await _controller.setParams(frequency: widget.frequency);
    if (widget.onDataChanged != null) {
      _controller.onDataChanged = widget.onDataChanged;
    }
    final options =
        await _controller.startPreview(camera, resolution: widget.resolution);
    if (options != null && mounted) {
      if (widget.autoRecognize) _controller.startRecognize();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FlMlKitTextRecognize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChanged != widget.onFlashChanged ||
        oldWidget.onZoomChanged != widget.onZoomChanged ||
        oldWidget.camera != widget.camera ||
        oldWidget.autoRecognize != widget.autoRecognize) {
      if (widget.updateReset) _controller.resetCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    boxFit = widget.fit;
    Widget current = super.build(context);
    if (widget.overlay != null) {
      current = Stack(children: <Widget>[
        current,
        SizedBox.expand(child: widget.overlay),
      ]);
    }
    return current;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
