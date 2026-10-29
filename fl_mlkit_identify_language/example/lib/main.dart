import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_identify_language/fl_mlkit_identify_language.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IdentifyLanguageApp());
}

/// ML Kit 语言识别示例应用。
class IdentifyLanguageApp extends StatelessWidget {
  const IdentifyLanguageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlMlKitIdentifyLanguage',
      debugShowCheckedModeBanner: false,
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0369A1))),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0369A1), brightness: Brightness.dark),
      ),
      home: const IdentifyPage(),
    );
  }
}

/// 语言识别主页。
class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key});

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  final FlMlKitIdentifyLanguage identifier = FlMlKitIdentifyLanguage();
  final TextEditingController textController = TextEditingController();

  double confidence = 0.5;
  IdentifiedLanguageModel? best;
  List<IdentifiedLanguageModel> possible = <IdentifiedLanguageModel>[];
  bool identifying = false;

  @override
  void initState() {
    super.initState();
    confidence = identifier.confidence;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Universal(
          isScroll: true,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.language, size: 28, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlText('语言识别', fontSize: 22),
                      SizedBox(height: 2),
                      FlText('ML Kit Language ID · Android / iOS', fontSize: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              maxLines: 5,
              minLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: '输入文本',
                hintText: '例如：Bonjour, comment allez-vous ?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            Row(
              children: <Widget>[
                const FlText('置信度阈值', fontSize: 14, fontWeight: FontWeight.w600),
                const Spacer(),
                FlText(confidence.toStringAsFixed(2), fontSize: 14),
              ],
            ),
            Slider(
              value: confidence,
              min: 0.01,
              max: 1,
              divisions: 99,
              label: confidence.toStringAsFixed(2),
              onChanged: (double value) => setState(() => confidence = value),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: applyConfidence,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('应用置信度'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: readNativeConfidence,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('读取原生值'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: identifying ? null : identifyBest,
                    icon: identifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: const Text('识别最可能的语言'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: identifying ? null : identifyPossible,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('识别所有可能'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (best != null) ...<Widget>[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: const Icon(Icons.translate),
                  ),
                  title: FlText('最可能：${best!.languageTag}', fontSize: 15),
                  subtitle: FlText('置信度阈值：${best!.confidence.toStringAsFixed(2)}', fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (possible.isNotEmpty) ...<Widget>[
              const FlText('可能语言', fontSize: 15, fontWeight: FontWeight.w600),
              const SizedBox(height: 8),
              ...possible.map(
                (IdentifiedLanguageModel item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: FlText(item.languageTag, fontSize: 14, fontWeight: FontWeight.w600)),
                          FlText('${(item.confidence * 100).toStringAsFixed(1)}%', fontSize: 12),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: item.confidence, minHeight: 6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FlText(
              '说明：identifyLanguage 只返回语言代码，因此 confidence 展示的是当前阈值；'
              'identifyPossibleLanguages 返回真实的置信度。无法确定的语言返回 und。',
              fontSize: 12,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> applyConfidence() async {
    final bool ok = await identifier.setConfidence(confidence);
    if (!ok) {
      showToast('置信度设置失败，取值范围 0.01 ~ 1');
      return;
    }
    showToast('置信度已更新为 ${confidence.toStringAsFixed(2)}');
  }

  Future<void> readNativeConfidence() async {
    final double value = await identifier.getCurrentConfidence();
    if (!mounted) return;
    setState(() => confidence = value);
    showToast('原生置信度：${value.toStringAsFixed(2)}');
  }

  Future<void> identifyBest() async {
    final String text = textController.text.trim();
    if (text.isEmpty) {
      showToast('请输入文本');
      return;
    }
    setState(() => identifying = true);
    final IdentifiedLanguageModel? value = await identifier.identifyLanguage(text);
    if (!mounted) return;
    setState(() {
      identifying = false;
      best = value;
      possible = <IdentifiedLanguageModel>[];
    });
    if (value == null) showToast('识别失败');
  }

  Future<void> identifyPossible() async {
    final String text = textController.text.trim();
    if (text.isEmpty) {
      showToast('请输入文本');
      return;
    }
    setState(() => identifying = true);
    final List<IdentifiedLanguageModel> values = await identifier.identifyPossibleLanguages(text);
    if (!mounted) return;
    setState(() {
      identifying = false;
      possible = values;
      best = values.isEmpty ? null : values.first;
    });
    if (values.isEmpty) showToast('没有识别到语言');
  }

  @override
  void dispose() {
    textController.dispose();
    identifier.dispose();
    super.dispose();
  }
}
