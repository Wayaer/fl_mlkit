import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google ML Kit 端侧文本翻译。
///
/// 翻译模型按语言对下载，首次使用前可通过 [downloadedModel] 下载，
/// 或在 [translate] 时传入 `downloadModelIfNeeded: true` 让原生自动下载。
///
/// ```dart
/// final translator = FlMlKitTranslateText();
/// await translator.switchLanguage(TranslateLanguage.english, TranslateLanguage.chinese);
/// final result = await translator.translate('Hello', downloadModelIfNeeded: true);
/// ```
class FlMlKitTranslateText {
  factory FlMlKitTranslateText() => _instance;

  FlMlKitTranslateText._();

  static final FlMlKitTranslateText _instance = FlMlKitTranslateText._();

  /// 全局单例。
  static FlMlKitTranslateText get instance => _instance;

  final MethodChannel _channel = const MethodChannel('fl_mlkit_translate_text');

  /// 语言与 BCP-47 语言代码的映射。
  static const Map<String, TranslateLanguage> _languageTags = <String, TranslateLanguage>{
    'af': TranslateLanguage.afrikaans,
    'sq': TranslateLanguage.albanian,
    'ar': TranslateLanguage.arabic,
    'be': TranslateLanguage.belarusian,
    'bg': TranslateLanguage.bulgarian,
    'bn': TranslateLanguage.bengali,
    'ca': TranslateLanguage.catalan,
    'zh': TranslateLanguage.chinese,
    'hr': TranslateLanguage.croatian,
    'cs': TranslateLanguage.czech,
    'da': TranslateLanguage.danish,
    'nl': TranslateLanguage.dutch,
    'en': TranslateLanguage.english,
    'eo': TranslateLanguage.esperanto,
    'et': TranslateLanguage.estonian,
    'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,
    'gl': TranslateLanguage.galician,
    'ka': TranslateLanguage.georgian,
    'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,
    'gu': TranslateLanguage.gujarati,
    'ht': TranslateLanguage.haitianCreole,
    'he': TranslateLanguage.hebrew,
    'hi': TranslateLanguage.hindi,
    'hu': TranslateLanguage.hungarian,
    'is': TranslateLanguage.icelandic,
    'id': TranslateLanguage.indonesian,
    'ga': TranslateLanguage.irish,
    'it': TranslateLanguage.italian,
    'ja': TranslateLanguage.japanese,
    'kn': TranslateLanguage.kannada,
    'ko': TranslateLanguage.korean,
    'lt': TranslateLanguage.lithuanian,
    'lv': TranslateLanguage.latvian,
    'mk': TranslateLanguage.macedonian,
    'mr': TranslateLanguage.marathi,
    'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,
    'no': TranslateLanguage.norwegian,
    'fa': TranslateLanguage.persian,
    'pl': TranslateLanguage.polish,
    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,
    'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,
    'sl': TranslateLanguage.slovenian,
    'es': TranslateLanguage.spanish,
    'sv': TranslateLanguage.swedish,
    'sw': TranslateLanguage.swahili,
    'tl': TranslateLanguage.tagalog,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,
    'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian,
    'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,
    'cy': TranslateLanguage.welsh,
  };

  static final Map<TranslateLanguage, String> _abbreviations = <TranslateLanguage, String>{
    for (final MapEntry<String, TranslateLanguage> entry in _languageTags.entries) entry.value: entry.key,
  };

  TranslateLanguage _sourceLanguage = TranslateLanguage.english;

  /// 当前源语言。
  TranslateLanguage get sourceLanguage => _sourceLanguage;

  TranslateLanguage _targetLanguage = TranslateLanguage.chinese;

  /// 当前目标语言。
  TranslateLanguage get targetLanguage => _targetLanguage;

  /// 翻译文本。
  ///
  /// [text] 为空时直接返回 null；
  /// [downloadModelIfNeeded] 为 true 时，缺少模型会自动下载；
  /// [requireWifi] 为 true 时，仅在 WiFi 下下载模型。
  /// 翻译失败（例如模型缺失）返回 null。
  Future<String?> translate(String text, {bool downloadModelIfNeeded = false, bool requireWifi = false}) async {
    if (!_supportPlatform || text.isEmpty) return null;
    try {
      return await _channel.invokeMethod<String>('translate', <String, dynamic>{
        'text': text,
        'downloadModelIfNeeded': downloadModelIfNeeded,
        'requireWifi': requireWifi,
      });
    } on PlatformException catch (error) {
      debugPrint('translate error: $error');
      return null;
    }
  }

