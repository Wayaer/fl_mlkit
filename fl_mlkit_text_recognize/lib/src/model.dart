part of '../fl_mlkit_text_recognize.dart';

class AnalysisTextModel {
  AnalysisTextModel.fromMap(Map<dynamic, dynamic> data)
      : text = data['text'] as String?,
        textBlocks = _getTextBlocks(data['textBlocks'] as List<dynamic>?),
        height = data['height'] as double?,
        width = data['width'] as double?;

  /// The coordinate points of [corners] and the boundary line of [boundingbox] are
  /// based on width and height
  /// If you need to display the bar code rectangle and coordinate points,
  /// you must calculate it yourself and determine whether it is a full screen preview
  /// The height of the image from which the barcode is currently parsed
  /// The position of the barcode is converted to the screen by high
  double? height;

  /// The width of the image from which the barcode is currently parsed
  /// The position of the barcode is converted to the screen by width
  double? width;

  //// Retrieves all the recognized text in the image.
  String? text;

  /// Gets an unmodifiable list of Text.TextBlock, which is a block of text and can be further decomposed to a list of Text.Line.
  List<TextBlock>? textBlocks;
}

class TextBlock extends TextElement {
  TextBlock.fromMap(Map<dynamic, dynamic> data) {
    lines = _getTextLines(data['lines'] as List<dynamic>?);
    text = data['text'] as String?;
    recognizedLanguage = data['recognizedLanguage'] as String?;
    recognizedLanguages =
        _getRecognizedLanguages(data['recognizedLanguages'] as List<dynamic>?);
    boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?);
    corners = _getCorners(data['corners'] as List<dynamic>?);
  }

  /// Gets an unmodifiable list of Lines that make up this text block.
  List<TextLine>? lines;

  List<TextLine>? _getTextLines(List<dynamic>? data) => data != null
      ? List<TextLine>.unmodifiable(data.map<dynamic>(
          (dynamic e) => TextLine.fromMap(e as Map<dynamic, dynamic>)))
      : null;
}

class TextLine extends TextElement {
  TextLine.fromMap(Map<dynamic, dynamic> data) {
    elements = _getTextElement(data['elements'] as List<dynamic>?);
    text = data['text'] as String?;
    recognizedLanguage = data['recognizedLanguage'] as String?;
    recognizedLanguages =
        _getRecognizedLanguages(data['recognizedLanguages'] as List<dynamic>?);
    boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?);
    corners = _getCorners(data['corners'] as List<dynamic>?);
  }

  /// Gets a unmodifiable list of Elements that make up this text line.
  List<TextElement>? elements;

  List<TextElement>? _getTextElement(List<dynamic>? data) => data != null
      ? List<TextElement>.unmodifiable(data.map<dynamic>(
          (dynamic e) => TextElement.fromMap(e as Map<dynamic, dynamic>)))
      : null;
}

class TextElement {
  TextElement({
    this.text,
    this.recognizedLanguage,
    this.boundingBox,
    this.corners,
  });

  TextElement.fromMap(Map<dynamic, dynamic> data)
      : text = data['text'] as String?,
        recognizedLanguage = data['recognizedLanguage'] as String?,
        recognizedLanguages = _getRecognizedLanguages(
            data['recognizedLanguages'] as List<dynamic>?),
        boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?),
        corners = _getCorners(data['corners'] as List<dynamic>?);

  /// Gets the recognized text in the [TextElement]、[TextLine]、[TextBlock].
  String? text;

  /// Gets prevailing language in the text, if any.
  /// There is data only on Android
  String? recognizedLanguage;

  /// Detected language from text recognition.
  /// The ISO 639-1 two-letter language code if that is defined (e.g. “en”), or else the ISO 639-2 three-letter code if that is defined, or else a Google-specific code.
  /// There is data only on IOS
  /// There is data only in block and lines, and element is null
  List<String>? recognizedLanguages;

  /// Returns the axis-aligned bounding rectangle of the detected text.
  Rect? boundingBox;

  /// Gets the four corner points in clockwise direction starting with top-left.
  List<Offset>? corners;
}

List<String>? _getRecognizedLanguages(List<dynamic>? data) => data != null
    ? List<String>.unmodifiable(data.map<dynamic>((dynamic e) => e as String))
    : null;

List<TextBlock>? _getTextBlocks(List<dynamic>? data) => data != null
    ? List<TextBlock>.unmodifiable(data.map<dynamic>(
        (dynamic e) => TextBlock.fromMap(e as Map<dynamic, dynamic>)))
    : null;

List<Offset>? _getCorners(List<dynamic>? data) => data != null
    ? List<Offset>.unmodifiable(data.map<dynamic>(
        (dynamic e) => Offset(e['x'] as double? ?? 0, e['y'] as double? ?? 0)))
    : null;

Rect? _getRect(Map<dynamic, dynamic>? data) {
  if (data == null) {
    return null;
  } else {
    if (_isAndroid) {
      final int left = (data['left'] as int?) ?? 0;
      final int top = (data['top'] as int?) ?? 0;
      final int right = (data['right'] as int?) ?? 0;
      final int bottom = (data['bottom'] as int?) ?? 0;
      return Rect.fromLTRB(
          left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
    } else if (_isIOS) {
      final double x = (data['x'] as double?) ?? 0;
      final double y = (data['y'] as double?) ?? 0;
      final double width = (data['width'] as double?) ?? 0;
      final double height = (data['height'] as double?) ?? 0;
      return Rect.fromPoints(Offset(x, y), Offset(x + width, y + height));
    }
  }
  return null;
}
