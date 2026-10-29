import 'package:fl_camera/fl_camera.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

/// 相机预览与控制器能力演示。
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

/// 浮层类型。
enum OverlayMode {
  /// 不显示浮层。
  none,

  /// 扫码框浮层。
  box,

  /// 扫描线浮层。
  line,
}

class _CameraPageState extends State<CameraPage> {
  final FlCameraController controller = FlCameraController();

  CameraInfo? camera;
  CameraResolution resolution = CameraResolution.high;
  FlashState flashState = FlashState.off;
  OverlayMode overlayMode = OverlayMode.box;
  double zoom = 1;
  double maxZoom = 1;
  bool showInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          FlCamera(
            camera: camera,
            resolution: resolution,
            updateReset: true,
            fit: BoxFit.cover,
            overlay: _buildOverlay(),
            onFlashChanged: (FlashState state) => setState(() => flashState = state),
            onZoomChanged: (CameraZoomState state) {
              setState(() {
                zoom = state.zoomRatio ?? 1;
                maxZoom = state.maxZoomRatio ?? 1;
              });
            },
            uninitialized: ValueListenableBuilder<FlCameraErrorCode?>(
              valueListenable: controller.errorNotifier,
              builder: (BuildContext context, FlCameraErrorCode? error, Widget? child) {
                if (error != null) {
                  final String message = switch (error) {
                    FlCameraErrorCode.permissionDenied => '未获得相机权限，请在系统设置中开启',
                    FlCameraErrorCode.permissionRequestInterrupted => '权限申请被中断，请重新进入相机',
                    FlCameraErrorCode.platformUnsupported => '当前平台不支持相机',
                    FlCameraErrorCode.notInitialized => '相机未初始化',
                    FlCameraErrorCode.invalidArguments => '相机参数非法',
                    FlCameraErrorCode.cameraNotFound => '未找到可用摄像头',
                    FlCameraErrorCode.cameraInitFailed => '相机初始化失败',
                    FlCameraErrorCode.unknown => '相机初始化失败',
                  };
                  return Center(
                    child: FlText(message, color: Colors.white70, textAlign: TextAlign.center),
                  );
                }
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      FlText('相机未初始化', color: Colors.white70),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: context.statusBarHeight + 8,
            left: 12,
            right: 12,
            child: Row(
              children: <Widget>[
                _CircleButton(icon: Icons.arrow_back, onTap: pop),
                const SizedBox(width: 10),
                const Expanded(
                  child: FlText('相机预览', color: Colors.white, fontSize: 18, textAlign: TextAlign.center),
                ),
                _CircleButton(icon: Icons.flip_camera_ios_outlined, onTap: switchCamera),
                const SizedBox(width: 8),
                _CircleButton(icon: Icons.info_outline, onTap: () => setState(() => showInfo = !showInfo)),
              ],
            ),
          ),
          if (showInfo)
            Positioned(
              top: context.statusBarHeight + 60,
              left: 12,
              right: 12,
              child: _InfoPanel(camera: camera, cameras: controller.cameras, onSelectCamera: selectCamera),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ControlPanel(
              flashState: flashState,
              resolution: resolution,
              overlayMode: overlayMode,
              zoom: zoom,
              maxZoom: maxZoom,
              onFlashChanged: setFlashMode,
              onResolutionChanged: (CameraResolution value) => setState(() => resolution = value),
              onOverlayChanged: (OverlayMode value) => setState(() => overlayMode = value),
              onZoomChanged: (double value) => setState(() => zoom = value),
              onZoomEnd: (double value) => controller.setZoomRatio(value),
              onReset: reset,
              onPreviewToggle: togglePreview,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildOverlay() {
    switch (overlayMode) {
      case OverlayMode.none:
        return null;
      case OverlayMode.box:
        return const ScannerBox(
          scannerSize: Size(260, 260),
          borderColor: Colors.lightBlueAccent,
          scannerColor: Colors.lightBlueAccent,
          hornStrokeWidth: 4,
          hornWidth: 20,
          scannerStrokeWidth: 2,
        );
      case OverlayMode.line:
        return const ScannerLine(color: Colors.lightBlueAccent);
    }
  }

  Future<void> setFlashMode(FlashState state) async {
    final bool ok = await controller.setFlashMode(state);
    if (!ok) showToast('闪光灯设置失败');
  }

  Future<void> switchCamera() async {
    final List<CameraInfo> cameras = controller.cameras ?? <CameraInfo>[];
    if (cameras.length < 2) {
      showToast('当前设备只有一个可用摄像头');
      return;
    }
    final int index = cameras.indexOf(camera ?? cameras.first);
    setState(() => camera = cameras[(index + 1) % cameras.length]);
  }

  void selectCamera(CameraInfo value) {
    setState(() => camera = value);
    showToast('切换到 ${value.lensFacing.name} 摄像头');
  }

  Future<void> reset() async {
    final bool ok = await controller.resetCamera();
    if (!ok) showToast('重置失败，请确认相机已初始化');
  }

  Future<void> togglePreview() async {
    if (controller.cameraOptions.value != null) {
      await controller.stopPreview();
      return;
    }
    final CameraInfo? target =
        camera ??
        controller.previousCamera ??
        (controller.cameras?.isNotEmpty ?? false ? controller.cameras!.first : null);
    if (target == null) {
      showToast('没有可用的摄像头');
      return;
    }
    await controller.startPreview(target, resolution: resolution);
  }
}

/// 圆形图标按钮。
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Universal(
      onTap: onTap,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

/// 相机信息面板。
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.camera, required this.cameras, required this.onSelectCamera});

  final CameraInfo? camera;
  final List<CameraInfo>? cameras;
  final ValueChanged<CameraInfo> onSelectCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FlText('预览配置', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          ValueListenableBuilder<FlCameraOptions?>(
            valueListenable: FlCameraController().cameraOptions,
            builder: (_, FlCameraOptions? options, _) {
              return FlText(
                options == null
                    ? '当前未预览'
                    : 'textureId: ${options.textureId}  '
                          '${options.width?.toStringAsFixed(0)} x ${options.height?.toStringAsFixed(0)}',
                color: Colors.white70,
                fontSize: 12,
              );
            },
          ),
          const SizedBox(height: 8),
          const FlText('可用摄像头', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (cameras ?? <CameraInfo>[])
                .map(
                  (CameraInfo item) => ChoiceChip(
                    label: Text('${item.lensFacing.name} · ${item.name}'),
                    selected: camera == item,
                    onSelected: (_) => onSelectCamera(item),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

/// 底部控制面板。
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.flashState,
    required this.resolution,
    required this.overlayMode,
    required this.zoom,
    required this.maxZoom,
    required this.onFlashChanged,
    required this.onResolutionChanged,
    required this.onOverlayChanged,
    required this.onZoomChanged,
    required this.onZoomEnd,
    required this.onReset,
    required this.onPreviewToggle,
  });

  final FlashState flashState;
  final CameraResolution resolution;
  final OverlayMode overlayMode;
  final double zoom;
  final double maxZoom;
  final ValueChanged<FlashState> onFlashChanged;
  final ValueChanged<CameraResolution> onResolutionChanged;
  final ValueChanged<OverlayMode> onOverlayChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onZoomEnd;
  final VoidCallback onReset;
  final VoidCallback onPreviewToggle;

  @override
  Widget build(BuildContext context) {
    final double sliderMax = maxZoom <= 1 ? 2 : maxZoom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, context.mediaQuery.padding.bottom + 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.zoom_out, color: Colors.white70, size: 18),
              Expanded(
                child: Slider(
                  value: zoom.clamp(1, sliderMax).toDouble(),
                  min: 1,
                  max: sliderMax,
                  divisions: sliderMax <= 1 ? null : (sliderMax * 2).round(),
                  label: '${zoom.toStringAsFixed(1)}x',
                  onChanged: onZoomChanged,
                  onChangeEnd: onZoomEnd,
                ),
              ),
              Icon(Icons.zoom_in, color: Colors.white70, size: 18),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: SegmentedButton<FlashState>(
                  segments: const <ButtonSegment<FlashState>>[
                    ButtonSegment<FlashState>(value: FlashState.off, icon: Icon(Icons.flash_off)),
                    ButtonSegment<FlashState>(value: FlashState.on, icon: Icon(Icons.flash_on)),
                    ButtonSegment<FlashState>(value: FlashState.auto, icon: Icon(Icons.flash_auto)),
                  ],
                  selected: <FlashState>{flashState},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<FlashState> value) => onFlashChanged(value.first),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<CameraResolution>(
                  initialValue: resolution,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '分辨率', isDense: true),
                  items: CameraResolution.values
                      .map(
                        (CameraResolution item) =>
                            DropdownMenuItem<CameraResolution>(value: item, child: Text(item.name)),
                      )
                      .toList(growable: false),
                  onChanged: (CameraResolution? value) {
                    if (value != null) onResolutionChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: SegmentedButton<OverlayMode>(
                  segments: const <ButtonSegment<OverlayMode>>[
                    ButtonSegment<OverlayMode>(value: OverlayMode.none, label: Text('无浮层')),
                    ButtonSegment<OverlayMode>(value: OverlayMode.box, label: Text('扫码框')),
                    ButtonSegment<OverlayMode>(value: OverlayMode.line, label: Text('扫描线')),
                  ],
                  selected: <OverlayMode>{overlayMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<OverlayMode> value) => onOverlayChanged(value.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: ValueListenableBuilder<FlCameraOptions?>(
                  valueListenable: FlCameraController().cameraOptions,
                  builder: (_, FlCameraOptions? options, _) => FilledButton.icon(
                    onPressed: onPreviewToggle,
                    icon: Icon(options == null ? Icons.play_arrow : Icons.pause),
                    label: Text(options == null ? '开始预览' : '停止预览'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: onReset, icon: const Icon(Icons.restart_alt)),
            ],
          ),
        ],
      ),
    );
  }
}
