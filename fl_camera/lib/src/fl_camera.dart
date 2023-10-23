part of '../fl_camera.dart';

typedef FlCameraCreateCallback = void Function(FlCameraController controller);

typedef FlCameraFlashStateChanged = void Function(FlashState state);

typedef FlCameraCameraZoomStateChanged = void Function(CameraZoomState state);

class FlCamera extends StatefulWidget {
  const FlCamera(
      {super.key,
      this.overlay,
      this.onFlashChanged,
      this.onZoomChanged,
      this.updateReset = false,
      this.camera,
      this.resolution = CameraResolution.high,
      this.fit = BoxFit.fitWidth,
      this.uninitialized});

  /// 显示在预览框上面
  /// Display above preview box
  final Widget? overlay;

  /// 未显示相机时显示的UI
  /// The UI displayed when the camera is not uninitialized
  final Widget? uninitialized;

  /// 闪光灯变化
  /// Flash change
  final FlCameraFlashStateChanged? onFlashChanged;

  /// 缩放变化
  /// zoom ratio
  final FlCameraCameraZoomStateChanged? onZoomChanged;

  /// 更新组件时是否重置相机
  /// Reset camera when updating components
  final bool updateReset;

  /// 需要预览的相机
  /// Camera ID to preview
  final CameraInfo? camera;

  /// 预览相机支持的分辨率
  /// Preview the resolution supported by the camera
  final CameraResolution resolution;

  /// How a camera box should be inscribed into another box.
  final BoxFit fit;

  @override
  FlCameraState<FlCamera> createState() => _FlCameraStateWidget();
}

class _FlCameraStateWidget extends FlCameraState<FlCamera> {
  @override
  void initState() {
    controller = FlCameraController();
    super.initState();
    uninitialized = widget.uninitialized;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initialize();
      initialize();
    });
    controller.onFlashChanged = widget.onFlashChanged;
    controller.onZoomChanged = widget.onZoomChanged;
  }

  Future<void> initialize() async {
    var camera = widget.camera;
    if (camera == null) {
      final List<CameraInfo>? cameras = controller.cameras;
      if (cameras == null) return;
      for (final CameraInfo cameraInfo in cameras) {
        if (cameraInfo.lensFacing == CameraLensFacing.back) {
          camera = cameraInfo;
          break;
        }
      }
    }
    if (camera == null) return;
    final options =
        await controller.startPreview(camera, resolution: widget.resolution);
    if (options != null && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FlCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay != widget.overlay ||
        oldWidget.onFlashChanged != widget.onFlashChanged ||
        oldWidget.onZoomChanged != widget.onZoomChanged ||
        oldWidget.uninitialized != widget.uninitialized) {
      if (widget.updateReset) controller.resetCamera();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    boxFit = widget.fit;
    Widget camera = super.build(context);
    if (widget.overlay != null) {
      camera = Stack(children: <Widget>[
        camera,
        SizedBox.expand(child: widget.overlay),
      ]);
    }
    return camera;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}

abstract class FlCameraState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  late CameraController controller;

  /// 相机未显示时显示的UI
  /// The UI displayed when the camera is not uninitialized
  Widget? uninitialized;
  BoxFit? boxFit;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.resetCamera();
    } else {
      controller.stopPreview();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      await SystemChrome.setPreferredOrientations(
          <DeviceOrientation>[DeviceOrientation.portraitUp]);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: controller.cameraOptions,
        builder: (_, FlCameraOptions? options, __) {
          late Widget current;
          if (options != null && options.textureId != null) {
            current = ColoredBox(
                color: Colors.black,
                child: FittedBox(
                    fit: boxFit!,
                    child: SizedBox.fromSize(
                        size: Size(options.width!, options.height!),
                        child: Texture(textureId: options.textureId!))));
          } else {
            current = uninitialized ?? const SizedBox();
          }
          return SizedBox.expand(child: current);
        });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
