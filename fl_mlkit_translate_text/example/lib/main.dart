import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_translate_text/fl_mlkit_translate_text.dart';
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
      title: 'FlMlKitTranslate',
      home: Scaffold(
        appBar: AppBarText('Fl MlKit Translate Text'),
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(10.0), child: _App()),
        ),
      ),
    ),
  );
}

class _App extends StatefulWidget {
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  TextEditingController controller = TextEditingController();
  List<TranslateRemoteModel> remoteModels = [];
  FlMlKitTranslateText translateText = FlMlKitTranslateText();
  ValueNotifier<String> text = ValueNotifier<String>('No Translate');

  @override
  void initState() {
    super.initState();
    addPostFrameCallback((duration) {
      getDownloadedModels();
    });
  }

  Future<void> getDownloadedModels() async {
    remoteModels = await translateText.getDownloadedModels();
    bool hasZH = false;
    for (var element in remoteModels) {
      if (element.language == TranslateLanguage.chinese) {
        hasZH = true;
        break;
      }
    }
    if (!hasZH) {
      final state = await translateText.downloadedModel(
        TranslateLanguage.chinese,
      );
      'DownloadedModel TranslateLanguage.chinese = $state'.log();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedText(
          text: 'TranslateRemoteModel Manager',
          onPressed: () {
            context.requestFocus();
            push(const TranslateRemoteModelManagerPage());
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          onSubmitted: (value) {
            context.requestFocus();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Please enter text',
          ),
        ),
        StatefulBuilder(
          builder: (_, state) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedText(
                  onPressed: () async {
                    context.requestFocus();
                    final language = await selectLanguage();
                    if (language != null &&
                        language != translateText.sourceLanguage &&
                        language != translateText.targetLanguage) {
                      translateText
                          .switchLanguage(
                            language,
                            translateText.targetLanguage,
                          )
                          .then((value) {
                            state(() {});
                          });
                    }
                  },
                  text: translateText.sourceLanguage.name,
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () {
                    translateText
                        .switchLanguage(
                          translateText.targetLanguage,
                          translateText.sourceLanguage,
                        )
                        .then((value) {
                          state(() {});
                        });
                  },
                  icon: const Icon(Icons.swap_horizontal_circle),
                ),
                ElevatedText(
                  onPressed: () async {
                    context.requestFocus();
                    final language = await selectLanguage();
                    if (language != null &&
                        language != translateText.sourceLanguage &&
                        language != translateText.targetLanguage) {
                      translateText
                          .switchLanguage(
                            translateText.sourceLanguage,
                            language,
                          )
                          .then((value) {
                            state(() {});
                          });
                    }
                  },
                  text: translateText.targetLanguage.name,
                ),
              ],
            );
          },
        ),
        ElevatedText(text: 'Translation', onPressed: translation),
        const SizedBox(height: 20),
        Card(
          child: ValueListenableBuilder(
            valueListenable: text,
            builder: (_, String value, __) {
              return Universal(
                onLongPress: () {
                  value.toClipboard;
                  showToast('Has been copied');
                },
                alignment: Alignment.center,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: BText(value, textAlign: TextAlign.center),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> translation() async {
    if (controller.text.isEmpty) {
      showToast('Please enter the text');
      return;
    }
    context.requestFocus();
    final hasSourceModel = await translateText.isModelDownloaded(
      translateText.sourceLanguage,
    );
    final hasTargetModel = await translateText.isModelDownloaded(
      translateText.targetLanguage,
    );
    if (hasSourceModel && hasTargetModel) {
      final value = await translateText.translate(controller.text);
      if (value != null) text.value = value;
    } else {
      showToast('No download TranslateRemoteModel');
    }
  }

  Future<TranslateLanguage?> selectLanguage() => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(10),
        right: Radius.circular(10),
      ),
    ),
    child: CustomFutureBuilder<List<TranslateRemoteModel>>(
      future: translateText.getDownloadedModels,
      onWaiting: (_) => const CircularProgressIndicator(),
      onDone: (_, value, __) {
        return ListView.separated(
          itemBuilder: (_, index) {
            return Universal(
              onTap: () {
                pop(value[index].language);
              },
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: BText(value[index].language.toString()),
            );
          },
          itemCount: value.length,
          separatorBuilder:
              (BuildContext context, int index) =>
                  const Divider(thickness: 0.3),
        );
      },
    ),
  ).popupBottomSheet(
    options: const BottomSheetOptions(isScrollControlled: false),
  );

  @override
  void dispose() {
    super.dispose();
    text.dispose();
    translateText.dispose();
  }
}

class TranslateRemoteModelManagerPage extends StatefulWidget {
  const TranslateRemoteModelManagerPage({super.key});

  @override
  State<TranslateRemoteModelManagerPage> createState() =>
      _TranslateRemoteModelManagerPageState();
}

class _TranslateRemoteModelManagerPageState
    extends State<TranslateRemoteModelManagerPage> {
  List<String> listLanguage = [];

  @override
  void initState() {
    super.initState();
    addPostFrameCallback((duration) => getDownloadedModels());
  }

  Future<void> getDownloadedModels() async {
    var list = await FlMlKitTranslateText().getDownloadedModels();
    listLanguage = list.builder(
      (item) => FlMlKitTranslateText().toAbbreviations(item.language),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarText('TranslateRemoteModel Manager'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (_, int index) {
          var item = TranslateLanguage.values[index];
          var abb = FlMlKitTranslateText().toAbbreviations(item);
          var isDownload = listLanguage.contains(abb);
          return Universal(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              BText.rich(
                texts: [
                  '${abb.toUpperCase()}  ',
                  item.toString().split('.')[1],
                ],
                styles: [TextStyle(fontSize: 16, fontWeight: FontWeight.bold)],
              ),
              ValueBuilder<bool>(
                builder: (_, bool? isLoading, updater) {
                  isLoading ??= false;
                  if (isLoading) return const CircularProgressIndicator();
                  return isDownload
                      ? ElevatedText(
                        text: 'Delete',
                        onPressed: () async {
                          updater(true);
                          final state = await FlMlKitTranslateText()
                              .deleteDownloadedModel(item);
                          updater(false);
                          if (state) getDownloadedModels();
                        },
                      )
                      : ElevatedText(
                        text: 'Download',
                        onPressed: () async {
                          updater(true);
                          final state = await FlMlKitTranslateText()
                              .downloadedModel(item);
                          updater(false);
                          if (state) getDownloadedModels();
                        },
                      );
                },
              ),
            ],
          );
        },
        itemCount: TranslateLanguage.values.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
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
