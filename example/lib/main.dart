import 'package:example/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(ExtendedWidgetsApp(
    home: App(),
  ));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fl MlKit Scanning')),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
              onPressed: openCamera, child: const Text('open Camera')),
        ]);
  }

  Future<void> openCamera() async {
    final bool permission = await getPermission(Permission.camera);
    if (permission) {
      push(const CameraPage());
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
