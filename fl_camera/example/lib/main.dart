import 'dart:async';

import 'package:example/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      navigatorKey: GlobalWayUI().navigatorKey,
      scaffoldMessengerKey: GlobalWayUI().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const App(),
      title: 'FlCamera'));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('FlCamera Example')),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: double.infinity),
          ElevatedText(
              onPressed: () async {
                final bool permission = await getPermission(Permission.camera);
                if (permission) push(const CameraPage());
              },
              text: 'Open the camera'),
          ElevatedText(
              onPressed: () async {
                final bool permission = await getPermission(Permission.camera);
                if (permission) push(const ScannerBoxPage());
              },
              text: '扫码框浮层'),
          ElevatedText(
              onPressed: () async {
                final bool permission = await getPermission(Permission.camera);
                if (permission) push(const ScannerLinePage());
              },
              text: '线条浮层'),
        ]));
  }
}

Future<bool> getPermission(Permission permission) async {
  PermissionStatus status = await permission.status;
  if (status.isGranted) {
    return true;
  } else {
    status = await permission.request();
    if (!status.isGranted) openAppSettings();
    return status.isGranted;
  }
}

Widget showText(dynamic key, dynamic value) {
  return Visibility(
      visible: value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'null',
      child: Container(
          margin: const EdgeInsets.all(10), child: Text('$key = $value')));
}

class ElevatedText extends ElevatedButton {
  ElevatedText({super.key, required String text, required super.onPressed})
      : super(child: Text(text));
}

class ElevatedIcon extends ElevatedButton {
  ElevatedIcon({super.key, required IconData icon, required super.onPressed})
      : super(child: Icon(icon));
}
