part of '../fl_mlkit_scanning.dart';

typedef EventBarcodeListen = void Function(AnalysisImageModel data);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormat>? barcodeFormats,
    this.onListen,
    this.overlay,
    this.uninitialized,
    this.onFlashChange,
    this.autoScanning = true,
    this.onZoomChange,
    this.updateReset = false,
    this.camera,
    this.resolution = CameraResolution.high,
    this.fit = BoxFit.fitWidth,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qr_code],
        super(key: key);

  /// 码识别回调
  /// Identify callback
  final EventBarcodeListen? onListen;

  /// 码识别类型
  /// Identification type
  final List<BarcodeFormat> barcodeFormats;

  /// 显示在预览框上面
  /// Display above preview box
  final Widget? overlay;

  /// 相机在未初始化时显示的UI
  /// The UI displayed when the camera is not initialized
  final Widget? uninitialized;

  /// Flash change
  final ValueChanged<FlashState>? onFlashChange;

  /// 缩放变化
  /// zoom ratio
  final ValueChanged<CameraZoomState>? onZoomChange;

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

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    currentChannel = _flMlKitScanningChannel;
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((Duration time) => init());
  }

  Future<void> init() async {
    boxFit = widget.fit;
    uninitialized = widget.uninitialized;

    /// Add message callback
    await initEvent(eventListen);

    /// Set identification type
    await FlMlKitScanningMethodCall().setBarcodeFormat(widget.barcodeFormats);

    /// Initialize camera
    initCamera(camera: widget.camera, resolution: widget.resolution)
        .then((bool value) {
      if (!value) return;
      setState(() {});

      /// Start scan
      if (widget.autoScanning) FlMlKitScanningMethodCall().start();
    });
  }

  void eventListen(dynamic data) {
    if (widget.onListen != null) {
      if (data is Map) {
        widget.onListen!(AnalysisImageModel.fromMap(data));
      }
    }
  }

  @override
  void onZoomChange(CameraZoomState state) {
    super.onZoomChange(state);
    if (widget.onZoomChange != null) widget.onZoomChange!(state);
  }

  @override
  void onFlashChange(FlashState state) {
    super.onFlashChange(state);
    if (widget.onFlashChange != null) widget.onFlashChange!(state);
  }

  @override
  void didUpdateWidget(covariant FlMlKitScanning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChange != widget.onFlashChange ||
        oldWidget.onZoomChange != widget.onZoomChange ||
        oldWidget.camera != widget.camera ||
        oldWidget.resolution != widget.resolution ||
        oldWidget.uninitialized != widget.uninitialized ||
        oldWidget.barcodeFormats != widget.barcodeFormats ||
        oldWidget.autoScanning != widget.autoScanning ||
        oldWidget.fit != widget.fit ||
        oldWidget.onListen != widget.onListen) {
      if (widget.updateReset)
        cameraMethodCall.dispose().then((bool value) {
          if (value) init();
        });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      init();
    } else {
      super.didChangeAppLifecycleState(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget camera = super.build(context);
    if (widget.overlay != null)
      camera = Stack(children: <Widget>[
        camera,
        SizedBox.expand(child: widget.overlay),
      ]);
    return camera;
  }

  @override
  void dispose() {
    super.dispose();
    FlMlKitScanningMethodCall().pause();
  }
}
