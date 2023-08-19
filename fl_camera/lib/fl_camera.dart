import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'src/controller.dart';

part 'src/fl_camera.dart';

part 'src/fl_camera_event.dart';

part 'src/shade/scanner_box.dart';

part 'src/shade/scanner_line.dart';

const MethodChannel _flCameraChannel = MethodChannel('fl.camera');

bool get _supportPlatform {
  if (!kIsWeb && (_isAndroid || _isIOS)) return true;
  debugPrint('Not support platform for $defaultTargetPlatform');
  return false;
}

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
