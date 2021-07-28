library fl_mlkit_scanning;

import 'package:flutter/services.dart';

export 'package:fl_camera/fl_camera.dart';

export 'src/enum.dart';
export 'src/meth_call.dart';
export 'src/mlkit_scanning.dart';
export 'src/model.dart';

const MethodChannel flMlKitScanningChannel = MethodChannel(flMlKitScanning);
const String flMlKitScanning = 'fl.mlkit.scanning';
