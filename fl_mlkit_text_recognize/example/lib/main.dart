import 'package:example/image_recognize.dart';
import 'package:example/mlkit_text_recognize.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: _App(),
      title: 'FlMlKitTextRecognize'));
}

class _App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<_App> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarText('Fl MlKit Text Recognize'),
        body: Universal(width: double.infinity, children: [
          ElevatedText(
              onPressed: () => openCamera(), text: 'Turn on camera  recognize'),
          ElevatedText(onPressed: scanImage, text: 'Image recognize'),
        ]));
  }

  void scanImage() {
    push(const ImageRecognizePage());
  }

  Future<void> openCamera() async {
    final hasPermission = await getPermission(Permission.camera);
    if (hasPermission) push(const FlMlKitTextRecognizePage());
  }
}

class CodeBox extends StatelessWidget {
  const CodeBox(this.model, {super.key, this.expanded = true});

  final AnalysisTextModel? model;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Universal(expanded: expanded, isScroll: expanded, children: <Widget>[
      TextBox('height=', model?.height),
      TextBox('width=', model?.width),
      TextBox('value=', model?.text),
      const Divider(),
      ...model?.textBlocks
              ?.map((TextBlock b) => SizedBox(
                  width: double.infinity, child: TextBox('TextBlock', b.text)))
              .toList() ??
          []
    ]);
  }
}

class AppBarText extends AppBar {
  AppBarText(String text, {super.key})
      : super(
            elevation: 0,
            title: BText(text, fontSize: 18, fontWeight: FontWeight.bold),
            centerTitle: true);
}

class TextBox extends StatelessWidget {
  final dynamic keyName;
  final dynamic value;

  const TextBox(this.keyName, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null',
        child: Universal(
            padding: const EdgeInsets.all(10),
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$keyName: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value.toString()).expanded,
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

class ElevatedText extends StatelessWidget {
  const ElevatedText({super.key, this.onPressed, required this.text});

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}

class ElevatedIcon extends StatelessWidget {
  const ElevatedIcon({super.key, this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Icon(icon));
}
