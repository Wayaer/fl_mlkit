part of '../fl_mlkit_text_recognize.dart';

/// 一次文字识别的结果。
///
/// [width] / [height] 为识别原图的宽高（单位像素），
/// [textBlocks] 中所有坐标都基于该尺寸。
class AnalysisTextModel {
  /// 从原生返回的 Map 创建结果。
  AnalysisTextModel.fromMap(Map<dynamic, dynamic> data)
    : text = data['text'] as String?,
      textBlocks = _getTextBlocks(data['textBlocks'] as List<dynamic>?),
      height = (data['height'] as num?)?.toDouble(),
      width = (data['width'] as num?)?.toDouble();

  /// 识别原图的宽度（像素）。
  final double? width;

  /// 识别原图的高度（像素）。
  final double? height;

  /// 图片中识别到的全部文字。
  final String? text;

  /// 按段落划分的文字块。
  final List<TextBlock>? textBlocks;

  /// 文字块列表，空值安全版本。
  List<TextBlock> get blockList => textBlocks ?? const <TextBlock>[];

  /// 是否没有识别到任何文字。
  bool get isEmpty => (text ?? '').isEmpty;

  @override
  String toString() => 'AnalysisTextModel(width: $width, height: $height, text: $text)';
}

/// 文字块，通常对应一个段落。
class TextBlock extends TextElement {
  /// 从原生返回的 Map 创建文字块。
  TextBlock.fromMap(super.data) : lines = _getTextLines(data['lines'] as List<dynamic>?), super.fromMap();

  /// 组成该文字块的行。
  final List<TextLine>? lines;

  /// 行列表，空值安全版本。
  List<TextLine> get lineList => lines ?? const <TextLine>[];
}

/// 文字行。
class TextLine extends TextElement {
  /// 从原生返回的 Map 创建文字行。
  TextLine.fromMap(super.data) : elements = _getTextElements(data['elements'] as List<dynamic>?), super.fromMap();

  /// 组成该行的元素（通常是一个单词）。
  final List<TextElement>? elements;

  /// 元素列表，空值安全版本。
  List<TextElement> get elementList => elements ?? const <TextElement>[];
}

/// 文字元素，可表示块、行或词。
class TextElement {
  /// 创建文字元素。
  const TextElement({this.text, this.recognizedLanguage, this.recognizedLanguages, this.boundingBox, this.corners});

  /// 从原生返回的 Map 创建文字元素。
  TextElement.fromMap(Map<dynamic, dynamic> data)
    : text = data['text'] as String?,
      recognizedLanguage = data['recognizedLanguage'] as String?,
      recognizedLanguages = _getRecognizedLanguages(data['recognizedLanguages'] as List<dynamic>?),
      boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?),
      corners = _getCorners(data['corners'] as List<dynamic>?);

  /// 识别出的文字。
  final String? text;

  /// 当前文字的主要语言，仅 Android 返回。
  final String? recognizedLanguage;

  /// 识别到的语言列表，仅 iOS 返回，且仅块与行包含该字段。
  final List<String>? recognizedLanguages;

  /// 文字区域的轴对齐外接矩形。
  final Rect? boundingBox;

  /// 文字区域的四个角点，按顺时针方向从左上角开始。
  final List<Offset>? corners;

  @override
  String toString() => 'TextElement(text: $text, boundingBox: $boundingBox)';
}

List<String>? _getRecognizedLanguages(List<dynamic>? data) =>
    data != null ? List<String>.unmodifiable(data.map<String>((dynamic e) => e as String)) : null;

List<TextBlock>? _getTextBlocks(List<dynamic>? data) => data != null
    ? List<TextBlock>.unmodifiable(data.map<TextBlock>((dynamic e) => TextBlock.fromMap(e as Map<dynamic, dynamic>)))
    : null;

List<TextLine>? _getTextLines(List<dynamic>? data) => data != null
    ? List<TextLine>.unmodifiable(data.map<TextLine>((dynamic e) => TextLine.fromMap(e as Map<dynamic, dynamic>)))
    : null;

List<TextElement>? _getTextElements(List<dynamic>? data) => data != null
    ? List<TextElement>.unmodifiable(
        data.map<TextElement>((dynamic e) => TextElement.fromMap(e as Map<dynamic, dynamic>)),
      )
    : null;

List<Offset>? _getCorners(List<dynamic>? data) => data != null
    ? List<Offset>.unmodifiable(
        data.map<Offset>((dynamic e) {
          final Map<dynamic, dynamic> corner = e as Map<dynamic, dynamic>;
          return Offset((corner['x'] as num?)?.toDouble() ?? 0, (corner['y'] as num?)?.toDouble() ?? 0);
        }),
      )
    : null;

Rect? _getRect(Map<dynamic, dynamic>? data) {
  if (data == null) return null;
  if (_isAndroid) {
    final int left = (data['left'] as num?)?.toInt() ?? 0;
    final int top = (data['top'] as num?)?.toInt() ?? 0;
    final int right = (data['right'] as num?)?.toInt() ?? 0;
    final int bottom = (data['bottom'] as num?)?.toInt() ?? 0;
    return Rect.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }
  if (_isIOS) {
    final double x = (data['x'] as num?)?.toDouble() ?? 0;
    final double y = (data['y'] as num?)?.toDouble() ?? 0;
    final double width = (data['width'] as num?)?.toDouble() ?? 0;
    final double height = (data['height'] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(x, y, width, height);
  }
  return null;
}
