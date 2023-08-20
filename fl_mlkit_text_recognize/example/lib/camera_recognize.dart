import 'package:camera/camera.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_waya/flutter_waya.dart';

class CameraRecognizePage extends StatefulWidget {
  const CameraRecognizePage({Key? key}) : super(key: key);

  @override
  State<CameraRecognizePage> createState() => _CameraRecognizePageState();
}

class _CameraRecognizePageState extends State<CameraRecognizePage> {
  CameraController? controller;
  int time = 0;
  bool hasImageStream = false;
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
    final bool state = await FlEvent().initialize();
    if (!state) return;
    FlEvent().addListener((dynamic value) {
      log('Received a message from native== $value');
      if (value != null && hasImageStream) {
        // final Barcode scanResult =
        // Barcode.fromJson(value as Map<dynamic, dynamic>);
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
      if (element.lensDirection == CameraLensDirection.back) {
        description = element;
      }
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
        /// Parse every 500 milliseconds
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
    return Scaffold(backgroundColor: Colors.black, body: Center(child: child));
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
    controller = null;
  }
}
