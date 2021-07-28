import 'dart:io';

import 'package:example/main.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageScanPage extends StatefulWidget {
  @override
  _ImageScanPageState createState() => _ImageScanPageState();
}

class _ImageScanPageState extends State<ImageScanPage> {
  String? path;
  List<BarcodeModel>? list;

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBarText('San file image'),
        padding: const EdgeInsets.all(20),
        isScroll: true,
        children: <Widget>[
          ElevatedText(onPressed: openGallery, text: '选择图片'),
          ElevatedText(onPressed: scanByte, text: '识别'),
          ShowText('path', path),
          if (path != null && path!.isNotEmpty)
            Container(
                width: double.infinity,
                height: 300,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                child: Image.file(File(path!))),
          const SizedBox(height: 20),
          if (list != null && list!.isEmpty) const ShowText('未识别', '未识别'),
          ShowCode(list ?? <BarcodeModel>[], expanded: false)
        ]);
  }

  Future<void> scanByte() async {
    if (path == null || path!.isEmpty) return showToast('请选择图片');
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (isIOS) hasPermission = true;
    if (hasPermission) {
      final File file = File(path!);
      final List<BarcodeModel> data = await FlMLKitScanningMethodCall.instance
          .scanImageByte(file.readAsBytesSync());
      if (data.isNotEmpty) {
        list = data;
        setState(() {});
      }
    }
  }

  Future<void> openGallery() async {
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (isIOS) hasPermission = true;
    if (hasPermission) {
      final String? data = await openSystemGallery();
      path = data;
      setState(() {});
    }
  }
}
