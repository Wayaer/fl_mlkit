part of '../fl_camera.dart';

/// 闪光灯状态变化回调。
typedef FlCameraFlashStateChanged = void Function(FlashState state);

/// 相机缩放状态变化回调。
typedef FlCameraCameraZoomStateChanged = void Function(CameraZoomState state);

/// 相机创建完成回调。
typedef FlCameraCreateCallback = void Function(FlCameraController controller);

/// 相机预览组件。
///
/// 负责初始化相机、打开默认（或指定）摄像头并渲染预览画面，
/// 同时把闪光灯、缩放等状态通过回调抛出。
///
/// ```dart
/// FlCamera(
///   resolution: CameraResolution.high,
///   overlay: const ScannerBox(scannerSize: Size(260, 260)),
///   onFlashChanged: (state) => debugPrint('$state'),
/// )
/// ```
class FlCamera extends StatefulWidget {
  /// 创建相机预览组件。
  const FlCamera({
    super.key,
    this.overlay,
    this.onFlashChanged,
    this.onZoomChanged,
    this.updateReset = false,
    this.camera,
    this.resolution = CameraResolution.high,
    this.fit = BoxFit.fitWidth,
    this.lockPortrait = true,
    this.uninitialized,
  });

  /// 显示在预览画面之上的浮层。
  ///
  /// 常用于 [ScannerBox]、[ScannerLine] 或自定义取景框。
  final Widget? overlay;

  /// 相机未初始化 / 已停止预览时显示的占位 UI。
  final Widget? uninitialized;

  /// 闪光灯变化回调。
  final FlCameraFlashStateChanged? onFlashChanged;

  /// 缩放变化回调。
  final FlCameraCameraZoomStateChanged? onZoomChanged;

  /// 组件更新时是否重新打开相机。
  ///
  /// 当 [camera]、[resolution] 等参数变化时，置为 true 会重新初始化预览。
  final bool updateReset;

  /// 需要预览的相机。
  ///
  /// 为空时自动选择后置摄像头。
  final CameraInfo? camera;

  /// 预览分辨率。
  final CameraResolution resolution;

  /// 预览画面在容器中的填充方式。
  final BoxFit fit;

  /// 相机页面是否锁定竖屏。
  ///
  /// 置为 false 时由宿主自行控制屏幕方向与状态栏样式。
  final bool lockPortrait;

  @override
  FlCameraState<FlCamera> createState() => _FlCameraStateWidget();
}

class _FlCameraStateWidget extends FlCameraState<FlCamera> {
  int _openGeneration = 0;

  @override
  void initState() {
    controller = FlCameraController();
    lockPortrait = widget.lockPortrait;
    super.initState();
    uninitialized = widget.uninitialized;
    controller.onFlashChanged = widget.onFlashChanged;
    controller.onZoomChanged = widget.onZoomChanged;
    controller.onNativeDisposed = _handleNativeDisposed;
    WidgetsBinding.instance.addPostFrameCallback((Duration time) {
      // 页面可能在本帧结束前就被销毁，避免销毁后仍初始化相机导致相机常驻。
      if (mounted) unawaited(_initializeAndOpen());
    });
  }

  /// 原生相机被释放（例如 Activity 重建）后立即重建预览，不依赖生命周期事件。
  void _handleNativeDisposed() {
    if (!mounted || !isOwner) return;
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    // 应用正在退出或进入后台时不再重新打开相机。
    if (state != null && state != AppLifecycleState.resumed) return;
    unawaited(_initializeAndOpen());
  }

  Future<void> _initializeAndOpen() async {
    if (!mounted || !isOwner) return;
    final bool initialized = await controller.initialize();
    if (initialized && mounted && isOwner) await _openCamera();
  }

  /// 打开组件指定（或默认后置）摄像头。
  Future<void> _openCamera() async {
    if (!mounted || !isOwner) return;
    final int generation = ++_openGeneration;
    CameraInfo? camera = widget.camera;
    if (camera == null) {
      final List<CameraInfo>? cameras = controller.cameras;
      if (cameras == null || cameras.isEmpty) return;
      for (final CameraInfo cameraInfo in cameras) {
        if (cameraInfo.lensFacing == CameraLensFacing.back) {
          camera = cameraInfo;
          break;
        }
      }
      camera ??= cameras.first;
    }
    // 先停止旧预览：原生会在启动新预览时释放旧纹理，直接覆盖会让 Flutter 引用已失效的纹理。
    await controller.stopPreview();
    if (!mounted || !isOwner || generation != _openGeneration) return;
    final FlCameraOptions? options = await controller.startPreview(camera, resolution: widget.resolution);
    if (options != null && mounted && isOwner && generation == _openGeneration) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 权限被拒绝后用户在系统设置中授权，回到前台时补一次初始化与预览。
    if (state == AppLifecycleState.resumed && !controller.isInitialized && mounted && isOwner) {
      unawaited(_initializeAndOpen());
    }
  }

