import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_identify_language/fl_mlkit_identify_language.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      title: 'FlMlKitIdentifyLanguage',
      home: Scaffold(
        appBar: AppBarText('Fl MlKit Identify Language'),
        body: const SingleChildScrollView(
          child: Padding(padding: EdgeInsets.all(10.0), child: _App()),
        ),
      ),
    ),
  );
}

class _App extends StatefulWidget {
  const _App();

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<_App> {
  ValueNotifier<List<IdentifiedLanguageModel>> identifiedLanguageModel =
      ValueNotifier<List<IdentifiedLanguageModel>>([]);
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();
  FlMlKitIdentifyLanguage mlKitIdentifyLanguage = FlMlKitIdentifyLanguage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: 500,
          maxLines: 4,
          onSubmitted: (value) {
            focusNode.unfocus();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Please enter text',
          ),
        ),
        CustomFutureBuilder<double>(
          future: () async => mlKitIdentifyLanguage.confidence,
          onWaiting: (_) => const CircularProgressIndicator(),
          onDone: (_, double value, reset) {
            return ElevatedText(
              onPressed: () async {
                focusNode.unfocus();
                final confidence = await selectConfidence();
                if (confidence != null) {
                  final state = await mlKitIdentifyLanguage.setConfidence(
                    confidence,
                  );
                  if (state) reset();
                }
              },
              text: 'Click Modify Confidence : $value',
            );
          },
        ),
        ElevatedText(text: 'Identify Language', onPressed: identifyLanguage),
        ElevatedText(
          text: 'Get Native Confidence',
          onPressed: () {
            mlKitIdentifyLanguage.getCurrentConfidence().then((value) {
              showToast(value.toString());
            });
          },
        ),
        ElevatedText(
          text: 'Identify Possible Language',
          onPressed: identifyPossibleLanguages,
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder(
          valueListenable: identifiedLanguageModel,
          builder: (_, List<IdentifiedLanguageModel> value, __) {
            return Column(
              children: value.builder(
                (item) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: BText.rich(
                    texts: [
                      'confidence：',
                      item.confidence.toString(),
                      '      languageTag：',
                      item.languageTag,
                    ],
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> identifyLanguage() async {
    if (controller.text.isEmpty) {
      showToast('Please enter the text');
      return;
    }
    focusNode.unfocus();
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
    final data = await mlKitIdentifyLanguage.identifyPossibleLanguages(
      controller.text,
    );
    identifiedLanguageModel.value = data;
    setState(() {});
  }

  Future<double?> selectConfidence() {
    var confidences = [0.01, 0.1, 0.25, 0.5, 0.75, 1.0];
    return Universal(
      safeBottom: true,
      mainAxisSize: MainAxisSize.min,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(10),
          right: Radius.circular(10),
        ),
      ),
      children: confidences.builder(
        (item) => Universal(
          width: double.infinity,
          onTap: () {
            pop(item);
          },
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: BText(item.toString(), textAlign: TextAlign.center),
        ),
      ),
    ).popupBottomSheet(
      options: const BottomSheetOptions(isScrollControlled: false),
    );
  }
}

class AppBarText extends AppBar {
  AppBarText(String text, {super.key})
    : super(
        elevation: 0,
        title: BText(text, fontSize: 18, fontWeight: FontWeight.bold),
        centerTitle: true,
      );
}

class ElevatedText extends ElevatedButton {
  ElevatedText({super.key, required String text, required super.onPressed})
    : super(child: Text(text));
}
