import 'package:fl_mlkit_identify_language/fl_mlkit_identify_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(const ExtendedWidgetsApp(home: _App()));
}

class _App extends StatefulWidget {
  const _App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<_App> {
  ValueNotifier<List<IdentifiedLanguageModel>> identifiedLanguageModel =
      ValueNotifier<List<IdentifiedLanguageModel>>([]);
  TextEditingController controller = TextEditingController();
  FlMlKitIdentifyLanguage mlKitIdentifyLanguage = FlMlKitIdentifyLanguage();

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        isScroll: true,
        appBar: AppBarText('Fl MlKit Identify Language'),
        mainAxisAlignment: MainAxisAlignment.center,
        padding: const EdgeInsets.all(30),
        children: [
          TextField(
              controller: controller,
              maxLength: 500,
              maxLines: 4,
              onSubmitted: (value) {
                context.requestFocus();
              },
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Please enter text')),
          CustomFutureBuilder<double>(
              future: () async => mlKitIdentifyLanguage.confidence,
              onWaiting: (_) => const CircularProgressIndicator(),
              onDone: (_, double value, reset) {
                return ElevatedText(
                    onPressed: () async {
                      context.requestFocus();
                      final confidence = await selectConfidence();
                      if (confidence != null) {
                        final state = await mlKitIdentifyLanguage
                            .setConfidence(confidence);
                        if (state) reset();
                      }
                    },
                    text: 'Click Modify Confidence : $value');
              }),
          ElevatedText(text: 'Identify Language', onPressed: identifyLanguage),
          ElevatedText(
              text: 'Get Native Confidence',
              onPressed: () {
                mlKitIdentifyLanguage.getCurrentConfidence().then((value) {
                  showToast(value.toString());
                });
              }),
          ElevatedText(
              text: 'Identify Possible Language',
              onPressed: identifyPossibleLanguages),
          const SizedBox(height: 20),
          ValueListenableBuilder(
              valueListenable: identifiedLanguageModel,
              builder: (_, List<IdentifiedLanguageModel> value, __) {
                return Column(
                    children: value.builder((item) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6)),
                        child: RText(
                            texts: [
                              'confidence：',
                              item.confidence.toString(),
                              '      languageTag：',
                              item.languageTag,
                            ],
                            textAlign: TextAlign.start,
                            styles: const [
                              BTextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              BTextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              BTextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              BTextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ]))));
              })
        ]);
  }

  Future<void> identifyLanguage() async {
    if (controller.text.isEmpty) {
      showToast('Please enter the text');
      return;
    }
    context.requestFocus();
    final data = await mlKitIdentifyLanguage.identifyLanguage(controller.text);
    if (data != null) {
      identifiedLanguageModel.value = [data];
      setState(() {});
    }
  }

  Future<void> identifyPossibleLanguages() async {
    if (controller.text.isEmpty) {
      showToast('Please enter the text');
      return;
    }
    context.requestFocus();
    final data =
        await mlKitIdentifyLanguage.identifyPossibleLanguages(controller.text);
    identifiedLanguageModel.value = data;
    setState(() {});
  }

  Future<double?> selectConfidence() {
    var confidences = [0.01, 0.1, 0.25, 0.5, 0.75, 1.0];
    return Universal(
      mainAxisSize: MainAxisSize.min,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(
              left: Radius.circular(10), right: Radius.circular(10))),
      children: confidences.builder((item) => Universal(
          width: double.infinity,
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 0.5))),
          onTap: () {
            pop(item);
          },
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(item.toString(), textAlign: TextAlign.center))),
    ).popupBottomSheet(
        options: const BottomSheetOptions(isScrollControlled: false));
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
