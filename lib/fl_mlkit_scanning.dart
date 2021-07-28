import 'dart:io';
import 'dart:typed_data';

import 'package:fl_camera/fl_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:fl_camera/fl_camera.dart';

part 'src/enum.dart';

part 'src/meth_call.dart';

part 'src/mlkit_scanning.dart';

part 'src/model.dart';

part 'src/util.dart';

const MethodChannel _flMlKitScanningChannel = MethodChannel(_flMlKitScanning);
const String _flMlKitScanning = 'fl.mlkit.scanning';
