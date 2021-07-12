import 'package:fl_camera/fl_camera.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

class FlMlKitScanning extends StatefulWidget {
  const FlMlKitScanning({Key? key}) : super(key: key);

  @override
  _FlMlKitScanningState createState() => _FlMlKitScanningState();
}

class _FlMlKitScanningState extends FlCameraState<FlMlKitScanning> {
  @override
  void initState() {
    channel = flMlKitScanningChannel;
    super.initState();
    initEvent();
  }

  Future<void> initEvent() async {
    if (await cameraEven.initialize()) {
      cameraEven.addListener((dynamic data) {
        print('收到原生发送来的消息$data');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }
}
