import 'dart:async';

import 'package:flutter/services.dart';

class FlMlKitIdentifyLanguage {
  factory FlMlKitIdentifyLanguage() =>
      _singleton ??= FlMlKitIdentifyLanguage._();

  FlMlKitIdentifyLanguage._();

  static const MethodChannel _channel = MethodChannel(
    'fl_mlkit_identify_language',
  );

  static FlMlKitIdentifyLanguage? _singleton;

  double _confidence = 0.5;

  double get confidence => _confidence;

  /// Identify language
  Future<IdentifiedLanguageModel?> identifyLanguage(String text) async {
    final tag = await _channel.invokeMethod<String>('identifyLanguage', text);
    if (tag != null) {
      return IdentifiedLanguageModel(confidence: _confidence, languageTag: tag);
    }
    return null;
  }

  /// Identify possible languages
  Future<List<IdentifiedLanguageModel>> identifyPossibleLanguages(
      String text) async {
    final list = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'identifyPossibleLanguages', text);
    if (list != null && list.isNotEmpty) {
      return list.map((data) => IdentifiedLanguageModel.fromMap(data)).toList();
    }
    return [];
  }

  /// Set confidence
  Future<bool> setConfidence(double confidence) async {
    assert(confidence >= 0.01 && confidence <= 1);
    final state =
        await _channel.invokeMethod<bool>('setConfidence', confidence);
    if (state == true) _confidence = confidence;
    return state ?? false;
  }

  /// Get native confidence
  Future<double> getCurrentConfidence() async {
    final confidence =
        await _channel.invokeMethod<double>('getCurrentConfidence');
    if (confidence != null) _confidence = confidence;
    return confidence ?? _confidence;
  }

  /// Be sure to call this method when you are no longer using a collapsible
  Future<bool> dispose(double confidence) async =>
      (await _channel.invokeMethod<bool>('dispose')) ?? false;
}

class IdentifiedLanguageModel {
  IdentifiedLanguageModel({
    required this.languageTag,
    required this.confidence,
  });

  IdentifiedLanguageModel.fromMap(Map<dynamic, dynamic> data)
      : languageTag = data['languageTag'] as String,
        confidence = data['confidence'] as double;

  /// If the call succeeds, a BCP-47 language code(https://en.wikipedia.org/wiki/IETF_language_tag) is passed to the success listener,
  /// indicating the language of the text. If no language is confidently detected,
  /// the code und (undetermined) is passed.
  String languageTag;

  /// Identified confidence
  double confidence;
}
