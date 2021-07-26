import 'package:fl_camera/fl_camera.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

typedef EventBarcodeListen = void Function(List<BarcodeModel> barcodes);

class FlMlKitScanning extends StatefulWidget {
  FlMlKitScanning({
    Key? key,
    List<BarcodeFormat>? barcodeFormats,
    this.onListen,
  })  : barcodeFormats =
            barcodeFormats ?? <BarcodeFormat>[BarcodeFormat.qr_code],
        super(key: key);
  final EventBarcodeListen? onListen;
  final List<BarcodeFormat> barcodeFormats;

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
      await setBarcodeFormat();
      if (await initCamera()) setState(() {});
    });
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
  Widget build(BuildContext context) {
    return super.build(context);
  }
}
