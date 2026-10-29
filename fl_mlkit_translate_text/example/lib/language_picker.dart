import 'package:fl_extended/fl_extended.dart';
import 'package:fl_list_wheel/fl_list_wheel.dart';
import 'package:fl_mlkit_translate_text/fl_mlkit_translate_text.dart';
import 'package:flutter/material.dart';

/// 语言选择弹层。
Future<TranslateLanguage?> showLanguagePicker(BuildContext context, TranslateLanguage current) {
  return Universal(
    height: 380,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: <Widget>[
      Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
        ),
      ),
      const SizedBox(height: 12),
      const FlText('选择语言', fontSize: 18, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      SizedBox(
        height: 220,
        child: FlListWheelState(
          count: TranslateLanguage.values.length,
          initialItem: TranslateLanguage.values.indexOf(current),
          builder: (FixedExtentScrollController controller) => FlListWheel.builder(
            controller: controller,
            itemCount: TranslateLanguage.values.length,
            options: const FlWheelOptions.cupertino(),
            onSelectedItemChanged: (int index) => current = TranslateLanguage.values[index],
            itemBuilder: (_, int index) =>
                Center(child: FlText(languageLabel(TranslateLanguage.values[index]), fontSize: 16)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: () => pop(current), child: const Text('确定')),
      ),
    ],
  ).popupModalBottomSheet(options: const ModalBottomSheetOptions(isScrollControlled: false));
}

/// 语言展示名称，例如 `English`。
String languageLabel(TranslateLanguage language) {
  final String name = language.name;
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}
