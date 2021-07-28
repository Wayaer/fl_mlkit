import 'dart:io';

import 'package:camera/camera.dart';
import 'package:example/main.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScanPage extends StatefulWidget {
  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? controller;
  int time = 0;
  bool hasImageStream = false;
  FLCameraEvent? event;
  int currentTime = 0;

  @override
  void initState() {
    super.initState();
    initEvent();
    addPostFrameCallback((Duration duration) {
      initCamera();
    });
  }

  Future<void> initEvent() async {
    event = FLCameraEvent.instance;
    final bool state = await event!.initialize();
    if (!state) return;
    event!.addListener((dynamic value) {
      log('收到了原生发来的消息== $value');
      log(value.runtimeType);
      if (value != null && hasImageStream) {
        // final BarcodeModel scanResult =
        // BarcodeModel.fromJson(value as Map<dynamic, dynamic>);
        // showToast(scanResult.code);
      } else {
        showToast(value.toString());
      }
    });
  }

  Future<void> initCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    CameraDescription? description;
    for (final CameraDescription element in cameras) {
      if (element.lensDirection == CameraLensDirection.back)
        description = element;
    }
    if (description == null) return;
    controller = CameraController(description, ResolutionPreset.high,
        enableAudio: false);
    await controller!.initialize();
    setState(() {});
    time = DateTime.now().millisecondsSinceEpoch;
    startImageStream();
  }

  void startImageStream() {
    hasImageStream = true;
    currentTime = DateTime.now().millisecond;
    controller?.startImageStream((CameraImage image) {
      if ((DateTime.now().millisecond - currentTime) > 400) {
        /// 每500毫秒解析一次
        if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) return;

        if (isAndroid && image.format.group != ImageFormatGroup.yuv420) return;
        // return scanImageYUV(
        //     uint8list: image.planes[0].bytes,
        //     width: image.width,
        //     height: image.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Container();
    if (controller != null) child = CameraPreview(controller!);
    return ExtendedScaffold(
        backgroundColor: Colors.black, body: Center(child: child));
  }

  @override
  void deactivate() {
    event?.dispose();
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
    controller = null;
  }
}

class _FileImageScanPage extends StatefulWidget {
  @override
  _FileImageScanPageState createState() => _FileImageScanPageState();
}

class _FileImageScanPageState extends State<_FileImageScanPage> {
  String? path;
  List<BarcodeModel> list = <BarcodeModel>[];

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBarText('San file image'),
        padding: const EdgeInsets.all(20),
        isScroll: true,
        children: <Widget>[
          ElevatedText(onPressed: () => openGallery(), text: '选择图片'),
          ElevatedText(onPressed: () => scanPath(), text: '识别(使用Path识别)'),
          ElevatedText(onPressed: () => scanByte(), text: '识别(从内存中识别)'),
          ShowText('path', path),
          if (path != null && path!.isNotEmpty)
            Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                child: Image.file(File(path!))),
          const SizedBox(height: 20),
          ShowCode(list)
        ]);
  }

  Future<void> scanPath() async {
    if (path == null || path!.isEmpty) return showToast('请选择图片');
    if (await getPermission(Permission.storage)) {
      final List<BarcodeModel> data =
          await FlMLKitScanningMethodCall.instance.scanImagePath(path!);
      if (data.isNotEmpty) {
        list = data;
        setState(() {});
      }
    }
  }

  Future<void> scanByte() async {
    if (path == null || path!.isEmpty) return showToast('请选择图片');
    if (await getPermission(Permission.storage)) {
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
    final String? data = await openSystemGallery();
    path = data;
    setState(() {});
  }
}
