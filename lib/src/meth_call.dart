import 'dart:io';
import 'dart:typed_data';

import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/services.dart';

class FlMLKitScanningMethodCall {
  factory FlMLKitScanningMethodCall() => _getInstance();

  FlMLKitScanningMethodCall._internal();

  static FlMLKitScanningMethodCall get instance => _getInstance();
  static FlMLKitScanningMethodCall? _instance;

  static FlMLKitScanningMethodCall _getInstance() {
    _instance ??= FlMLKitScanningMethodCall._internal();
    return _instance!;
  }

  final MethodChannel _channel = flMlKitScanningChannel;

  List<BarcodeFormat> _barcodeFormats = <BarcodeFormat>[BarcodeFormat.qr_code];

  MethodChannel get channel => _channel;

  /// 设置设别码类型
  Future<bool> setBarcodeFormat(List<BarcodeFormat> barcodeFormats) async {
    _barcodeFormats = barcodeFormats;
    final bool? state = await _channel
        .invokeMethod<bool?>('setBarcodeFormat', <String, dynamic>{
      'barcodeFormats': _barcodeFormats
          .map((BarcodeFormat e) => e.toString().split('.')[1])
          .toSet()
          .toList()
    });
    return state ?? false;
  }

  /// 识别图片字节
  Future<bool> scanImageByte(Uint8List uint8list,
      {int rotationDegrees = 0}) async {
    final bool? state = await _channel.invokeMethod<bool?>(
        'scanImageByte', <String, dynamic>{
      'byte': uint8list,
      'rotationDegrees': rotationDegrees
    });
    return state ?? false;
  }

  /// 识别本地存储的图片
  Future<bool> scanImagePath(String path, {int rotationDegrees = 0}) async {
    final File file = File(path);
    if (file.existsSync()) {
      return await scanImageByte(file.readAsBytesSync(),
          rotationDegrees: rotationDegrees);
    }
    return false;
  }
}
