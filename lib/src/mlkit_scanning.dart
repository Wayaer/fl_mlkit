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
    this.resolution = CameraResolution.high,
    this.fit = BoxFit.fitWidth,
    this.onCreateView,
    this.notPreviewed,
    this.frequency = 1,
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
  /// The UI displayed when the camera is not previewed
  final Widget? notPreviewed;

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

  /// 解析频率 单位是 毫秒
  /// Analytical frequency The unit is millisecond
  final double frequency;

  /// How a camera box should be inscribed into another box.
  final BoxFit fit;

  /// get Controller
  final FlMlKitScanningCreateCallback? onCreateView;

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    controller = FlMlKitScanningController();
    super.initState();
    notPreviewed = widget.notPreviewed;
    WidgetsBinding.instance!.addPostFrameCallback((Duration time) async {
      await controller.initialize();
      if (widget.onCreateView != null) {
        widget.onCreateView!(controller as FlMlKitScanningController);
      }
      initialize();
    });
    controller.addListener(changedListener);
  }

  void changedListener() {
    if (widget.onFlashChanged != null && controller.cameraFlash != null) {
      widget.onFlashChanged!(controller.cameraFlash!);
    }
    if (widget.onZoomChanged != null && controller.cameraZoom != null) {
      widget.onZoomChanged!(controller.cameraZoom!);
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
    final data = await scanningController.initialize();
    if (data) {
      await scanningController.setBarcodeFormat(widget.barcodeFormats);
      if (widget.onDataChanged != null) {
        (controller as FlMlKitScanningController).onDataChanged =
            widget.onDataChanged;
      }
      final options = await scanningController.startPreview(camera,
          resolution: widget.resolution, frequency: widget.frequency);
      if (options != null && mounted) {
        if (widget.autoScanning) scanningController.startScan();
        setState(() {});
      }
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
