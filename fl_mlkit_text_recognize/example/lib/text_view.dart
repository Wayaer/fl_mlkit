import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_text_recognize/fl_mlkit_text_recognize.dart';
import 'package:flutter/material.dart';

/// 在相机预览上绘制文字区域。
///
/// [previewSize] 为相机原图尺寸，[fit] 需与 FlMlKitTextRecognize 的 fit 保持一致。
class TextOverlay extends StatelessWidget {
  const TextOverlay({
    super.key,
    required this.model,
    required this.previewSize,
    this.fit = BoxFit.cover,
    this.showBlocks = true,
    this.showLines = false,
    this.showElements = false,
  });

  /// 当前识别结果。
  final AnalysisTextModel? model;

  /// 相机预览尺寸（像素）。
  final Size? previewSize;

  /// 预览画面的填充方式。
  final BoxFit fit;

  /// 是否绘制文字块。
  final bool showBlocks;

  /// 是否绘制文字行。
  final bool showLines;

  /// 是否绘制文字元素。
  final bool showElements;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _TextPainter(
            model: model,
            previewSize: previewSize,
            fit: fit,
            showBlocks: showBlocks,
            showLines: showLines,
            showElements: showElements,
          ),
        ),
      ),
    );
  }
}

class _TextPainter extends CustomPainter {
  _TextPainter({
    required this.model,
    required this.previewSize,
    required this.fit,
    required this.showBlocks,
    required this.showLines,
    required this.showElements,
  });

  final AnalysisTextModel? model;
  final Size? previewSize;
  final BoxFit fit;
  final bool showBlocks;
  final bool showLines;
  final bool showElements;

  @override
  void paint(Canvas canvas, Size size) {
    final AnalysisTextModel? model = this.model;
    if (model == null) return;
    final Size imageSize = previewSize ?? Size(model.width ?? size.width, model.height ?? size.height);
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final FittedSizes fitted = applyBoxFit(fit, imageSize, size);
    final double scaleX = fitted.destination.width / imageSize.width;
    final double scaleY = fitted.destination.height / imageSize.height;
    final Offset offset = Alignment.center.inscribe(fitted.destination, Offset.zero & size).topLeft;
    Offset map(Offset point) => Offset(offset.dx + point.dx * scaleX, offset.dy + point.dy * scaleY);

    final Paint blockPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Paint linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Paint elementPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final TextBlock block in model.blockList) {
      if (showBlocks && block.boundingBox != null) {
        _drawRect(canvas, block.boundingBox!, map, blockPaint);
      }
      for (final TextLine line in block.lineList) {
        if (showLines && line.boundingBox != null) {
          _drawRect(canvas, line.boundingBox!, map, linePaint);
        }
        if (showElements) {
          for (final TextElement element in line.elementList) {
            if (element.boundingBox != null) {
              _drawRect(canvas, element.boundingBox!, map, elementPaint);
            }
          }
        }
      }
    }
  }

  void _drawRect(Canvas canvas, Rect rect, Offset Function(Offset) map, Paint paint) {
    canvas.drawRect(Rect.fromPoints(map(rect.topLeft), map(rect.bottomRight)), paint);
  }

  @override
  bool shouldRepaint(covariant _TextPainter oldDelegate) =>
      oldDelegate.model != model ||
      oldDelegate.previewSize != previewSize ||
      oldDelegate.fit != fit ||
      oldDelegate.showBlocks != showBlocks ||
      oldDelegate.showLines != showLines ||
      oldDelegate.showElements != showElements;
}

/// 识别结果树：文字块 -> 行 -> 元素。
class TextResultView extends StatelessWidget {
  const TextResultView({super.key, required this.model});

  /// 识别结果。
  final AnalysisTextModel model;

  @override
  Widget build(BuildContext context) {
    if (model.isEmpty && model.blockList.isEmpty) {
      return const FlText('未识别到文字', fontSize: 13);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const FlText('全部文字', fontSize: 15, fontWeight: FontWeight.w600),
        const SizedBox(height: 6),
        SelectableText(model.text ?? '', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        FlText(
          '原图尺寸：${model.width?.toStringAsFixed(0) ?? '-'} x '
          '${model.height?.toStringAsFixed(0) ?? '-'} · 文字块 ${model.blockList.length} 个',
          fontSize: 12,
        ),
        const SizedBox(height: 12),
        ...model.blockList.indexed.map(((int, TextBlock) entry) => _BlockTile(block: entry.$2, index: entry.$1)),
      ],
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.index});

  final TextBlock block;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: FlText('文字块 ${index + 1}', fontSize: 14),
      subtitle: FlText(block.text ?? '', fontSize: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
      childrenPadding: const EdgeInsets.only(left: 12, bottom: 10),
      children: <Widget>[
        _InfoRow(label: '语言', value: block.recognizedLanguage ?? block.recognizedLanguages?.join(', ')),
        _InfoRow(label: '外接矩形', value: block.boundingBox?.toString()),
        _InfoRow(label: '角点', value: block.corners?.join('  ')),
        ...block.lineList.indexed.map(((int, TextLine) entry) => _LineTile(line: entry.$2, index: entry.$1)),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.index});

  final TextLine line;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 8),
      title: FlText('第 ${index + 1} 行', fontSize: 13),
      subtitle: FlText(line.text ?? '', fontSize: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
      childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
      children: <Widget>[
        _InfoRow(label: '语言', value: line.recognizedLanguage ?? line.recognizedLanguages?.join(', ')),
        _InfoRow(label: '外接矩形', value: line.boundingBox?.toString()),
        ...line.elementList.indexed.map(
          ((int, TextElement) entry) => _InfoRow(label: '元素 ${entry.$1 + 1}', value: entry.$2.text),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? value = this.value;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 76, child: FlText(label, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: FlText(value, fontSize: 12)),
        ],
      ),
    );
  }
}
