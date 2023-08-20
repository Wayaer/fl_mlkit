part of '../fl_mlkit_scanning.dart';

typedef EventBarcodeListen = void Function(AnalysisImageModel data);

typedef FlMlKitScanningCreateCallback = void Function(
    FlMlKitScanningController controller);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
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
    this.onCreateView,
    this.uninitialized,
    this.frequency = 500,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qrCode],
        super(key: key);

  /// 码识别类型
  /// Identification type
  final List<BarcodeFormat> barcodeFormats;

  /// 显示在预览框上面
  /// Display above preview box
  final Widget? overlay;

  /// 停止预览时显示的UI
  /// The UI displayed when the camera is not uninitialized
  final Widget? uninitialized;

  /// Flash change
  final ValueChanged<FlashState>? onFlashChanged;

  /// 缩放变化
  /// zoom ratio
  final ValueChanged<CameraZoomState>? onZoomChanged;

  /// 码识别回调
  /// Identify callback
  final EventBarcodeListen? onDataChanged;

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

  /// 如果你设置为10, 2次解析数据间隔为10 毫秒，数字越小 在ios上cpu占有率越高，数字越大，识别速度会变慢，建议设置500-1500
  /// If you set it to 10, The interval between data parsing is 10 milliseconds
  /// The larger the number, the slower the parsing,If the number is too small, the CPU percentage will be too high on ios
  /// Therefore, the recommended setting range is 500 to 1500
  final double frequency;

  /// How a camera box should be inscribed into another box.
  final BoxFit fit;

  /// get Controller
  final FlMlKitScanningCreateCallback? onCreateView;

  @override
  FlCameraState<FlMlKitScanning> createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  FlashState? _flashState;
  CameraZoomState? _zoomState;

  @override
  void initState() {
    controller = FlMlKitScanningController();
    super.initState();
    uninitialized = widget.uninitialized;
    controller.addListener(changedListener);
    WidgetsBinding.instance.addPostFrameCallback((Duration time) async {
      await (controller as FlMlKitScanningController).initialize();
      widget.onCreateView?.call(controller as FlMlKitScanningController);
      initialize();
    });
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
    var scanningController = controller as FlMlKitScanningController;
    await scanningController.setBarcodeFormat(widget.barcodeFormats);
    await scanningController.setParams(frequency: widget.frequency);
    if (widget.onDataChanged != null) {
      scanningController.onDataChanged = widget.onDataChanged;
    }
    final options = await scanningController.startPreview(camera,
        resolution: widget.resolution);
    if (options != null && mounted) {
      if (widget.autoScanning) scanningController.startScan();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FlMlKitScanning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChanged != widget.onFlashChanged ||
        oldWidget.onZoomChanged != widget.onZoomChanged ||
        oldWidget.camera != widget.camera ||
        oldWidget.barcodeFormats != widget.barcodeFormats ||
        oldWidget.uninitialized != widget.uninitialized ||
        oldWidget.autoScanning != widget.autoScanning) {
      if (widget.updateReset) controller.resetCamera();
      setState(() {});
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