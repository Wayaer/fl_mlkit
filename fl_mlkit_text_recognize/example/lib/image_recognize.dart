import 'dart:io';

import 'package:example/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageRecognizePage extends StatefulWidget {
  const ImageRecognizePage({super.key});

  @override
  State<ImageRecognizePage> createState() => _ImageRecognizePageState();
}

class _ImageRecognizePageState extends State<ImageRecognizePage> {
  String? path;
  AnalysisTextModel? model;

  int? selectIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarText('Recognize file image'),
        body: Universal(
            padding: const EdgeInsets.all(20),
            isScroll: true,
            width: double.infinity,
            children: [
              ElevatedText(onPressed: openGallery, text: 'Select Picture'),
              ElevatedButton(
                  onPressed: () {},
                  child: DropdownMenuButton.material(
                      itemCount: RecognizedLanguage.values.length,
                      onChanged: (int index) {
                        selectIndex = index;
                        FlMlKitTextRecognizeController().setRecognizedLanguage(
                            RecognizedLanguage.values[selectIndex!]);
                      },
                      builder: (int? index) => BText(index == null
                          ? 'Select Recognized Language'
                          : RecognizedLanguage.values[index].name),
                      itemBuilder: (int index) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: BText(RecognizedLanguage.values[index].name,
                              fontSize: 14)))),
              ElevatedText(onPressed: scanByte, text: 'Recognize'),
              TextBox('path', path),
              if (path != null && path!.isNotEmpty)
                Container(
                    width: double.infinity,
                    height: 300,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
                    child: Image.file(File(path!))),
              if (model == null) const TextBox('Unrecognized', 'Unrecognized'),
              CodeBox(model, expanded: false)
            ]));
  }

  Future<void> scanByte() async {
    if (path == null || path!.isEmpty) {
      showToast('Please select a picture');
      return;
    }
    if (selectIndex == null) {
      showToast('Please select recognized language');
      return;
    }
    bool hasPermission = true;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (hasPermission) {
      final File file = File(path!);
      final AnalysisTextModel? data = await FlMlKitTextRecognizeController()
          .recognizeImageByte(file.readAsBytesSync());
      if (data != null) {
        model = data;
        setState(() {});
      } else {
        showToast('no data');
      }
    }
  }

  Future<void> openGallery() async {
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.storage);
    if (isIOS) hasPermission = true;
    if (!hasPermission) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    path = result.files.first.path;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    FlMlKitTextRecognizeController().dispose();
  }
}
