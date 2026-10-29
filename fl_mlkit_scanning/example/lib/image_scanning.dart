import 'dart:typed_data';

import 'package:example/barcode_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

/// 图片文件扫码演示。
class ImageScanningPage extends StatefulWidget {
  const ImageScanningPage({super.key});

  @override
  State<ImageScanningPage> createState() => _ImageScanningPageState();
}

class _ImageScanningPageState extends State<ImageScanningPage> {
  final FlMlKitScanningController controller = FlMlKitScanningController();

  Uint8List? bytes;
  String? fileName;
  AnalysisImageModel? model;
  Set<BarcodeFormat> formats = <BarcodeFormat>{BarcodeFormat.all};
  double rotationDegrees = 0;
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    final bool hasData = bytes != null;
    return Scaffold(
      appBar: AppBar(title: const FlText('图片扫描', fontSize: 18)),
      body: Universal(
        isScroll: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('选择图片'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: hasData && !scanning ? scanImage : null,
                  icon: scanning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: Text(scanning ? '识别中...' : '开始识别'),
                ),
              ),
            ],
          ),
          if (fileName != null) ...<Widget>[
            const SizedBox(height: 10),
            FlText(fileName!, fontSize: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (hasData) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes!, height: 260, width: double.infinity, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const FlText('旋转角度（仅 Android）', fontSize: 13),
                const Spacer(),
                FlText('${rotationDegrees.toStringAsFixed(0)}°', fontSize: 13),
              ],
            ),
            Slider(
              value: rotationDegrees,
              max: 360,
              divisions: 24,
              onChanged: (double value) => setState(() => rotationDegrees = value),
            ),
          ],
          const SizedBox(height: 16),
          const FlText('条码格式', fontSize: 15, fontWeight: FontWeight.w600),
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
                    onSelected: (bool selected) => toggleFormat(item, selected),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          const FlText('识别结果', fontSize: 15, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          if (model == null)
            const FlText('请选择图片并点击“开始识别”', fontSize: 13)
          else if (model!.barcodeList.isEmpty)
            const FlText('未识别到条码，试试调整旋转角度或选择全部格式', fontSize: 13)
          else
            ...model!.barcodeList.indexed.map(
              ((int, Barcode) entry) => BarcodeDetailsCard(barcode: entry.$2, index: entry.$1),
            ),
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final Uint8List data = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      bytes = data;
      fileName = file.name;
      model = null;
    });
  }

  Future<void> scanImage() async {
    final Uint8List? data = bytes;
    if (data == null) return;
    setState(() => scanning = true);
    final bool formatState = await controller.setBarcodeFormat(formats.toList(growable: false));
    if (!formatState) showToast('设置条码格式失败');
    final AnalysisImageModel? result = await controller.scanningImageByte(
      data,
      rotationDegrees: rotationDegrees.round(),
    );
    if (!mounted) return;
    setState(() {
      model = result;
      scanning = false;
    });
    if (result == null) showToast('识别失败');
  }

  void toggleFormat(BarcodeFormat format, bool selected) {
    setState(() {
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
    });
  }
}
