import 'package:example/language_picker.dart';
import 'package:example/model_manager.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_translate_text/fl_mlkit_translate_text.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TranslateApp());
}

/// ML Kit 文本翻译示例应用。
class TranslateApp extends StatelessWidget {
  const TranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlMlKitTranslateText',
      debugShowCheckedModeBanner: false,
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB45309))),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB45309), brightness: Brightness.dark),
      ),
      home: const TranslatePage(),
    );
  }
}

/// 翻译主页。
class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final FlMlKitTranslateText translator = FlMlKitTranslateText();
  final TextEditingController textController = TextEditingController();

  String? result;
  bool translating = false;
  bool autoDownload = true;
  bool wifiOnly = false;
  bool sourceDownloaded = false;
  bool targetDownloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await translator.getCurrentLanguage();
      await refreshModels();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const FlText('ML Kit 文本翻译', fontSize: 18),
        actions: <Widget>[
          IconButton(
            tooltip: '模型管理',
            onPressed: () async {
              await push(const ModelManagerPage());
              await refreshModels();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
      ),
      body: Universal(
        isScroll: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Universal(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            direction: Axis.horizontal,
            children: <Widget>[
              Expanded(
                child: _LanguageButton(
                  label: '源语言',
                  language: translator.sourceLanguage,
                  downloaded: sourceDownloaded,
                  onTap: () => selectLanguage(isSource: true),
                ),
              ),
              IconButton.filledTonal(onPressed: swapLanguage, icon: const Icon(Icons.swap_horiz)),
              Expanded(
                child: _LanguageButton(
                  label: '目标语言',
                  language: translator.targetLanguage,
                  downloaded: targetDownloaded,
                  onTap: () => selectLanguage(isSource: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: textController,
            maxLines: 6,
            minLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: '输入要翻译的文本',
              hintText: '例如：Hello, how are you?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const FlText('缺少模型时自动下载', fontSize: 14),
            value: autoDownload,
            onChanged: (bool value) => setState(() => autoDownload = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const FlText('仅在 WiFi 下下载模型', fontSize: 14),
            value: wifiOnly,
            onChanged: (bool value) => setState(() => wifiOnly = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: translating ? null : translate,
              icon: translating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.translate),
              label: Text(translating ? '翻译中...' : '翻译'),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(child: FlText('翻译结果', fontSize: 15, fontWeight: FontWeight.w600)),
                      if (result != null)
                        IconButton(
                          tooltip: '复制',
                          onPressed: () async {
                            await result!.toClipboard();
                            showToast('已复制到剪贴板');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    result ?? '暂无结果',
                    style: TextStyle(fontSize: 15, color: result == null ? colorScheme.outline : null),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FlText(
            '提示：首次翻译某个语言对时，需要下载源语言与目标语言模型。'
            'Android 的模型大小约 15MB，iOS 约 30MB，下载后可离线翻译。',
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  Future<void> refreshModels() async {
    final List<TranslateRemoteModel> models = await translator.getDownloadedModels();
    final Set<TranslateLanguage> languages = models
        .map((TranslateRemoteModel item) => item.language)
        .whereType<TranslateLanguage>()
        .toSet();
    sourceDownloaded = languages.contains(translator.sourceLanguage);
    targetDownloaded = languages.contains(translator.targetLanguage);
  }

  Future<void> selectLanguage({required bool isSource}) async {
    final TranslateLanguage? language = await showLanguagePicker(
      context,
      isSource ? translator.sourceLanguage : translator.targetLanguage,
    );
    if (language == null) return;
    if (language == translator.sourceLanguage || language == translator.targetLanguage) {
      showToast('源语言与目标语言不能相同');
      return;
    }
    final bool ok = isSource
        ? await translator.switchLanguage(language, translator.targetLanguage)
        : await translator.switchLanguage(translator.sourceLanguage, language);
    if (!ok) {
      showToast('切换语言失败');
      return;
    }
    await refreshModels();
    if (mounted) setState(() => result = null);
  }

  Future<void> swapLanguage() async {
    final bool ok = await translator.switchLanguage(translator.targetLanguage, translator.sourceLanguage);
    if (!ok) {
      showToast('切换语言失败');
      return;
    }
    await refreshModels();
    if (mounted) setState(() => result = null);
  }

  Future<void> translate() async {
    final String text = textController.text.trim();
    if (text.isEmpty) {
      showToast('请输入要翻译的文本');
      return;
    }
    setState(() => translating = true);
    final String? value = await translator.translate(text, downloadModelIfNeeded: autoDownload, requireWifi: wifiOnly);
    if (!mounted) return;
    setState(() => translating = false);
    if (value == null) {
      showToast('翻译失败，请先在模型管理中下载所需的语言模型');
      return;
    }
    setState(() => result = value);
    await refreshModels();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    textController.dispose();
    translator.dispose();
    super.dispose();
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.label, required this.language, required this.downloaded, required this.onTap});

  final String label;
  final TranslateLanguage language;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            FlText(label, fontSize: 11),
            const SizedBox(height: 4),
            FlText(languageLabel(language), fontSize: 16, fontWeight: FontWeight.w600),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  downloaded ? Icons.check_circle : Icons.downloading,
                  size: 12,
                  color: downloaded ? Colors.green : colorScheme.outline,
                ),
                const SizedBox(width: 4),
                FlText(downloaded ? '模型已下载' : '模型未下载', fontSize: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
