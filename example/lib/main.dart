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
  List<BarcodeModel> list = <BarcodeModel>[];

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fl MlKit Scanning')),
        mainAxisAlignment: MainAxisAlignment.center,
        padding: const EdgeInsets.all(30),
        children: <Widget>[
          ElevatedButton(
              onPressed: () => openCamera(BarcodeFormat.values),
              child: const Text('open Camera')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: openCamera, child: const Text('识别二维码')),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: () => openCamera(<BarcodeFormat>[
                    BarcodeFormat.code39,
                    BarcodeFormat.code_bar,
                    BarcodeFormat.itf,
                    BarcodeFormat.code93,
                    BarcodeFormat.code128,
                    BarcodeFormat.upc_a,
                    BarcodeFormat.upc_e,
                    BarcodeFormat.ean8,
                    BarcodeFormat.ean13,
                  ]),
              child: const Text('识别条形码')),
          const SizedBox(height: 30),
          Universal(
            expanded: true,
            isScroll: true,
            children: list.builderEntry((MapEntry<int, BarcodeModel> entry) {
              return Column(children: [
                Text('第${entry.key + 1}个二维码'),
                const SizedBox(height: 6),
                Text('value:${entry.value.value}')
                    .sizedBox(width: double.infinity),
                const SizedBox(height: 6),
                Text('type:${entry.value.type}')
                    .sizedBox(width: double.infinity),
              ]);
            }),
          ),
        ]);
  }

  Future<void> openCamera([List<BarcodeFormat>? barcodeFormats]) async {
    final bool permission = await getPermission(Permission.camera);
    if (permission) {
      final List<BarcodeModel>? data =
          await push(CameraPage(barcodeFormats: barcodeFormats));
      if (data != null) {
        list = data;
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
