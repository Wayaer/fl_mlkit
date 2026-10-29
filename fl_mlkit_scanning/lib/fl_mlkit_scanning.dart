/// Google ML Kit 二维码 / 条形码扫描插件，支持 Android 与 iOS。
///
/// 相机预览由 [fl_camera] 提供，本插件负责在相机帧上执行条码识别，
/// 并把条码内容、坐标与结构化解析结果返回给 Flutter 层。
///
/// ```dart
/// FlMlKitScanning(
///   barcodeFormats: const <BarcodeFormat>[BarcodeFormat.all],
///   overlay: const ScannerBox(scannerSize: Size(260, 260)),
///   onDataChanged: (AnalysisImageModel data) {
///     for (final Barcode barcode in data.barcodeList) {
///       debugPrint(barcode.value);
///     }
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

part 'src/enum.dart';

part 'src/mlkit_scanning.dart';

part 'src/model.dart';

/// 当前平台是否受支持（仅 Android 与 iOS）。
bool get _supportPlatform {
  if (!kIsWeb && (_isAndroid || _isIOS)) return true;
  debugPrint('Not support platform for $defaultTargetPlatform');
  return false;
}

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
