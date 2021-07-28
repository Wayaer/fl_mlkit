import 'package:fl_camera/fl_camera.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

typedef EventBarcodeListen = void Function(List<BarcodeModel> barcodes);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormat>? barcodeFormats,
    this.onListen,
    this.overlay,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qr_code],
        super(key: key);

  /// 码识别回调
  final EventBarcodeListen? onListen;

  /// 码识别类型
  final List<BarcodeFormat> barcodeFormats;

  /// 显示在预览框上面
  final Widget? overlay;

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    channel = flMlKitScanningChannel;
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((Duration time) => init());
  }

  Future<void> init() async {
    await initEvent(eventListen);
    await setBarcodeFormat();
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
      cameraMethodCall.disposeCamera().then((bool value) {
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
