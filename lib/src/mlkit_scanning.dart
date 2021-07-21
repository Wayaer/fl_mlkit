import 'package:fl_camera/fl_camera.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormats>? barcodeFormats,
    this.onListen,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormats>[BarcodeFormats.qrCode],
        super(key: key);
  final EventListen? onListen;
  final List<BarcodeFormats> barcodeFormats;

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    channel = flMlKitScanningChannel;
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((Duration time) async {
      await initEvent(eventListen);
      await setBarcodeFormats();
      if (await initCamera()) setState(() {});
    });
  }

  Future<void> setBarcodeFormats() async {
    await FlMLKitScanningMethodCall.instance
        .setBarcodeFormats(widget.barcodeFormats);
  }

  void eventListen(dynamic data) {
    if (widget.onListen != null) widget.onListen!(data);
  }

  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }
}
