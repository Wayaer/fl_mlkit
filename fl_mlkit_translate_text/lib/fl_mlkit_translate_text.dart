import 'dart:async';

import 'package:flutter/services.dart';

class FlMlKitTranslateText {
  factory FlMlKitTranslateText() => _singleton ??= FlMlKitTranslateText._();

  FlMlKitTranslateText._();

  static const MethodChannel _channel =
      MethodChannel('fl_mlkit_translate_text');

  static FlMlKitTranslateText? _singleton;

  TranslateLanguage _sourceLanguage = TranslateLanguage.english;

  /// Source language
  TranslateLanguage get sourceLanguage => _sourceLanguage;

  TranslateLanguage _targetLanguage = TranslateLanguage.chinese;

  /// Target language
  TranslateLanguage get targetLanguage => _targetLanguage;

  /// translation
  /// [downloadModelIfNeeded] The model will be downloaded if needed
  Future<String?> translate(String text,
      {bool downloadModelIfNeeded = false}) async {
    if (text.isEmpty) return null;
    return await _channel.invokeMethod<String?>('translate',
        {'text': text, 'downloadModelIfNeeded': downloadModelIfNeeded});
  }

  /// Switching translation languages
  Future<bool> switchLanguage(
      TranslateLanguage source, TranslateLanguage target) async {
    bool? state = await _channel.invokeMethod<bool?>('switchLanguage',
        {'source': toAbbreviations(source), 'target': toAbbreviations(target)});
    if (state == true) {
      _sourceLanguage = source;
      _targetLanguage = target;
    }
    getCurrentLanguage();
    return state ?? false;
  }

  /// Get current language
  Future<void> getCurrentLanguage() async {
    final Map<dynamic, dynamic>? map =
        await _channel.invokeMapMethod('getCurrentLanguage');
    if (map != null) {
      _sourceLanguage = toTranslateLanguage(map['source'])!;
      _targetLanguage = toTranslateLanguage(map['target'])!;
    }
  }

  /// Get downloaded models
  Future<List<TranslateRemoteModel>> getDownloadedModels() async {
    final List<dynamic>? list =
        await _channel.invokeListMethod('getDownloadedModels');
    return list != null
        ? List<TranslateRemoteModel>.unmodifiable(
            list.map<dynamic>((dynamic e) => TranslateRemoteModel.fromMap(e)))
        : [];
  }

  /// Downloaded model
  Future<bool> downloadedModel(TranslateLanguage language) async {
    final bool? state = await _channel.invokeMethod(
        'downloadedModel', toAbbreviations(language));
    return state ?? false;
  }

  /// Delete downloaded model
  Future<bool> deleteDownloadedModel(TranslateLanguage language) async {
    final bool? state = await _channel.invokeMethod(
        'deleteDownloadedModel', toAbbreviations(language));
    return state ?? false;
  }

  /// Whether downloaded model
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    final bool? state = await _channel.invokeMethod(
        'isModelDownloaded', toAbbreviations(language));
    return state ?? false;
  }

  /// Be sure to call this method when you no longer use translation
  Future<bool> dispose() async {
    bool? state = await _channel.invokeMethod('dispose');
    return state ?? false;
  }

  /// Convert to Abbreviations
  String toAbbreviations(TranslateLanguage language) {
    late String abbreviations;
    for (int i = 0; i < allLanguage.length; i++) {
      var element = allLanguage.values.elementAt(i);
      if (element == language) {
        abbreviations = allLanguage.keys.elementAt(i);
        break;
      }
    }
    return abbreviations;
  }

  /// Convert to TranslateLanguage enum
  TranslateLanguage? toTranslateLanguage(String language) {
    TranslateLanguage? translateLanguage;
    for (var element in allLanguage.keys) {
      if (element == language) {
        translateLanguage = allLanguage[element]!;
        break;
      }
    }
    return translateLanguage;
  }

  Map<String, TranslateLanguage> get allLanguage => {
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
}

class TranslateRemoteModel {
  TranslateRemoteModel.fromMap(Map<dynamic, dynamic> data)
      : language = FlMlKitTranslateText()
            .toTranslateLanguage(data['language'] as String)!,
        modelType = _toTranslateRemoteModelType(data['modelType'] as String?),
        isBaseModel = data['isBaseModel'] as bool?;

  /// Translate language
  late TranslateLanguage language;

  /// Null on Android
  bool? isBaseModel;

  /// Null on Android
  TranslateRemoteModelType? modelType;
}

TranslateRemoteModelType _toTranslateRemoteModelType(String? type) {
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
      return TranslateRemoteModelType.entityextraction;
    case 'CUSTOM':
      return TranslateRemoteModelType.custom;
    case 'DIGITAL_INK':
      return TranslateRemoteModelType.digitalink;
  }
  return TranslateRemoteModelType.unknown;
}

/// Android TranslateRemoteModel Type
enum TranslateRemoteModelType {
  unknown,
  base,
  automl,
  translate,
  entityextraction,
  custom,
  digitalink,
}

/// Translate Language
enum TranslateLanguage {
  afrikaans,
  albanian,
  arabic,
  belarusian,
  bulgarian,
  bengali,
  catalan,
  chinese,
  croatian,
  czech,
  danish,
  dutch,
  english,
  esperanto,
  estonian,
  finnish,
  french,
  galician,
  georgian,
  german,
  greek,
  gujarati,
  haitianCreole,
  hebrew,
  hindi,
  hungarian,
  icelandic,
  indonesian,
  irish,
  italian,
  japanese,
  kannada,
  korean,
  lithuanian,
  latvian,
  macedonian,
  marathi,
  malay,
  maltese,
  norwegian,
  persian,
  polish,
  portuguese,
  romanian,
  russian,
  slovak,
  slovenian,
  spanish,
  swedish,
  swahili,
  tagalog,
  tamil,
  telugu,
  thai,
  turkish,
  ukrainian,
  urdu,
  vietnamese,
  welsh,
}
