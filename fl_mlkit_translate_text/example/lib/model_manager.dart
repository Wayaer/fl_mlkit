import 'package:example/language_picker.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_translate_text/fl_mlkit_translate_text.dart';
import 'package:flutter/material.dart';

/// 翻译模型管理页。
class ModelManagerPage extends StatefulWidget {
  const ModelManagerPage({super.key});

  @override
  State<ModelManagerPage> createState() => _ModelManagerPageState();
}

class _ModelManagerPageState extends State<ModelManagerPage> {
  final FlMlKitTranslateText translator = FlMlKitTranslateText();
  final TextEditingController searchController = TextEditingController();

  final Map<TranslateLanguage, TranslateRemoteModel> downloaded = <TranslateLanguage, TranslateRemoteModel>{};
  final Set<TranslateLanguage> loading = <TranslateLanguage>{};
  String query = '';
  bool wifiOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadModels());
  }

  @override
  Widget build(BuildContext context) {
    final List<TranslateLanguage> languages = TranslateLanguage.values
        .where(
          (TranslateLanguage item) =>
              query.isEmpty ||
              languageLabel(item).toLowerCase().contains(query.toLowerCase()) ||
              translator.toAbbreviations(item).contains(query.toLowerCase()),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const FlText('翻译模型管理', fontSize: 18),
        actions: <Widget>[IconButton(onPressed: loadModels, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '搜索语言或语言代码',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (String value) => setState(() => query = value.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FlText('已下载 ${downloaded.length} / ${TranslateLanguage.values.length} 个模型', fontSize: 12),
                ),
                const FlText('仅 WiFi', fontSize: 12),
                Switch(value: wifiOnly, onChanged: (bool value) => setState(() => wifiOnly = value)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadModels,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: languages.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final TranslateLanguage language = languages[index];
                  final TranslateRemoteModel? model = downloaded[language];
                  final bool isLoading = loading.contains(language);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: model != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(model != null ? Icons.offline_bolt : Icons.cloud_download_outlined, size: 18),
                    ),
                    title: FlText(languageLabel(language), fontSize: 14),
                    subtitle: FlText(_modelSubtitle(language, model), fontSize: 11),
                    trailing: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : model != null
                        ? TextButton(onPressed: () => deleteModel(language), child: const Text('删除'))
                        : TextButton(onPressed: () => downloadModel(language), child: const Text('下载')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _modelSubtitle(TranslateLanguage language, TranslateRemoteModel? model) {
    final String code = translator.toAbbreviations(language);
    if (model == null) return '$code · 未下载';
    final String type = model.modelType?.name ?? 'translate';
    final String base = model.isBaseModel == true ? ' · 基础模型' : '';
    return '$code · 已下载 · $type$base';
  }

  Future<void> loadModels() async {
    final List<TranslateRemoteModel> models = await translator.getDownloadedModels();
    if (!mounted) return;
    setState(() {
      downloaded
        ..clear()
        ..addEntries(
          models
              .where((TranslateRemoteModel item) => item.language != null)
              .map(
                (TranslateRemoteModel item) => MapEntry<TranslateLanguage, TranslateRemoteModel>(item.language!, item),
              ),
        );
    });
  }

  Future<void> downloadModel(TranslateLanguage language) async {
    setState(() => loading.add(language));
    final bool ok = await translator.downloadedModel(language, requireWifi: wifiOnly);
    if (!mounted) return;
    setState(() => loading.remove(language));
    showToast(ok ? '${languageLabel(language)} 模型下载完成' : '下载失败，请检查网络');
    if (ok) await loadModels();
  }

  Future<void> deleteModel(TranslateLanguage language) async {
    setState(() => loading.add(language));
    final bool ok = await translator.deleteDownloadedModel(language);
    if (!mounted) return;
    setState(() => loading.remove(language));
    showToast(ok ? '${languageLabel(language)} 模型已删除' : '删除失败');
    if (ok) await loadModels();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
