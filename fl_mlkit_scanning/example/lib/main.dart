import 'package:example/image_scanning.dart';
import 'package:example/mlkit_scanning.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
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
      title: 'FlMlKitScanning'));
}

class _App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<_App> {
  List<Barcode> list = <Barcode>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarText('Fl MlKit Scanning'),
        body: Universal(width: double.infinity, children: [
          ElevatedText(onPressed: openCamera, text: 'Turn on camera scanning'),
          ElevatedText(onPressed: scanImage, text: 'Image scanning'),
          const SizedBox(height: 30),
          CodeBox(list)
        ]));
  }

  void scanImage() {
    push(const ImageScanningPage());
  }

  Future<void> openCamera() async {
    bool permission = await getPermission(Permission.camera);
    if (permission) {
      final List<Barcode>? data = await push(const FlMlKitScanningPage());
      if (data != null) {
        list = data;
        setState(() {});
      }
    }
  }
}

class CodeBox extends StatelessWidget {
  const CodeBox(this.list, {super.key, this.expanded = true});

  final List<Barcode> list;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Universal(
        expanded: expanded,
        isScroll: expanded,
        children: list.builderEntry((MapEntry<int, Barcode> entry) {
          return Column(children: <Widget>[
            Text('NO.${entry.key + 1}'),
            const SizedBox(height: 6),
            Text('value:${entry.value.value}').sizedBox(width: double.infinity),
            const SizedBox(height: 6),
            Text('type:${entry.value.type}').sizedBox(width: double.infinity),
            Text('boundingBox:${entry.value.boundingBox?.size}')
                .sizedBox(width: double.infinity),
            Text('boundingBox:${entry.value.boundingBox}')
                .sizedBox(width: double.infinity),
            Text('corners:${entry.value.corners}')
                .sizedBox(width: double.infinity),
          ]);
        }));
  }
}

class AppBarText extends AppBar {
  AppBarText(String text, {super.key})
      : super(
            elevation: 0,
            title: BText(text, fontSize: 18, fontWeight: FontWeight.bold));
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
        child: Container(
            margin: const EdgeInsets.all(10),
            child: Text('$keyName = $value')));
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
  Widget build(BuildContext context) => ElevatedButton(
      onPressed: onPressed, child: Icon(icon, color: Colors.white));
}
