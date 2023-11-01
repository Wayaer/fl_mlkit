import 'package:example/main.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class FlMlKitScanningPage extends StatefulWidget {
  const FlMlKitScanningPage({super.key});

  @override
  State<FlMlKitScanningPage> createState() => _FlMlKitScanningPageState();
}

class _FlMlKitScanningPageState extends State<FlMlKitScanningPage>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  AnalysisImageModel? model;
  ValueNotifier<bool> flashState = ValueNotifier<bool>(false);
  double maxRatio = 10;
  ValueNotifier<double> ratio = ValueNotifier<double>(1);

  ///  The first rendering is null ，Using the rear camera
  CameraInfo? currentCamera;

  bool isBackCamera = true;

  ValueNotifier<bool> canScanning = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          body: Stack(children: <Widget>[
        FlMlKitScanning(
            frequency: 800,
            camera: currentCamera,
            // overlay: const ScannerBox(),
            onFlashChanged: (FlashState state) {
              showToast('$state');
              flashState.value = state == FlashState.on;
            },
            onZoomChanged: (CameraZoomState zoom) {
              showToast('zoom ratio:${zoom.zoomRatio}');
              maxRatio = zoom.maxZoomRatio ?? 10;
              ratio.value = zoom.zoomRatio ?? 1;
            },
            resolution: CameraResolution.veryHigh,
            autoScanning: true,
            barcodeFormats: const [BarcodeFormat.all],
            fit: BoxFit.fitWidth,
            uninitialized: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const Text('Camera not initialized',
                    style: TextStyle(color: Colors.blueAccent))),
            onDataChanged: (AnalysisImageModel data) {
              final List<Barcode>? barcodes = data.barcodes;
              if (barcodes != null && barcodes.isNotEmpty) {
                model = data;
                animationController.reset();
              }
            }),
        AnimatedBuilder(
            animation: animationController,
            builder: (_, __) =>
                model != null ? _RectBox(model!) : const SizedBox()),
        Universal(
            alignment: Alignment.bottomCenter,
            mainAxisSize: MainAxisSize.min,
            children: [buildRatioSlider, buildFlashState]),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
              width: 150,
              height: 300,
              child: ListWheelState(
                  initialItem: 1,
                  count: BarcodeFormat.values.length,
                  builder: (FixedExtentScrollController controller) =>
                      ListWheel.builder(
                          controller: controller,
                          onSelectedItemChanged: (int index) {
                            var format = BarcodeFormat.values[index];
                            FlMlKitScanningController()
                                .setBarcodeFormat([format]).then((value) {
                              animationReset();
                              showToast('setBarcodeFormat:$format $value');
                            });
                          },
                          options: const WheelOptions.cupertino(),
                          itemBuilder: (_, int index) => Align(
                              alignment: Alignment.center,
                              child: BText(BarcodeFormat.values[index].name,
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          itemCount: BarcodeFormat.values.length))),
        ),
        Positioned(
            right: 12,
            left: 12,
            top: context.statusBarHeight + 12,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const BackButton(color: Colors.white, onPressed: pop),
                  Row(children: [
                    ElevatedIcon(
                        icon: Icons.flip_camera_ios, onPressed: switchCamera),
                    const SizedBox(width: 12),
                    previewButton,
                    const SizedBox(width: 12),
                    canScanningButton,
                  ])
                ])),
      ])),
    );
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
                FlMlKitScanningController()
                    .setFlashMode(state ? FlashState.off : FlashState.on);
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
                FlMlKitScanningController().setZoomRatio(value.floorToDouble());
              });
        });
  }

  Widget get canScanningButton => ValueListenableBuilder(
      valueListenable: canScanning,
      builder: (_, bool value, __) {
        return ElevatedText(
            text: value ? 'pause' : 'start',
            onPressed: () async {
              value
                  ? await FlMlKitScanningController().pauseScanning()
                  : await FlMlKitScanningController().startScanning();
              canScanning.value = !canScanning.value;
              animationReset();
            });
      });

  void animationReset() {
    model = null;
    animationController.reset();
  }

  Widget get previewButton => ValueListenableBuilder<FlCameraOptions?>(
      valueListenable: FlMlKitScanningController().cameraOptions,
      builder: (_, FlCameraOptions? options, __) {
        return ElevatedText(
            text: options == null ? 'start' : 'stop',
            onPressed: () async {
              if (options == null) {
                if (FlMlKitScanningController().previousCamera != null) {
                  await FlMlKitScanningController().startPreview(
                      FlMlKitScanningController().previousCamera!);
                }
              } else {
                await FlMlKitScanningController().stopPreview();
              }
            });
      });

  Future<void> switchCamera() async {
    for (final CameraInfo cameraInfo in FlMlKitScanningController().cameras!) {
      if (cameraInfo.lensFacing ==
          (isBackCamera ? CameraLensFacing.front : CameraLensFacing.back)) {
        currentCamera = cameraInfo;
        break;
      }
    }
    await FlMlKitScanningController().switchCamera(currentCamera!);
    isBackCamera = !isBackCamera;
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    canScanning.dispose();
    ratio.dispose();
    flashState.dispose();
  }
}

class _RectBox extends StatelessWidget {
  const _RectBox(this.model);

  final AnalysisImageModel model;

  @override
  Widget build(BuildContext context) {
    final List<Barcode> barcodes = model.barcodes ?? <Barcode>[];
    final List<Widget> children = <Widget>[];
    for (final Barcode barcode in barcodes) {
      children.add(boundingBox(barcode.boundingBox!, context));
      children.add(corners(barcode.corners!, context));
    }
    return Universal(expand: true, isStack: true, children: children);
  }

  Widget boundingBox(Rect rect, BuildContext context) {
    final double w = model.width! / context.devicePixelRatio;
    final double h = model.height! / context.devicePixelRatio;
    return Universal(
        alignment: Alignment.center,
        child: CustomPaint(
            size: Size(w, h), painter: _LinePainter(rect, context)));
  }

  Widget corners(List<Offset> corners, BuildContext context) {
    final double w = model.width! / context.devicePixelRatio;
    final double h = model.height! / context.devicePixelRatio;
    return Universal(
        alignment: Alignment.center,
        child: CustomPaint(
            size: Size(w, h), painter: _BoxPainter(corners, context)));
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.rect, this.context);

  final Rect rect;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = Rect.fromLTWH(
        (rect.left) / context.devicePixelRatio,
        (rect.top) / context.devicePixelRatio,
        rect.width / context.devicePixelRatio,
        rect.height / context.devicePixelRatio);
    canvas.drawRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.corners, this.context);

  final List<Offset> corners;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2;

    final offsets = corners
        .map((e) => Offset(
            (e.dx / context.devicePixelRatio), e.dy / context.devicePixelRatio))
        .toList();
    final rect = Rect.fromPoints(offsets[1], offsets[3]);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
