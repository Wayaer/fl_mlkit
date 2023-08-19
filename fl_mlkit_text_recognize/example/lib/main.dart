import 'package:example/camera_scan.dart';
import 'package:example/image_scan.dart';
import 'package:example/mlkit_text_recognize.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
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
  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBarText('Fl MlKit Text Recognize'),
        padding: const EdgeInsets.all(30),
        children: <Widget>[
          const SizedBox(height: 10),
          ElevatedText(
              onPressed: () => openCamera(), text: 'Camera recognition'),
          const SizedBox(height: 10),
          ElevatedText(onPressed: scanImage, text: 'Image recognition'),
          const SizedBox(height: 10),
        ]);
  }

  void scanImage() {
    push(const ImageScanPage());
  }

  Future<void> scanCamera() async {
    if (!isMobile) return;
    final bool permission = await getPermission(Permission.camera);
    if (permission) push(const CameraScanPage());
  }

  Future<void> openCamera() async {
    bool hasPermission = false;
    if (isAndroid) hasPermission = await getPermission(Permission.camera);
    if (isIOS) hasPermission = true;
    if (hasPermission) push(const FlMlKitTextRecognizePage());
  }
}

class ShowCode extends StatelessWidget {
  const ShowCode(this.model, {Key? key, this.expanded = true})
      : super(key: key);
  final AnalysisTextModel? model;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Universal(expanded: expanded, isScroll: expanded, children: <Widget>[
      ShowText('height=', model?.height),
      ShowText('width=', model?.width),
      ShowText('value=', model?.text),
      const Divider(),
      ...model?.textBlocks
              ?.map((TextBlock b) => SizedBox(
                  width: double.infinity, child: ShowText('TextBlock', b.text)))
              .toList() ??
          <Widget>[]
    ]);
  }
}

class AppBarText extends AppBar {
  AppBarText(String text, {Key? key})
      : super(
            key: key,
            elevation: 0,
            title: BText(text,
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            centerTitle: true);
}

class ShowText extends StatelessWidget {
  final dynamic keyName;
  final dynamic value;

  const ShowText(this.keyName, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null',
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: RText(textAlign: TextAlign.start, texts: <String>[
              '$keyName: ',
              value.toString()
            ], styles: const <TextStyle>[
              TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.3),
              TextStyle(color: Colors.black, height: 1.3),
            ])));
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

class ElevatedText extends StatelessWidget {
  const ElevatedText({Key? key, this.onPressed, required this.text})
      : super(key: key);
  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}

class ElevatedIcon extends StatelessWidget {
  const ElevatedIcon({Key? key, this.onPressed, required this.icon})
      : super(key: key);
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ElevatedButton(
      onPressed: onPressed, child: Icon(icon, color: Colors.white));
}
