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
    this.autoScanning = true,
    this.onZoomChanged,
    this.camera,
    this.resolution = CameraResolution.high,
    this.updateReset = false,
    this.fit = BoxFit.fitWidth,
    this.recognizedLanguage = RecognizedLanguage.latin,
    this.onCreateView,
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

  /// 是否自动扫描 默认为[true]
  /// Auto scan defaults to [true]
  final bool autoScanning;

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

  /// get Controller
  final FlMlKitTextRecognizeCreateCallback? onCreateView;

  @override
  FlCameraState<FlMlKitTextRecognize> createState() =>
      _FlMlKitTextRecognizeState();
}

class _FlMlKitTextRecognizeState extends FlCameraState<FlMlKitTextRecognize> {
  FlashState? _flashState;
  CameraZoomState? _zoomState;

  @override
  void initState() {
    controller = FlMlKitTextRecognizeController();
    super.initState();
    uninitialized = widget.uninitialized;
    controller.addListener(changedListener);
    WidgetsBinding.instance.addPostFrameCallback((Duration time) async {
      await (controller as FlMlKitTextRecognizeController).initialize();
      widget.onCreateView?.call(controller as FlMlKitTextRecognizeController);
      initialize();
    });
  }

  Future<void> initialize() async {
    var camera = widget.camera;
    if (camera == null) {
      final List<CameraInfo>? cameras = controller.cameras;
      if (cameras == null) return;
      for (final CameraInfo cameraInfo in cameras) {
        if (cameraInfo.lensFacing == CameraLensFacing.back) {
          camera = cameraInfo;
          break;
        }
      }
    }
    if (camera == null) return;
    var textController = controller as FlMlKitTextRecognizeController;
    await textController.setRecognizedLanguage(widget.recognizedLanguage);
    if (widget.onDataChanged != null) {
      textController.onDataChanged = widget.onDataChanged;
    }
    final options = await textController.startPreview(camera,
        resolution: widget.resolution, frequency: widget.frequency);
    if (options != null && mounted) {
      if (widget.autoScanning) textController.startScan();
      setState(() {});
    }
  }

  void changedListener() {
    if (controller.cameraFlash != null &&
        controller.cameraFlash != _flashState) {
      _flashState = controller.cameraFlash!;
      widget.onFlashChanged?.call(_flashState!);
    }
    if (controller.cameraZoom != null && controller.cameraZoom != _zoomState) {
      _zoomState = controller.cameraZoom!;
      widget.onZoomChanged?.call(_zoomState!);
    }
  }

  @override
  void didUpdateWidget(covariant FlMlKitTextRecognize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChanged != widget.onFlashChanged ||
        oldWidget.onZoomChanged != widget.onZoomChanged ||
        oldWidget.camera != widget.camera ||
        oldWidget.autoScanning != widget.autoScanning) {
      if (widget.updateReset) controller.resetCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    boxFit = widget.fit;
    Widget camera = super.build(context);
    if (widget.overlay != null) {
      camera = Stack(children: <Widget>[
        camera,
        SizedBox.expand(child: widget.overlay),
      ]);
    }
    return camera;
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(changedListener);
    controller.dispose();
  }
}
