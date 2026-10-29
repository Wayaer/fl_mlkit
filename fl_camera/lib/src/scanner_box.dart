part of '../fl_camera.dart';

/// 扫码框动画浮层。
///
/// 在预览画面上绘制一个带四角高亮与上下扫描线的取景框，
/// 可直接作为 [FlCamera.overlay] 使用。
class ScannerBox extends StatefulWidget {
  /// 创建扫码框。
  const ScannerBox({
    super.key,
    this.child,
    this.borderColor,
    this.scannerColor,
    this.hornStrokeWidth,
    this.hornWidth,
    this.scannerStrokeWidth,
    this.scannerSize,
    this.backgroundColor,
  });

  /// 扫码框内的组件，例如提示文案或结果展示。
  final Widget? child;

  /// 扫描框尺寸。
  ///
  /// 为 null 时扫描框铺满父组件，此时不会绘制四周遮罩。
  final Size? scannerSize;

  /// 四角线宽度。
  final double? hornStrokeWidth;

  /// 四角线长度。
  final double? hornWidth;

  /// 四边线宽度。
  final double? scannerStrokeWidth;

  /// 四边线与四角线颜色。
  final Color? borderColor;

  /// 中间滚动扫描线颜色。
  final Color? scannerColor;

  /// 扫描框外的半透明遮罩颜色。
  final Color? backgroundColor;

  @override
  State<ScannerBox> createState() => _ScannerBoxState();
}

class _ScannerBoxState extends State<ScannerBox> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (BuildContext context, Widget? child) => CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: ScannerPainter(
        scannerStrokeWidth: widget.scannerStrokeWidth,
        hornStrokeWidth: widget.hornStrokeWidth,
        hornWidth: widget.hornWidth,
        value: controller.value,
        backgroundColor: widget.backgroundColor,
        scannerSize: widget.scannerSize,
        borderColor: widget.borderColor,
        scannerColor: widget.scannerColor,
      ),
      willChange: true,
      child: widget.child,
    ),
  );
}

/// 扫码框绘制器。
///
/// 可单独用于自定义动画，[value] 取值 0 ~ 1 表示扫描线从上到下的位置。
class ScannerPainter extends CustomPainter {
  /// 创建扫码框绘制器。
  ScannerPainter({
    double? hornStrokeWidth,
    double? scannerStrokeWidth,
    double? hornWidth,
    Color? scannerColor,
    Color? borderColor,
    Color? backgroundColor,
    this.scannerSize,
    required this.value,
  }) : scannerColor = scannerColor ?? Colors.white,
       borderColor = borderColor ?? Colors.white,
       backgroundColor = backgroundColor ?? Colors.black45,
       hornStrokeWidth = hornStrokeWidth ?? 4,
       hornWidth = hornWidth ?? 15,
       scannerStrokeWidth = scannerStrokeWidth ?? 2;

  /// 动画进度，0 表示扫描线在顶部，1 表示在底部。
  final double value;

  /// 四边线与四角线颜色。
  final Color borderColor;

  /// 扫描线颜色。
  final Color scannerColor;

  /// 扫描框外的半透明遮罩颜色。
  final Color backgroundColor;

  /// 扫描框尺寸，为 null 时使用画布尺寸。
  final Size? scannerSize;

  /// 四角线宽度。
  final double hornStrokeWidth;

  /// 四角线长度。
  final double hornWidth;

  /// 四边线宽度。
  final double scannerStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = backgroundColor;
    final Size boxSize = scannerSize ?? size;
    final double width = boxSize.width.clamp(0, size.width).toDouble();
    final double height = boxSize.height.clamp(0, size.height).toDouble();
    if (scannerSize != null && (boxSize.width != size.width || boxSize.height != size.height)) {
      final double w = (size.width - width) / 2;
      final double h = (size.height - height) / 2;
      final Path pathShadow = Path()
        ..addRect(Rect.fromLTWH(0, 0, w, size.height))
        ..addRect(Rect.fromLTWH(w, 0, width, h))
        ..addRect(Rect.fromLTWH(size.width - w, 0, w, size.height))
        ..addRect(Rect.fromLTWH(w, size.height - h, width, h));
      canvas.drawPath(pathShadow, paint);
    }
    paint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = scannerStrokeWidth;
    final double top = (size.height - height) / 2;
    final double left = (size.width - width) / 2;
    final Rect rect = Rect.fromLTWH(left, top, width, height);
    canvas.drawRect(rect, paint);
    paint.strokeWidth = hornStrokeWidth;
    final Path path = Path()
      ..moveTo(left, hornWidth + top)
      ..lineTo(left, top)
      ..lineTo(hornWidth + left, top)
      ..moveTo(width + left - hornWidth, top)
      ..lineTo(width + left, top)
      ..lineTo(width + left, hornWidth + top)
      ..moveTo(width + left, height - hornWidth + top)
      ..lineTo(width + left, height + top)
      ..lineTo(width + left - hornWidth, height + top)
      ..moveTo(hornWidth + left, height + top)
      ..lineTo(left, height + top)
      ..lineTo(left, height + top - hornWidth);
    canvas.drawPath(path, paint);
    final double scanWidth = width > 20 ? width - 20 : 0;
    final double scanHeight = height > 20 ? height - 20 : 0;
    final Rect scanRect = Rect.fromLTWH(10 + left, value * scanHeight + top + 10, scanWidth, 0);
    paint.shader = LinearGradient(
      colors: <Color>[scannerColor.withAlpha(51), scannerColor, scannerColor.withAlpha(51)],
      stops: const <double>[0, 0.5, 1],
    ).createShader(scanRect);
    paint.strokeWidth = scannerStrokeWidth;
    canvas.drawRect(scanRect, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.scannerColor != scannerColor ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.scannerSize != scannerSize ||
      oldDelegate.hornStrokeWidth != hornStrokeWidth ||
      oldDelegate.hornWidth != hornWidth ||
      oldDelegate.scannerStrokeWidth != scannerStrokeWidth;
}
