part of '../fl_mlkit_scanning.dart';

/// 条码识别回调。
typedef EventBarcodeListen = void Function(AnalysisImageModel data);

/// 扫码组件。
///
/// 基于 [FlCamera] 的相机预览，自动识别画面中的条码，并通过
/// [onDataChanged] 回调返回坐标与解析后的结构化数据。
class FlMlKitScanning extends StatefulWidget {
  /// 创建扫码组件。
  FlMlKitScanning({
    super.key,
    List<BarcodeFormat>? barcodeFormats,
    this.onDataChanged,
    this.overlay,
    this.onFlashChanged,
    this.autoScanning = true,
    this.onZoomChanged,
    this.updateReset = false,
    this.camera,
    this.resolution = CameraResolution.medium,
    this.fit = BoxFit.fitWidth,
    this.uninitialized,
    this.frequency = 500,
  }) : barcodeFormats = barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qrCode];

  /// 需要识别的条码格式，默认仅识别二维码。
  final List<BarcodeFormat> barcodeFormats;

  /// 显示在预览画面之上的浮层。
  final Widget? overlay;

  /// 相机未初始化 / 已停止预览时显示的占位 UI。
  final Widget? uninitialized;

  /// 闪光灯变化回调。
  final ValueChanged<FlashState>? onFlashChanged;

  /// 缩放变化回调。
  final ValueChanged<CameraZoomState>? onZoomChanged;

  /// 条码识别回调。
  final EventBarcodeListen? onDataChanged;

  /// 组件更新时是否重新打开相机。
  final bool updateReset;

  /// 是否在打开相机后自动开始扫描，默认 true。
  final bool autoScanning;

  /// 需要预览的相机，为空时使用后置摄像头。
  final CameraInfo? camera;

  /// 预览分辨率。
  final CameraResolution resolution;

  /// 两次解析的最小间隔，单位毫秒。
  ///
  /// 数值越小识别越快，但 iOS 上 CPU 占用越高，建议 500 ~ 1500。
  final double frequency;

  /// 预览画面在容器中的填充方式。
  final BoxFit fit;

  @override
  FlCameraState<FlMlKitScanning> createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  late final FlMlKitScanningController _controller;

  int _openGeneration = 0;

  @override
  void initState() {
    _controller = FlMlKitScanningController();
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
    await _controller.setBarcodeFormat(widget.barcodeFormats);
    await _controller.setParams(frequency: widget.frequency, canScanning: widget.autoScanning);
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
  void didUpdateWidget(covariant FlMlKitScanning oldWidget) {
    super.didUpdateWidget(oldWidget);
    uninitialized = widget.uninitialized;
    _controller.onFlashChanged = widget.onFlashChanged;
    _controller.onZoomChanged = widget.onZoomChanged;
    _controller.onDataChanged = widget.onDataChanged;
    if (!listEquals(oldWidget.barcodeFormats, widget.barcodeFormats)) {
      _controller.setBarcodeFormat(widget.barcodeFormats);
    }
    if (oldWidget.frequency != widget.frequency) {
      _controller.setParams(frequency: widget.frequency);
    }
    if (oldWidget.autoScanning != widget.autoScanning) {
      _controller.setParams(canScanning: widget.autoScanning);
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
