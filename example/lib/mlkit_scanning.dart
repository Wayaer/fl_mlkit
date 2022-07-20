import 'package:example/main.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class FlMlKitScanningPage extends StatefulWidget {
  const FlMlKitScanningPage({Key? key}) : super(key: key);

  @override
  State<FlMlKitScanningPage> createState() => _FlMlKitScanningPageState();
}

class _FlMlKitScanningPageState extends State<FlMlKitScanningPage>
    with TickerProviderStateMixin {
  List<String> types = BarcodeFormat.values.builder((item) => item.toString());

  late AnimationController animationController;
  AnalysisImageModel? model;
  ValueNotifier<bool> flashState = ValueNotifier<bool>(false);
  double maxRatio = 10;
  ValueNotifier<double> ratio = ValueNotifier<double>(1);

  ValueNotifier<FlMlKitScanningController?> scanningController =
      ValueNotifier<FlMlKitScanningController?>(null);

  ///  The first rendering is null ，Using the rear camera
  CameraInfo? currentCamera;

  bool isBackCamera = true;

  ValueNotifier<bool> hasPreview = ValueNotifier<bool>(false);

  ValueNotifier<bool> canScan = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this);
  }

  void listener() {
    if (!mounted) return;
    if (hasPreview.value != scanningController.value!.hasPreview) {
      hasPreview.value = scanningController.value!.hasPreview;
    }
    if (canScan.value != scanningController.value!.canScan) {
      canScan.value = scanningController.value!.canScan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        onWillPop: () async {
          return false;
        },
        body: Stack(children: <Widget>[
          FlMlKitScanning(
              frequency: 800,
              camera: currentCamera,
              onCreateView: (FlMlKitScanningController controller) {
                scanningController.value = controller;
                scanningController.value!.addListener(listener);
              },
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
              children: <Widget>[buildRatioSlider, buildFlashState]),
          Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                  width: 150,
                  height: 300,
                  child: ListStateWheel(
                      initialItem: 1,
                      options: WheelOptions(
                          useMagnifier: true,
                          magnification: 1.5,
                          onChanged: (int index) {
                            var format = BarcodeFormat.values[index];
                            scanningController.value
                                ?.setBarcodeFormat([format]).then((value) {
                              animationReset();
                              showToast('setBarcodeFormat:$format $value');
                            });
                          }),
                      childDelegateType: ListWheelChildDelegateType.builder,
                      itemBuilder: (_, int index) => Align(
                          alignment: Alignment.center,
                          child: BText(types[index].split('.')[1],
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      itemCount: types.length))),
          Positioned(
              right: 12,
              left: 12,
              top: getStatusBarHeight + 12,
              child: ValueListenableBuilder<FlMlKitScanningController?>(
                  valueListenable: scanningController,
                  builder: (_, FlMlKitScanningController? controller, __) {
                    return controller == null
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
                                  previewButton(controller),
                                  const SizedBox(width: 12),
                                  canScanButton(controller),
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
                scanningController.value
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
                scanningController.value?.setZoomRatio(value.floorToDouble());
              });
        });
  }

  Widget canScanButton(FlMlKitScanningController scanningController) {
    return ValueListenableBuilder(
        valueListenable: canScan,
        builder: (_, bool value, __) {
          return ElevatedText(
              text: value ? 'pause' : 'start',
              onPressed: () async {
                value
                    ? await scanningController.pauseScan()
                    : await scanningController.startScan();
                animationReset();
              });
        });
  }

  void animationReset() {
    model = null;
    animationController.reset();
  }

  Widget previewButton(FlMlKitScanningController scanningController) {
    return ValueListenableBuilder(
        valueListenable: hasPreview,
        builder: (_, bool hasPreview, __) {
          return ElevatedText(
              text: !hasPreview ? 'start' : 'stop',
              onPressed: () async {
                if (!hasPreview) {
                  if (scanningController.previousCamera != null) {
                    await scanningController
                        .startPreview(scanningController.previousCamera!);
                  }
                } else {
                  await scanningController.stopPreview();
                }
              });
        });
  }

  Future<void> switchCamera() async {
    if (scanningController.value == null) return;
    for (final CameraInfo cameraInfo in scanningController.value!.cameras!) {
      if (cameraInfo.lensFacing ==
          (isBackCamera ? CameraLensFacing.front : CameraLensFacing.back)) {
        currentCamera = cameraInfo;
        break;
      }
    }
    await scanningController.value!.switchCamera(currentCamera!);
    isBackCamera = !isBackCamera;
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    scanningController.dispose();
    hasPreview.dispose();
    canScan.dispose();
    ratio.dispose();
    flashState.dispose();
  }
}

class _RectBox extends StatelessWidget {
  const _RectBox(this.model, {Key? key}) : super(key: key);
  final AnalysisImageModel model;

  @override
  Widget build(BuildContext context) {
    final List<Barcode> barcodes = model.barcodes ?? <Barcode>[];
    final List<Widget> children = <Widget>[];
    for (final Barcode barcode in barcodes) {
      children.add(boundingBox(barcode.boundingBox!));
      children.add(corners(barcode.corners!));
    }
    return Universal(expand: true, isStack: true, children: children);
  }

  Widget boundingBox(Rect rect) {
    final double w = model.width! / getDevicePixelRatio;
    final double h = model.height! / getDevicePixelRatio;
    return Universal(
        alignment: Alignment.center,
        child: CustomPaint(size: Size(w, h), painter: _LinePainter(rect)));
  }

  Widget corners(List<Offset> corners) {
    final double w = model.width! / getDevicePixelRatio;
    final double h = model.height! / getDevicePixelRatio;
    return Universal(
        alignment: Alignment.center,
        child: CustomPaint(size: Size(w, h), painter: _BoxPainter(corners)));
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Path path = Path();
    final double left = (rect.left) / getDevicePixelRatio;
    final double top = (rect.top) / getDevicePixelRatio;

    final double width = rect.width / getDevicePixelRatio;
    final double height = rect.height / getDevicePixelRatio;

    path.moveTo(left, top);
    path.lineTo(left + width, top);
    path.lineTo(left + width, height + top);
    path.lineTo(left, height + top);
    path.lineTo(left, top);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.corners);

  final List<Offset> corners;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset o0 = Offset(corners[0].dx / getDevicePixelRatio,
        corners[0].dy / getDevicePixelRatio);
    final Offset o1 = Offset(corners[1].dx / getDevicePixelRatio,
        corners[1].dy / getDevicePixelRatio);
    final Offset o2 = Offset(corners[2].dx / getDevicePixelRatio,
        corners[2].dy / getDevicePixelRatio);
    final Offset o3 = Offset(corners[3].dx / getDevicePixelRatio,
        corners[3].dy / getDevicePixelRatio);

    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2;
    final Path path = Path();
    path.moveTo(o0.dx, o0.dy);
    path.lineTo(o1.dx, o1.dy);
    path.lineTo(o2.dx, o2.dy);
    path.lineTo(o3.dx, o3.dy);
    path.lineTo(o0.dx, o0.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
