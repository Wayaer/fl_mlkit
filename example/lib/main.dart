import 'package:example/camera_scan.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
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
  List<BarcodeModel> list = <BarcodeModel>[];

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBarText('Fl MlKit Scanning'),
        mainAxisAlignment: MainAxisAlignment.center,
        padding: const EdgeInsets.all(30),
        children: <Widget>[
          ElevatedText(
              onPressed: () => openCamera(BarcodeFormat.values),
              text: 'open Camera'),
          const SizedBox(height: 10),
          ElevatedText(onPressed: scanImage, text: '官方相机扫码'),
          ElevatedText(onPressed: openCamera, text: '识别二维码'),
          const SizedBox(height: 10),
          ElevatedText(
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
              text: '识别条形码'),
          const SizedBox(height: 30),
          ShowCode(list)
        ]);
  }

  Future<void> scanImage() async {
    if (!isMobile) return;
    final bool permission = await getPermission(Permission.camera) &&
        await getPermission(Permission.storage);
    if (permission) {
      push(CameraScanPage());
    } else {
      openAppSettings();
    }
  }

  Future<void> openCamera([List<BarcodeFormat>? barcodeFormats]) async {
    final bool permission = await getPermission(Permission.camera);
    if (permission) {
      final List<BarcodeModel>? data =
          await push(FlMlKitScanningPage(barcodeFormats: barcodeFormats));
      if (data != null) {
        list = data;
        setState(() {});
      }
    } else {
      openAppSettings();
    }
  }
}

class ShowCode extends StatelessWidget {
  const ShowCode(this.list, {Key? key}) : super(key: key);
  final List<BarcodeModel> list;

  @override
  Widget build(BuildContext context) {
    return Universal(
        expanded: true,
        isScroll: true,
        children: list.builderEntry((MapEntry<int, BarcodeModel> entry) {
          return Column(children: <Widget>[
            Text('第${entry.key + 1}个二维码'),
            const SizedBox(height: 6),
            Text('value:${entry.value.value}').sizedBox(width: double.infinity),
            const SizedBox(height: 6),
            Text('type:${entry.value.type}').sizedBox(width: double.infinity),
          ]);
        }));
  }
}

class AppBarText extends AppBar {
  AppBarText(String text, {Key? key})
      : super(
            key: key,
            elevation: 0,
            iconTheme: const IconThemeData.fallback(),
            title: BText(text,
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            centerTitle: true);
}

class ShowText extends StatelessWidget {
  const ShowText(this.keyName, this.value) : super();
  final dynamic keyName;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null',
        child: Container(
            margin: const EdgeInsets.all(10),
            child: Text(keyName.toString() + ' = ' + value.toString())));
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

class ElevatedText extends StatelessWidget {
  const ElevatedText({Key? key, this.onPressed, required this.text})
      : super(key: key);
  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}

class FlMlKitScanningPage extends StatelessWidget {
  const FlMlKitScanningPage({Key? key, this.barcodeFormats}) : super(key: key);
  final List<BarcodeFormat>? barcodeFormats;

  @override
  Widget build(BuildContext context) {
    bool backState = true;
    return ExtendedScaffold(
        body: Stack(children: <Widget>[
      FlMlKitScanning(
        overlay: const ScannerLine(),
        barcodeFormats: barcodeFormats,
        onListen: (List<BarcodeModel> barcodes) {
          if (backState && barcodes.isNotEmpty) {
            backState = false;
            pop(barcodes);
          }
        },
      ),
    ]));
  }
}
