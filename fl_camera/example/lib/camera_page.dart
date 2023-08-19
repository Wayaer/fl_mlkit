import 'package:example/main.dart';
import 'package:fl_camera/fl_camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  ///  The first rendering is null ，Using the rear camera
  CameraInfo? currentCamera;
  bool isBackCamera = true;

  ValueNotifier<FlCameraController?> controller =
      ValueNotifier<FlCameraController?>(null);

  ValueNotifier<bool> hasPreview = ValueNotifier<bool>(false);
  ValueNotifier<bool> flashState = ValueNotifier<bool>(false);

  double maxRatio = 10;
  ValueNotifier<double> ratio = ValueNotifier<double>(1);

  void listener() {
    if (mounted && hasPreview.value != controller.value!.hasPreview) {
      hasPreview.value = controller.value!.hasPreview;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: <Widget>[
      FlCamera(
          onCreateView: (FlCameraController controller) {
            this.controller.value = controller;
            this.controller.value!.addListener(listener);
          },
          uninitialized: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Text('Camera uninitialized',
                  style: TextStyle(color: Colors.white))),
          fit: BoxFit.fitWidth,
          onFlashChanged: (FlashState state) {
            showToast('flash state:$state');
            flashState.value = state == FlashState.on;
          },
          onZoomChanged: (CameraZoomState zoomState) {
            showToast('zoom ratio:${zoomState.zoomRatio}');
            maxRatio = zoomState.maxZoomRatio ?? 10;
            ratio.value = zoomState.zoomRatio ?? 1;
          },
          overlay: Universal(
              alignment: Alignment.bottomCenter,
              mainAxisSize: MainAxisSize.min,
              children: [buildRatioSlider, buildFlashState])),
      Positioned(
          right: 12,
          left: 12,
          top: context.statusBarHeight + 12,
          child: ValueListenableBuilder<FlCameraController?>(
              valueListenable: controller,
              builder: (_, FlCameraController? flCameraController, __) {
                return flCameraController == null
                    ? const SizedBox()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                            const BackButton(
                                color: Colors.white, onPressed: pop),
                            Row(children: [
                              ElevatedIcon(
                                  icon: Icons.flip_camera_ios,
                                  onPressed: switchCamera),
                              const SizedBox(width: 12),
                              ElevatedText(
                                  text: 'reset',
                                  onPressed: () =>
                                      controller.value?.resetCamera()),
                              const SizedBox(width: 12),
                              previewButton(flCameraController),
                            ])
                          ]);
              })),
    ]));
  }

  Widget get buildFlashState {
    return ValueListenableBuilder(
        valueListenable: flashState,
        builder: (_, bool state, __) {
          return IconBox(
              size: 30,
              color: state ? Colors.white : Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 40),
              icon: state ? Icons.flash_on : Icons.flash_off,
              onTap: () {
                controller.value
                    ?.setFlashMode(state ? FlashState.off : FlashState.on);
              });
        });
  }

  Widget get buildRatioSlider {
    return ValueListenableBuilder(
        valueListenable: ratio,
        builder: (_, double ratio, __) {
          return CupertinoSlider(
              value: ratio.floorToDouble(),
              min: 1,
              max: maxRatio,
              divisions: maxRatio.toInt(),
              onChanged: (double value) {
                controller.value?.setZoomRatio(value.floorToDouble());
              });
        });
  }

  Widget previewButton(FlCameraController flCameraController) {
    return ValueListenableBuilder(
        valueListenable: hasPreview,
        builder: (_, bool hasPreview, __) {
          return ElevatedText(
              text: !hasPreview ? 'start' : 'stop',
              onPressed: () async {
                if (!hasPreview) {
                  if (flCameraController.previousCamera != null) {
                    await flCameraController
                        .startPreview(flCameraController.previousCamera!);
                  }
                } else {
                  await flCameraController.stopPreview();
                }
              });
        });
  }

  Future<void> switchCamera() async {
    if (controller.value == null) return;
    for (final CameraInfo cameraInfo in controller.value!.cameras!) {
      if (cameraInfo.lensFacing ==
          (isBackCamera ? CameraLensFacing.front : CameraLensFacing.back)) {
        currentCamera = cameraInfo;
        break;
      }
    }
    await controller.value!.switchCamera(currentCamera!);
    isBackCamera = !isBackCamera;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    hasPreview.dispose();
    ratio.dispose();
    flashState.dispose();
  }
}

class ScannerBoxPage extends StatelessWidget {
  const ScannerBoxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: FlCamera(
            overlay: ScannerBox(
                borderColor: Colors.blue,
                scannerColor: Colors.blue,
                scannerSize: Size(300, 300),
                scannerStrokeWidth: 2)));
  }
}

class ScannerLinePage extends StatelessWidget {
  const ScannerLinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: FlCamera(overlay: ScannerLine(color: Colors.blue)));
  }
}
