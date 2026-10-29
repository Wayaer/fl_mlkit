part of '../fl_mlkit_text_recognize.dart';

/// 文字识别回调。
typedef EventRecognizedListen = void Function(AnalysisTextModel text);

/// 文字识别组件。
///
/// 基于 [FlCamera] 的相机预览，自动识别画面中的文字，并通过
/// [onDataChanged] 返回文字块、行、元素及其坐标。
class FlMlKitTextRecognize extends StatefulWidget {
  /// 创建文字识别组件。
  const FlMlKitTextRecognize({
    super.key,
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
  });

  /// 识别回调。
  final EventRecognizedListen? onDataChanged;

  /// 显示在预览画面之上的浮层。
  final Widget? overlay;

  /// 相机未初始化 / 已停止预览时显示的占位 UI。
  final Widget? uninitialized;

  /// 闪光灯变化回调。
  final ValueChanged<FlashState>? onFlashChanged;

  /// 缩放变化回调。
  final ValueChanged<CameraZoomState>? onZoomChanged;

  /// 组件更新时是否重新打开相机。
  final bool updateReset;

  /// 是否在打开相机后自动开始识别，默认 true。
  final bool autoRecognize;

  /// 需要预览的相机，为空时使用后置摄像头。
  final CameraInfo? camera;

  /// 预览分辨率。
  final CameraResolution resolution;

  /// 预览画面在容器中的填充方式。
  final BoxFit fit;

  /// 需要识别的语言。
  final RecognizedLanguage recognizedLanguage;

  /// 两次识别的最小间隔，单位毫秒。
  ///
  /// 数值越小识别越快，但 iOS 上 CPU 占用越高，建议 500 ~ 1500。
  final double frequency;

  @override
  FlCameraState<FlMlKitTextRecognize> createState() => _FlMlKitTextRecognizeState();
}

class _FlMlKitTextRecognizeState extends FlCameraState<FlMlKitTextRecognize> {
  late final FlMlKitTextRecognizeController _controller;

  int _openGeneration = 0;

  @override
  void initState() {
    _controller = FlMlKitTextRecognizeController();
    controller = _controller;
    super.initState();
    uninitialized = widget.uninitialized;
    _controller.onFlashChanged = widget.onFlashChanged;
    _controller.onZoomChanged = widget.onZoomChanged;
    _controller.onDataChanged = widget.onDataChanged;
    _controller.onNativeDisposed = _handleNativeDisposed;
    WidgetsBinding.instance.addPostFrameCallback((Duration time) {
      if (mounted) unawaited(_initializeAndOpen());
    });
  }

  /// 原生相机被释放（例如 Activity 重建）后立即重建预览，不依赖生命周期事件。
  void _handleNativeDisposed() {
    if (!mounted || !isOwner) return;
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    // 应用正在退出或进入后台时不再重新打开相机。
    if (state != null && state != AppLifecycleState.resumed) return;
    unawaited(_initializeAndOpen());
  }

  Future<void> _initializeAndOpen() async {
    if (!mounted || !isOwner) return;
    final bool initialized = await _controller.initialize();
    if (initialized && mounted && isOwner) await _openCamera();
  }

  /// 应用组件参数并打开默认（或指定）摄像头。
  Future<void> _openCamera() async {
    if (!mounted || !isOwner) return;
    final int generation = ++_openGeneration;
    CameraInfo? camera = widget.camera;
    if (camera == null) {
      final List<CameraInfo>? cameras = _controller.cameras;
      if (cameras == null || cameras.isEmpty) return;
      for (final CameraInfo cameraInfo in cameras) {
        if (cameraInfo.lensFacing == CameraLensFacing.back) {
          camera = cameraInfo;
          break;
        }
      }
      camera ??= cameras.first;
    }
    await _controller.setRecognizedLanguage(widget.recognizedLanguage);
    await _controller.setParams(frequency: widget.frequency, canRecognize: widget.autoRecognize);
    // 先停止旧预览：原生会在启动新预览时释放旧纹理，直接覆盖会让 Flutter 引用已失效的纹理。
    await _controller.stopPreview();
    if (!mounted || !isOwner || generation != _openGeneration) return;
    final FlCameraOptions? options = await _controller.startPreview(camera, resolution: widget.resolution);
    if (options != null && mounted && isOwner && generation == _openGeneration) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 权限被拒绝后用户在系统设置中授权，回到前台时补一次初始化与预览。
    if (state == AppLifecycleState.resumed && !_controller.isInitialized && mounted && isOwner) {
      unawaited(_initializeAndOpen());
    }
  }

  @override
  void didUpdateWidget(covariant FlMlKitTextRecognize oldWidget) {
    super.didUpdateWidget(oldWidget);
    uninitialized = widget.uninitialized;
    _controller.onFlashChanged = widget.onFlashChanged;
    _controller.onZoomChanged = widget.onZoomChanged;
    _controller.onDataChanged = widget.onDataChanged;
    if (oldWidget.recognizedLanguage != widget.recognizedLanguage) {
      _controller.setRecognizedLanguage(widget.recognizedLanguage);
    }
    if (oldWidget.frequency != widget.frequency) {
      _controller.setParams(frequency: widget.frequency);
    }
    if (oldWidget.autoRecognize != widget.autoRecognize) {
      _controller.setParams(canRecognize: widget.autoRecognize);
    }
    final bool cameraChanged = oldWidget.camera != widget.camera || oldWidget.resolution != widget.resolution;
    if (cameraChanged && widget.updateReset) {
      _openCamera();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    boxFit = widget.fit;
    Widget current = super.build(context);
    if (widget.overlay != null) {
      current = Stack(
        children: <Widget>[
          current,
          SizedBox.expand(child: widget.overlay),
        ],
      );
    }
    return current;
  }

  @override
  void dispose() {
    // 只有仍是最新的使用方时才清理回调并释放相机，避免退出动画期间误伤新页面。
    if (releaseController()) _controller.onDataChanged = null;
    super.dispose();
  }
}
