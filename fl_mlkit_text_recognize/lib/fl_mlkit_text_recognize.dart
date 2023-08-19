import 'package:fl_camera/fl_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:fl_camera/fl_camera.dart' hide CameraController;

part 'src/controller.dart';

part 'src/mlkit_text_recognize.dart';

part 'src/model.dart';

const MethodChannel _flMlKitTextRecognizeChannel =
    MethodChannel('fl.mlkit.text.recognize');

bool get _supportPlatform {
  if (!kIsWeb && (_isAndroid || _isIOS)) return true;
  debugPrint('Not support platform for $defaultTargetPlatform');
  return false;
}

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
