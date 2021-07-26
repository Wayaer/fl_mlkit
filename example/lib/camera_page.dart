import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({Key? key, this.barcodeFormats}) : super(key: key);
  final List<BarcodeFormat>? barcodeFormats;

  @override
  Widget build(BuildContext context) {
    bool backState = true;

    return ExtendedScaffold(
        body: Stack(children: <Widget>[
      FlMlKitScanning(
        barcodeFormats: barcodeFormats,
        onListen: (List<BarcodeModel> barcodes) {
          if (backState && barcodes.isNotEmpty) {
            backState = false;
            pop(barcodes);
          }
        },
      ),
    ]));
  }
}
