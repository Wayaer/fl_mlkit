part of '../fl_mlkit_scanning.dart';

typedef EventBarcodeListen = void Function(List<BarcodeModel> barcodes);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormat>? barcodeFormats,
    this.onListen,
    this.overlay,
    this.uninitialized,
    this.onFlashChange,
    this.isFullScreen = true,
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

  /// 闪光灯变化
  final ValueChanged<FlashState>? onFlashChange;

  /// 是否全屏
  final bool isFullScreen;

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
    fullScreen = widget.isFullScreen;
    uninitialized = widget.uninitialized;

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
  void onFlashChange(FlashState state) {
    super.onFlashChange(state);
    if (widget.onFlashChange != null) widget.onFlashChange!(state);
  }

  @override
  void didUpdateWidget(covariant FlMlKitScanning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChange != widget.onFlashChange ||
        oldWidget.uninitialized != widget.uninitialized ||
        oldWidget.barcodeFormats != widget.barcodeFormats ||
        oldWidget.isFullScreen != widget.isFullScreen ||
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