  /// 切换翻译语言。
  ///
  /// 源语言与目标语言相同时无法翻译，直接返回 false。
  /// 切换后原生会释放旧的翻译器，下次 [translate] 重新创建。
  Future<bool> switchLanguage(TranslateLanguage source, TranslateLanguage target) async {
    if (!_supportPlatform || source == target) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('switchLanguage', <String, dynamic>{
        'source': toAbbreviations(source),
        'target': toAbbreviations(target),
      });
      if (state == true) {
        _sourceLanguage = source;
        _targetLanguage = target;
      }
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('switchLanguage error: $error');
      return false;
    }
  }

  /// 从原生同步当前源语言与目标语言。
  Future<void> getCurrentLanguage() async {
    if (!_supportPlatform) return;
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMapMethod<dynamic, dynamic>('getCurrentLanguage');
      if (map == null) return;
      final TranslateLanguage? source = toTranslateLanguage(map['source'] as String?);
      final TranslateLanguage? target = toTranslateLanguage(map['target'] as String?);
      if (source != null) _sourceLanguage = source;
      if (target != null) _targetLanguage = target;
    } on PlatformException catch (error) {
      debugPrint('getCurrentLanguage error: $error');
    }
  }

  /// 获取已下载的翻译模型列表。
  Future<List<TranslateRemoteModel>> getDownloadedModels() async {
    if (!_supportPlatform) return <TranslateRemoteModel>[];
    try {
      final List<dynamic>? list = await _channel.invokeListMethod<dynamic>('getDownloadedModels');
      if (list == null) return <TranslateRemoteModel>[];
      return List<TranslateRemoteModel>.unmodifiable(
        list
            .map<TranslateRemoteModel?>((dynamic item) => TranslateRemoteModel.fromMap(item as Map<dynamic, dynamic>))
            .whereType<TranslateRemoteModel>()
            .where((TranslateRemoteModel model) => model.language != null),
      );
    } on PlatformException catch (error) {
      debugPrint('getDownloadedModels error: $error');
      return <TranslateRemoteModel>[];
    }
  }

  /// 下载指定语言的翻译模型。
  ///
  /// [requireWifi] 为 true 时仅在 WiFi 下下载。下载失败返回 false。
  Future<bool> downloadedModel(TranslateLanguage language, {bool requireWifi = false}) async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('downloadedModel', <String, dynamic>{
        'language': toAbbreviations(language),
        'requireWifi': requireWifi,
      });
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('downloadedModel error: $error');
      return false;
    }
  }

  /// 删除指定语言的翻译模型。
  Future<bool> deleteDownloadedModel(TranslateLanguage language) async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('deleteDownloadedModel', toAbbreviations(language));
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('deleteDownloadedModel error: $error');
      return false;
    }
  }

  /// 判断指定语言的翻译模型是否已下载。
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('isModelDownloaded', toAbbreviations(language));
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('isModelDownloaded error: $error');
      return false;
    }
  }

  /// 释放翻译器与模型管理器。
  ///
  /// 不再使用翻译能力时调用，之后仍可重新调用其它方法继续使用。
  Future<bool> dispose() async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('dispose');
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('translate dispose error: $error');
      return false;
    }
  }

  /// 把 [TranslateLanguage] 转换为语言代码，例如 `zh`。
  String toAbbreviations(TranslateLanguage language) => _abbreviations[language]!;

  /// 把语言代码转换为 [TranslateLanguage]，未知代码返回 null。
  TranslateLanguage? toTranslateLanguage(String? language) {
    if (language == null) return null;
    return _languageTags[language];
  }

  /// 全部语言及语言代码的映射。
  Map<String, TranslateLanguage> get allLanguage => _languageTags;

  bool get _supportPlatform {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return true;
    }
    debugPrint('Not support platform for $defaultTargetPlatform');
    return false;
  }
}

/// 已下载或可下载的翻译模型。
class TranslateRemoteModel {
  /// 从原生返回的 Map 创建模型信息。
  TranslateRemoteModel.fromMap(Map<dynamic, dynamic> data)
    : language = FlMlKitTranslateText().toTranslateLanguage(data['language'] as String?),
      modelType = TranslateRemoteModel._toTranslateRemoteModelType(data['modelType'] as String?),
      isBaseModel = data['isBaseModel'] as bool?;

