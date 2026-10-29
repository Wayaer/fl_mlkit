import 'dart:async';

import 'package:fl_channel/fl_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:fl_channel/fl_channel.dart';

part 'src/controller.dart';

part 'src/fl_camera.dart';

part 'src/scanner_box.dart';

part 'src/scanner_line.dart';

/// 当前平台是否受支持。
///
/// 仅 Android 与 iOS 可用，其余平台会打印日志并返回 false。
bool get _supportPlatform {
  if (!kIsWeb && (_isAndroid || _isIOS)) return true;
  debugPrint('Not support platform for $defaultTargetPlatform');
  return false;
}

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
