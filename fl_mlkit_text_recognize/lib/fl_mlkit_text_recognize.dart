/// Google ML Kit 文字识别（OCR）插件，支持 Android 与 iOS。
///
/// 相机预览由 [fl_camera] 提供，本插件负责识别画面中的文字，
/// 并返回文字块、行、元素及其坐标。
///
/// ```dart
/// FlMlKitTextRecognize(
///   recognizedLanguage: RecognizedLanguage.chinese,
///   onDataChanged: (AnalysisTextModel data) {
///     debugPrint(data.text);
///   },
/// )
/// ```
library;

import 'dart:async';

import 'package:fl_camera/fl_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:fl_camera/fl_camera.dart';

part 'src/controller.dart';

part 'src/mlkit_text_recognize.dart';

part 'src/model.dart';

/// 当前平台是否受支持（仅 Android 与 iOS）。
bool get _supportPlatform {
  if (!kIsWeb && (_isAndroid || _isIOS)) return true;
  debugPrint('Not support platform for $defaultTargetPlatform');
  return false;
}

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
