import 'dart:io';

import 'package:example/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageScanningPage extends StatefulWidget {
  const ImageScanningPage({Key? key}) : super(key: key);

  @override
  State<ImageScanningPage> createState() => _ImageScanningPageState();
}

class _ImageScanningPageState extends State<ImageScanningPage> {
  String? path;
  List<Barcode>? list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarText('San file image'),
        body: Universal(isScroll: true, width: double.infinity, children: [
          ElevatedText(onPressed: openGallery, text: 'Select Picture'),
          ElevatedText(onPressed: scanByte, text: 'Scanning'),
          TextBox('path', path),
          if (path != null && path!.isNotEmpty)
            Container(
                width: double.infinity,
                height: 300,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                child: Image.file(File(path!))),
          if (list != null && list!.isEmpty)
            const TextBox('Unrecognized', 'Unrecognized'),
          CodeBox(list ?? [], expanded: false)
        ]));
  }

  Future<void> scanByte() async {
    if (path == null || path!.isEmpty) {
      showToast('Please select a picture');
      return;
    }
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (isIOS) hasPermission = true;
    if (hasPermission) {
      final File file = File(path!);
      final call = FlMlKitScanningController();
      await call.setBarcodeFormat([BarcodeFormat.all]);
      final AnalysisImageModel? data =
          await call.scanningImageByte(file.readAsBytesSync());
      if (data != null && data.barcodes != null && data.barcodes!.isNotEmpty) {
        list = data.barcodes;
        setState(() {});
      } else {
        showToast('no data');
      }
    }
  }

  Future<void> openGallery() async {
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (isIOS) hasPermission = true;
    if (!hasPermission) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    path = result.files.first.path;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    FlMlKitScanningController().dispose();
  }
}
