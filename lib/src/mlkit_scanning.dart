part of '../fl_mlkit_scanning.dart';

typedef EventBarcodeListen = void Function(List<BarcodeModel> barcodes);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormat>? barcodeFormats,
    this.onListen,
    this.overlay,
    this.uninitialized,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qr_code],
        super(key: key);

  /// 码识别回调
  final EventBarcodeListen? onListen;

  /// 码识别类型
  final List<BarcodeFormat> barcodeFormats;

  /// 显示在预览框上面
  final Widget? overlay;

  /// 相机在未初始化时显示的布局
  final Widget? uninitialized;

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    currentChannel = _flMlKitScanningChannel;
    uninitialized = widget.uninitialized;
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((Duration time) => init());
  }

  Future<void> init() async {
    /// 添加消息回调
    await initEvent(eventListen);

    /// 设置识别类型
    await setBarcodeFormat();

    /// 初始化相机
    if (await initCamera()) setState(() {});
  }

  Future<void> setBarcodeFormat() => FlMLKitScanningMethodCall.instance
      .setBarcodeFormat(widget.barcodeFormats);

  void eventListen(dynamic data) {
    if (widget.onListen != null) {
      final List<BarcodeModel> barcodes =
          getBarcodeModelList((data as List<dynamic>?) ?? <BarcodeModel>[]);
      widget.onListen!(barcodes);
    }
  }

  @override
  void didUpdateWidget(covariant FlMlKitScanning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.barcodeFormats != widget.barcodeFormats ||
        oldWidget.onListen != widget.onListen) {
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
}
