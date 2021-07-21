import 'package:example/camera_page.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(ExtendedWidgetsApp(home: _App()));
}

class _App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<_App> {
  List<dynamic> list = <dynamic>[];

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fl MlKit Scanning')),
        mainAxisAlignment: MainAxisAlignment.center,
        padding: const EdgeInsets.all(30),
        children: <Widget>[
          ElevatedButton(
              onPressed: () => openCamera(BarcodeFormats.values),
              child: const Text('open Camera')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: openCamera, child: const Text('识别二维码')),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: () => openCamera(<BarcodeFormats>[
                    BarcodeFormats.code39,
                    BarcodeFormats.codaBar,
                    BarcodeFormats.itf,
                    BarcodeFormats.code93,
                    BarcodeFormats.code128,
                    BarcodeFormats.upcA,
                    BarcodeFormats.upcE,
                    BarcodeFormats.ean8,
                    BarcodeFormats.ean13,
                  ]),
              child: const Text('识别条形码')),
          const SizedBox(height: 30),
          Universal(
              expanded: true, isScroll: true, child: Text(list.toString())),
        ]);
  }

  Future<void> openCamera([List<BarcodeFormats>? barcodeFormats]) async {
    final bool permission = await getPermission(Permission.camera);
    if (permission) {
      final dynamic data =
          await push(CameraPage(barcodeFormats: barcodeFormats));
      if (data != null) {
        list = data as List<Object?>;
        setState(() {});
      }
    } else {
      openAppSettings();
    }
  }
}

Future<bool> getPermission(Permission permission) async {
  PermissionStatus status = await permission.status;
  if (!status.isGranted) {
    status = await permission.request();
    if (!status.isGranted) {
      final bool has = await openAppSettings();
      return has;
    }
  }
  return true;
}
