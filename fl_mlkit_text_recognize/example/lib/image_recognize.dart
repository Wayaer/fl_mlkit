import 'dart:typed_data';

import 'package:example/text_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';

/// 图片文件文字识别演示。
class ImageRecognizePage extends StatefulWidget {
  const ImageRecognizePage({super.key});

  @override
  State<ImageRecognizePage> createState() => _ImageRecognizePageState();
}

class _ImageRecognizePageState extends State<ImageRecognizePage> {
  final FlMlKitTextRecognizeController controller = FlMlKitTextRecognizeController();

  Uint8List? bytes;
  String? fileName;
  AnalysisTextModel? model;
  RecognizedLanguage language = RecognizedLanguage.latin;
  double rotationDegrees = 0;
  bool recognizing = false;

  @override
  Widget build(BuildContext context) {
    final bool hasData = bytes != null;
    return Scaffold(
      appBar: AppBar(title: const FlText('图片识别', fontSize: 18)),
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
                  onPressed: hasData && !recognizing ? recognizeImage : null,
                  icon: recognizing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.text_fields),
                  label: Text(recognizing ? '识别中...' : '开始识别'),
                ),
              ),
            ],
          ),
          if (fileName != null) ...<Widget>[
            const SizedBox(height: 10),
            FlText(fileName!, fontSize: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 14),
          const FlText('识别语言', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          SegmentedButton<RecognizedLanguage>(
            segments: RecognizedLanguage.values
                .map(
                  (RecognizedLanguage item) => ButtonSegment<RecognizedLanguage>(value: item, label: Text(item.name)),
                )
                .toList(growable: false),
            selected: <RecognizedLanguage>{language},
            showSelectedIcon: false,
            onSelectionChanged: (Set<RecognizedLanguage> value) => setState(() => language = value.first),
          ),
          if (hasData) ...<Widget>[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes!, height: 240, width: double.infinity, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          const FlText('识别结果', fontSize: 15, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          if (model == null) const FlText('请选择图片并点击“开始识别”', fontSize: 13) else TextResultView(model: model!),
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

  Future<void> recognizeImage() async {
    final Uint8List? data = bytes;
    if (data == null) return;
    setState(() => recognizing = true);
    final bool languageState = await controller.setRecognizedLanguage(language);
    if (!languageState) showToast('设置识别语言失败');
    final AnalysisTextModel? result = await controller.recognizeImageByte(
      data,
      rotationDegrees: rotationDegrees.round(),
    );
    if (!mounted) return;
    setState(() {
      model = result;
      recognizing = false;
    });
    if (result == null) showToast('识别失败');
  }
}