  @override
  void didUpdateWidget(covariant FlCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.onFlashChanged = widget.onFlashChanged;
    controller.onZoomChanged = widget.onZoomChanged;
    uninitialized = widget.uninitialized;
    if (oldWidget.lockPortrait != widget.lockPortrait) {
      lockPortrait = widget.lockPortrait;
      controller.followDeviceOrientation = !lockPortrait;
    }
    final bool cameraChanged = oldWidget.camera != widget.camera || oldWidget.resolution != widget.resolution;
    if (cameraChanged && widget.updateReset) {
      unawaited(_openCamera());
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    boxFit = widget.fit;
    Widget camera = super.build(context);
    if (widget.overlay != null) {
      camera = Stack(
        children: <Widget>[
          camera,
          SizedBox.expand(child: widget.overlay),
        ],
      );
    }
    return camera;
  }
}

/// 相机预览状态基类。
///
/// 统一处理生命周期、预览纹理渲染以及 [uninitialized] 占位，
/// 扫码、文字识别等插件可复用该状态类。
abstract class FlCameraState<T extends StatefulWidget> extends State<T> with WidgetsBindingObserver {
  /// 相机控制器。
  late CameraController controller;

  /// 相机未初始化 / 已停止预览时显示的占位 UI。
  Widget? uninitialized;

  /// 预览画面的填充方式。
  BoxFit? boxFit;

  /// 相机页面是否锁定竖屏，由子类在 [initState] 中设置。
  bool lockPortrait = true;

  /// 进入后台前是否正在预览；用于恢复时只重启原本在预览的相机。
  bool _resumePreview = false;

  /// 控制器占用标识，由 [initState] 申请。
  int? _owner;

  /// 当前组件是否仍是 [controller] 的使用方。
  ///
  /// 页面退出存在过渡动画，新页面可能在本页面销毁前就接管了控制器；
  /// 此时本页面不应再初始化 / 打开相机。
  @protected
  bool get isOwner => _owner != null && controller.isOwner(_owner!);

  @override
  void initState() {
    super.initState();
    _owner = controller.takeOwner();
    boxFit ??= BoxFit.fitWidth;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      if (!mounted || !lockPortrait) return;
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 仅当宿主自行控制屏幕方向时，iOS 预览才跟随设备方向旋转。
    controller.followDeviceOrientation = !lockPortrait;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      if (!_resumePreview) return;
      _resumePreview = false;
      unawaited(controller.resetCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _resumePreview = _resumePreview || controller.cameraOptions.value != null;
      unawaited(controller.stopPreview());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FlCameraOptions?>(
      valueListenable: controller.cameraOptions,
      builder: (BuildContext context, FlCameraOptions? options, Widget? child) {
        Widget current;
        if (options != null && options.textureId != null && options.width != null && options.height != null) {
          current = ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: boxFit ?? BoxFit.fitWidth,
              child: SizedBox.fromSize(
                size: Size(options.width!, options.height!),
                child: Texture(textureId: options.textureId!),
              ),
            ),
          );
        } else {
          current = uninitialized ?? const SizedBox();
        }
        return SizedBox.expand(child: current);
      },
    );
  }

  /// 释放控制器占用并清理通用回调。
  ///
  /// 只有仍是最新的使用方时才会真正释放相机，返回是否执行了释放；
  /// 退出动画期间新页面可能已经接管控制器，此时旧页面不应再释放相机。
  @protected
  bool releaseController() {
    final int? owner = _owner;
    _owner = null;
    if (owner == null || !controller.releaseOwner(owner)) return false;
    controller.onFlashChanged = null;
    controller.onZoomChanged = null;
    controller.onNativeDisposed = null;
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 这里只能恢复为「允许所有方向」，宿主若有自定义方向锁需在退出后自行重新设置。
    if (lockPortrait) unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    releaseController();
    super.dispose();
  }
}
