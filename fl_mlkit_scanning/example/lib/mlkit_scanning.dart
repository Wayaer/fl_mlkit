import 'package:example/barcode_view.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

/// 相机实时扫码演示。
class FlMlKitScanningPage extends StatefulWidget {
  const FlMlKitScanningPage({super.key});

  @override
  State<FlMlKitScanningPage> createState() => _FlMlKitScanningPageState();
}

class _FlMlKitScanningPageState extends State<FlMlKitScanningPage> {
  final FlMlKitScanningController controller = FlMlKitScanningController();

  Set<BarcodeFormat> formats = <BarcodeFormat>{BarcodeFormat.all};
  AnalysisImageModel? model;
  CameraInfo? camera;
  CameraResolution resolution = CameraResolution.medium;
  FlashState flashState = FlashState.off;
  double frequency = 600;
  double zoom = 1;
  double maxZoom = 1;
  bool autoScanning = true;
  bool canScanning = true;
  bool showOverlay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          FlMlKitScanning(
            camera: camera,
            resolution: resolution,
            frequency: frequency,
            autoScanning: autoScanning,
            barcodeFormats: formats.toList(growable: false),
            updateReset: true,
            fit: BoxFit.cover,
            overlay: showOverlay ? _buildOverlay() : null,
            onFlashChanged: (FlashState state) => setState(() => flashState = state),
            onZoomChanged: (CameraZoomState state) {
              setState(() {
                zoom = state.zoomRatio ?? 1;
                maxZoom = state.maxZoomRatio ?? 1;
              });
            },
            onDataChanged: (AnalysisImageModel data) {
              if (data.barcodeList.isEmpty) return;
              setState(() => model = data);
            },
            uninitialized: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  FlText('相机未初始化', color: Colors.white70),
                ],
              ),
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
                  child: FlText('实时扫码', color: Colors.white, fontSize: 18, textAlign: TextAlign.center),
                ),
                _CircleButton(icon: Icons.flip_camera_ios_outlined, onTap: switchCamera),
                const SizedBox(width: 8),
                _CircleButton(icon: canScanning ? Icons.pause : Icons.play_arrow, onTap: toggleScanning),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 14, 16, context.mediaQuery.padding.bottom + 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.qr_code, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FlText(
                          model == null
                              ? '对准条码即可自动识别'
                              : '识别到 ${model!.barcodeList.length} 个条码：${model!.barcodeList.first.value ?? ''}',
                          color: Colors.white,
                          fontSize: 13,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (model != null) TextButton(onPressed: showDetails, child: const Text('详情')),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: toggleFlash,
                        icon: Icon(flashState == FlashState.on ? Icons.flash_on : Icons.flash_off),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(onPressed: openSettings, icon: const Icon(Icons.tune)),
                      Expanded(
                        child: Slider(
                          value: zoom.clamp(1, maxZoom <= 1 ? 2 : maxZoom).toDouble(),
                          min: 1,
                          max: maxZoom <= 1 ? 2 : maxZoom,
                          label: '${zoom.toStringAsFixed(1)}x',
                          onChanged: (double value) => setState(() => zoom = value),
                          onChangeEnd: (double value) => controller.setZoomRatio(value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: <Widget>[
        const ScannerBox(
          scannerSize: Size(260, 260),
          borderColor: Colors.tealAccent,
          scannerColor: Colors.tealAccent,
          hornStrokeWidth: 4,
          hornWidth: 20,
          scannerStrokeWidth: 2,
        ),
        ValueListenableBuilder<FlCameraOptions?>(
          valueListenable: controller.cameraOptions,
          builder: (_, FlCameraOptions? options, _) {
            final Size? previewSize = options?.width != null && options?.height != null
                ? Size(options!.width!, options.height!)
                : null;
            return BarcodeOverlay(model: model, previewSize: previewSize);
          },
        ),
      ],
    );
  }

  Future<void> toggleFlash() async {
    final FlashState next = flashState == FlashState.on ? FlashState.off : FlashState.on;
    final bool ok = await controller.setFlashMode(next);
    if (!ok) showToast('闪光灯设置失败');
  }

  Future<void> toggleScanning() async {
    final bool ok = canScanning ? await controller.pauseScanning() : await controller.startScanning();
    if (ok) setState(() => canScanning = !canScanning);
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

  void showDetails() {
    final AnalysisImageModel? model = this.model;
    if (model == null) return;
    Universal(
      height: context.mediaQuery.size.height * 0.7,
      isScroll: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        const FlText('识别结果', fontSize: 18),
        const SizedBox(height: 12),
        ...model.barcodeList.indexed.map(
          ((int, Barcode) entry) => BarcodeDetailsCard(barcode: entry.$2, index: entry.$1),
        ),
      ],
    ).popupModalBottomSheet(options: const ModalBottomSheetOptions());
  }

  void openSettings() {
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setSheetState) {
        void update(VoidCallback action) {
          setState(action);
          setSheetState(() {});
        }

        return Universal(
          height: context.mediaQuery.size.height * 0.78,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          isScroll: true,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const FlText('扫描设置', fontSize: 18),
            const SizedBox(height: 16),
            const FlText('条码格式', fontSize: 14, fontWeight: FontWeight.w600),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BarcodeFormat.values
                  .where((BarcodeFormat item) => item != BarcodeFormat.unknown)
                  .map(
                    (BarcodeFormat item) => FilterChip(
                      label: Text(item.name),
                      selected: formats.contains(item),
                      onSelected: (bool selected) => update(() => applyFormat(item, selected)),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                const FlText('扫描间隔', fontSize: 14, fontWeight: FontWeight.w600),
                const Spacer(),
                FlText('${frequency.toStringAsFixed(0)} ms', fontSize: 13),
              ],
            ),
            Slider(
              value: frequency,
              min: 200,
              max: 2000,
              divisions: 36,
              label: '${frequency.toStringAsFixed(0)} ms',
              onChanged: (double value) => update(() => frequency = value),
            ),
            Row(
              children: <Widget>[
                const Expanded(child: FlText('分辨率', fontSize: 14, fontWeight: FontWeight.w600)),
                DropdownButton<CameraResolution>(
                  value: resolution,
                  items: CameraResolution.values
                      .map(
                        (CameraResolution item) =>
                            DropdownMenuItem<CameraResolution>(value: item, child: Text(item.name)),
                      )
                      .toList(growable: false),
                  onChanged: (CameraResolution? value) {
                    if (value != null) update(() => resolution = value);
                  },
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const FlText('自动开始扫描', fontSize: 14),
              value: autoScanning,
              onChanged: (bool value) => update(() {
                autoScanning = value;
                canScanning = value;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const FlText('显示扫码框与识别区域', fontSize: 14),
              value: showOverlay,
              onChanged: (bool value) => update(() => showOverlay = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: ValueListenableBuilder<FlCameraOptions?>(
                    valueListenable: controller.cameraOptions,
                    builder: (_, FlCameraOptions? options, _) => FilledButton.icon(
                      onPressed: togglePreview,
                      icon: Icon(options == null ? Icons.play_arrow : Icons.pause),
                      label: Text(options == null ? '开始预览' : '停止预览'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () async {
                    final bool ok = await controller.resetCamera();
                    if (!ok) showToast('重置失败');
                  },
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
          ],
        );
      },
    ).popupModalBottomSheet(options: const ModalBottomSheetOptions());
  }

  void applyFormat(BarcodeFormat format, bool selected) {
    if (format == BarcodeFormat.all) {
      formats = <BarcodeFormat>{BarcodeFormat.all};
      return;
    }
    formats = Set<BarcodeFormat>.of(formats)..remove(BarcodeFormat.all);
    if (selected) {
      formats.add(format);
    } else {
      formats.remove(format);
    }
    if (formats.isEmpty) formats = <BarcodeFormat>{BarcodeFormat.all};
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
