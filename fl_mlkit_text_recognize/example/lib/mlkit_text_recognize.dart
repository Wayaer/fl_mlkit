import 'package:example/main.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class FlMlKitTextRecognizePage extends StatefulWidget {
  const FlMlKitTextRecognizePage({super.key});

  @override
  State<FlMlKitTextRecognizePage> createState() =>
      _FlMlKitTextRecognizePageState();
}

class _FlMlKitTextRecognizePageState extends State<FlMlKitTextRecognizePage>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  AnalysisTextModel? model;

  ValueNotifier<bool> flashState = ValueNotifier<bool>(false);
  double maxRatio = 10;
  ValueNotifier<double> ratio = ValueNotifier<double>(1);

  ///  The first rendering is null ，Using the rear camera
  CameraInfo? currentCamera;
  bool isBackCamera = true;

  ValueNotifier<bool> canRecognize = ValueNotifier<bool>(true);

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
        FlMlKitTextRecognize(
            recognizedLanguage: RecognizedLanguage.latin,
            frequency: 1000,
            camera: currentCamera,
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
            autoRecognize: true,
            fit: BoxFit.fitWidth,
            uninitialized: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const Text('Camera not initialized',
                    style: TextStyle(color: Colors.blueAccent))),
            onDataChanged: (AnalysisTextModel data) {
              if (data.text != null && data.text!.isNotEmpty) {
                model = data;
                if (mounted) animationController.reset();
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
                child: ListWheel.builder(
                    onSelectedItemChanged: (int index) {
                      FlMlKitTextRecognizeController()
                          .setRecognizedLanguage(
                              RecognizedLanguage.values[index])
                          .then((value) {
                        showToast('setRecognizedLanguage:$value');
                      });
                    },
                    options: const WheelOptions.cupertino(),
                    itemBuilder: (_, int index) => Align(
                        alignment: Alignment.center,
                        child: BText(RecognizedLanguage.values[index].name,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    itemCount: RecognizedLanguage.values.length))),
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
                    recognizeButton,
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
                FlMlKitTextRecognizeController()
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
                FlMlKitTextRecognizeController()
                    .setZoomRatio(value.floorToDouble());
              });
        });
  }

  Widget get recognizeButton => ValueListenableBuilder(
      valueListenable: canRecognize,
      builder: (_, bool value, __) {
        return ElevatedText(
            text: value ? 'pause' : 'start',
            onPressed: () async {
              value
                  ? await FlMlKitTextRecognizeController().pauseRecognize()
                  : await FlMlKitTextRecognizeController().startRecognize();
              canRecognize.value = !canRecognize.value;
              model = null;
              animationController.reset();
            });
      });

  Widget get previewButton => ValueListenableBuilder<FlCameraOptions?>(
      valueListenable: FlMlKitTextRecognizeController().cameraOptions,
      builder: (_, FlCameraOptions? options, __) {
        return ElevatedText(
            text: options == null ? 'start' : 'stop',
            onPressed: () async {
              if (options == null) {
                if (FlMlKitTextRecognizeController().previousCamera != null) {
                  await FlMlKitTextRecognizeController().startPreview(
                      FlMlKitTextRecognizeController().previousCamera!);
                }
              } else {
                await FlMlKitTextRecognizeController().stopPreview();
              }
            });
      });

  Future<void> switchCamera() async {
    for (final CameraInfo cameraInfo
        in FlMlKitTextRecognizeController().cameras!) {
      if (cameraInfo.lensFacing ==
          (isBackCamera ? CameraLensFacing.front : CameraLensFacing.back)) {
        currentCamera = cameraInfo;
        break;
      }
    }
    await FlMlKitTextRecognizeController().switchCamera(currentCamera!);
    isBackCamera = !isBackCamera;
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    canRecognize.dispose();
    ratio.dispose();
    flashState.dispose();
  }
}

class _RectBox extends StatelessWidget {
  const _RectBox(this.model);

  final AnalysisTextModel model;

  @override
  Widget build(BuildContext context) {
    final List<TextBlock> blocks = model.textBlocks ?? <TextBlock>[];
    final List<Widget> children = <Widget>[];
    for (final TextBlock block in blocks) {
      children.add(boundingBox(block.boundingBox!, context));
      children.add(corners(block.corners!, context));
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

    /// 由于android原生的 [corners] 表示不一致，所以区分一下
    final offsets = corners
        .map((e) => isAndroid
            ? Offset((context.width - (e.dy / context.devicePixelRatio)),
                e.dx / context.devicePixelRatio)
            : Offset((e.dx / context.devicePixelRatio),
                e.dy / context.devicePixelRatio))
        .toList();
    final rect = Rect.fromPoints(offsets[1], offsets[3]);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
