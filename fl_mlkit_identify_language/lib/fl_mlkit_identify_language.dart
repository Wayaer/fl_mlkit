import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google ML Kit 语言识别。
///
/// 可以识别一段文本最可能的语言，也可以返回所有可能语言及其置信度。
/// 支持的语言列表见
/// [官方文档](https://developers.google.com/ml-kit/language/identification/langid-support)。
///
/// ```dart
/// final identifier = FlMlKitIdentifyLanguage();
/// final language = await identifier.identifyLanguage('Hello world');
/// final possible = await identifier.identifyPossibleLanguages('Hello world');
/// ```
class FlMlKitIdentifyLanguage {
  factory FlMlKitIdentifyLanguage() => _instance;

  FlMlKitIdentifyLanguage._();

  static final FlMlKitIdentifyLanguage _instance = FlMlKitIdentifyLanguage._();

  /// 全局单例。
  static FlMlKitIdentifyLanguage get instance => _instance;

  final MethodChannel _channel = const MethodChannel('fl_mlkit_identify_language');

  double _confidence = 0.5;

  /// 当前置信度阈值，取值范围 0.01 ~ 1。
  double get confidence => _confidence;

  /// 识别文本最可能的语言。
  ///
  /// 返回的 [IdentifiedLanguageModel.languageTag] 为 BCP-47 语言代码；
  /// 如果没有足够置信度的语言，返回 `und`（undetermined）。
  /// 因为原生接口只返回语言代码，[IdentifiedLanguageModel.confidence] 为
  /// 当前使用的置信度阈值 [confidence]，真实置信度请使用
  /// [identifyPossibleLanguages]。
  /// 识别失败时返回 null。
  Future<IdentifiedLanguageModel?> identifyLanguage(String text) async {
    if (!_supportPlatform || text.isEmpty) return null;
    try {
      final String? tag = await _channel.invokeMethod<String>('identifyLanguage', text);
      if (tag == null) return null;
      return IdentifiedLanguageModel(languageTag: tag, confidence: _confidence);
    } on PlatformException catch (error) {
      debugPrint('identifyLanguage error: $error');
      return null;
    }
  }

  /// 识别文本可能的语言，按置信度从高到低排序。
  ///
  /// 识别失败或没有结果时返回空列表。
  Future<List<IdentifiedLanguageModel>> identifyPossibleLanguages(String text) async {
    if (!_supportPlatform || text.isEmpty) return <IdentifiedLanguageModel>[];
    try {
      final List<Map<dynamic, dynamic>>? list = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'identifyPossibleLanguages',
        text,
      );
      if (list == null) return <IdentifiedLanguageModel>[];
      return List<IdentifiedLanguageModel>.unmodifiable(
        list.map<IdentifiedLanguageModel>((Map<dynamic, dynamic> item) => IdentifiedLanguageModel.fromMap(item)),
      );
    } on PlatformException catch (error) {
      debugPrint('identifyPossibleLanguages error: $error');
      return <IdentifiedLanguageModel>[];
    }
  }

  /// 设置置信度阈值，取值范围 0.01 ~ 1。
  ///
  /// 超出范围时不做任何设置并返回 false；设置成功后原生会重建识别器。
  Future<bool> setConfidence(double confidence) async {
    if (!_supportPlatform || confidence < 0.01 || confidence > 1) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('setConfidence', confidence);
      if (state == true) _confidence = confidence;
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('setConfidence error: $error');
      return false;
    }
  }

  /// 读取原生当前的置信度阈值。
  Future<double> getCurrentConfidence() async {
    if (!_supportPlatform) return _confidence;
    try {
      final double? confidence = await _channel.invokeMethod<double>('getCurrentConfidence');
      if (confidence != null) _confidence = confidence;
    } on PlatformException catch (error) {
      debugPrint('getCurrentConfidence error: $error');
    }
    return _confidence;
  }

  /// 释放原生识别器。
  ///
  /// 之后仍可继续调用识别方法，会重新创建识别器。
  Future<bool> dispose() async {
    if (!_supportPlatform) return false;
    try {
      final bool? state = await _channel.invokeMethod<bool>('dispose');
      return state ?? false;
    } on PlatformException catch (error) {
      debugPrint('identify dispose error: $error');
      return false;
    }
  }

  bool get _supportPlatform {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return true;
    }
    debugPrint('Not support platform for $defaultTargetPlatform');
    return false;
  }
}

/// 语言识别结果。
class IdentifiedLanguageModel {
  /// 创建语言识别结果。
  const IdentifiedLanguageModel({required this.languageTag, required this.confidence});

  /// 从原生返回的 Map 创建识别结果。
  IdentifiedLanguageModel.fromMap(Map<dynamic, dynamic> data)
    : languageTag = data['languageTag'] as String? ?? 'und',
      confidence = (data['confidence'] as num?)?.toDouble() ?? 0;

  /// BCP-47 语言代码，例如 `en`、`zh`；无法确定时为 `und`。
  final String languageTag;

  /// 置信度，0 ~ 1。
  ///
  /// [FlMlKitIdentifyLanguage.identifyLanguage] 返回的是当前置信度阈值，
  /// [FlMlKitIdentifyLanguage.identifyPossibleLanguages] 返回的是真实置信度。
  final double confidence;

  @override
  String toString() => 'IdentifiedLanguageModel(languageTag: $languageTag, confidence: $confidence)';
}
