library fl_mlkit_scanning;

import 'package:flutter/services.dart';

export 'src/fl_mlkit_scanning_meth_call.dart';
export 'src/mlkit_scanning.dart';

const MethodChannel flMlKitScanningChannel = MethodChannel(flMlKitScanning);
const String flMlKitScanning = 'fl.mlkit.scanning';