  /// 模型对应的语言，未知语言为 null。
  final TranslateLanguage? language;

  /// 是否为基础模型，仅 Android 返回。
  final bool? isBaseModel;

  /// 模型类型，仅 Android 返回，iOS 为 null。
  final TranslateRemoteModelType? modelType;

  @override
  String toString() =>
      'TranslateRemoteModel(language: ${language?.name}, isBaseModel: $isBaseModel, modelType: $modelType)';

  static TranslateRemoteModelType? _toTranslateRemoteModelType(String? type) {
    switch (type) {
      case 'UNKNOWN':
        return TranslateRemoteModelType.unknown;
      case 'BASE':
        return TranslateRemoteModelType.base;
      case 'AUTOML':
        return TranslateRemoteModelType.automl;
      case 'TRANSLATE':
        return TranslateRemoteModelType.translate;
      case 'ENTITY_EXTRACTION':
        return TranslateRemoteModelType.entityExtraction;
      case 'CUSTOM':
        return TranslateRemoteModelType.custom;
      case 'DIGITAL_INK':
        return TranslateRemoteModelType.digitalInk;
      default:
        return null;
    }
  }
}

/// Android 端翻译模型类型。
enum TranslateRemoteModelType {
  /// 未知类型。
  unknown,

  /// 基础模型。
  base,

  /// AutoML 模型。
  automl,

  /// 翻译模型。
  translate,

  /// 实体抽取模型。
  entityExtraction,

  /// 自定义模型。
  custom,

  /// 数字墨水模型。
  digitalInk,
}

/// ML Kit 支持的翻译语言。
enum TranslateLanguage {
  /// 南非荷兰语
  afrikaans,

  /// 阿尔巴尼亚语
  albanian,

  /// 阿拉伯语
  arabic,

  /// 白俄罗斯语
  belarusian,

  /// 保加利亚语
  bulgarian,

  /// 孟加拉语
  bengali,

  /// 加泰罗尼亚语
  catalan,

  /// 中文
  chinese,

  /// 克罗地亚语
  croatian,

  /// 捷克语
  czech,

  /// 丹麦语
  danish,

  /// 荷兰语
  dutch,

  /// 英语
  english,

  /// 世界语
  esperanto,

  /// 爱沙尼亚语
  estonian,

  /// 芬兰语
  finnish,

  /// 法语
  french,

  /// 加利西亚语
  galician,

  /// 格鲁吉亚语
  georgian,

  /// 德语
  german,

  /// 希腊语
  greek,

  /// 古吉拉特语
  gujarati,

  /// 海地克里奥尔语
  haitianCreole,

  /// 希伯来语
  hebrew,

  /// 印地语
  hindi,

  /// 匈牙利语
  hungarian,

  /// 冰岛语
  icelandic,

  /// 印度尼西亚语
  indonesian,

  /// 爱尔兰语
  irish,

  /// 意大利语
  italian,

  /// 日语
  japanese,

  /// 卡纳达语
  kannada,

  /// 韩语
  korean,

  /// 立陶宛语
  lithuanian,

  /// 拉脱维亚语
  latvian,

  /// 马其顿语
  macedonian,

  /// 马拉地语
  marathi,

  /// 马来语
  malay,

  /// 马耳他语
  maltese,

  /// 挪威语
  norwegian,

  /// 波斯语
  persian,

  /// 波兰语
  polish,

  /// 葡萄牙语
  portuguese,

  /// 罗马尼亚语
  romanian,

  /// 俄语
  russian,

  /// 斯洛伐克语
  slovak,

  /// 斯洛文尼亚语
  slovenian,

  /// 西班牙语
  spanish,

  /// 瑞典语
  swedish,

  /// 斯瓦希里语
  swahili,

  /// 他加禄语
  tagalog,

  /// 泰米尔语
  tamil,

  /// 泰卢固语
  telugu,

  /// 泰语
  thai,

  /// 土耳其语
  turkish,

  /// 乌克兰语
  ukrainian,

  /// 乌尔都语
  urdu,

  /// 越南语
  vietnamese,

  /// 威尔士语
  welsh,
}
