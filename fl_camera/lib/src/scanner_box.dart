part of '../fl_camera.dart';

/// 扫码框动画
/// Scan frame animation
class ScannerBox extends StatefulWidget {
  const ScannerBox(
      {super.key,
      this.child,
      this.borderColor,
      this.scannerColor,
      this.hornStrokeWidth,
      this.scannerStrokeWidth,
      this.scannerSize,
      this.backgroundColor});

  /// 扫码框内的组件
  /// Components in code scanning box
  final Widget? child;

  /// 扫描区域的大小
  /// Size of scan area
  /// [scannerSize]==null 时 扫描框大小等于父组件
  /// When [scannerSize] = null, the scan box size is equal to the parent component
  final Size? scannerSize;

  /// 四角线宽度
  /// Width of quadrangular line
  final double? hornStrokeWidth;

  /// 四边线宽度
  /// Quadrilateral width
  final double? scannerStrokeWidth;

  /// 四边线颜色
  /// Quad color
  final Color? borderColor;

  /// 中间滚动线颜色
  /// Middle scroll line color
  final Color? scannerColor;

  /// 背景色
  final Color? backgroundColor;

  @override
  State<ScannerBox> createState() => _ScannerBoxState();
}

class _ScannerBoxState extends State<ScannerBox> with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    controller.repeat(reverse: true);
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
              value: controller.value,
              backgroundColor: widget.backgroundColor,
              scannerSize: widget.scannerSize,
              borderColor: widget.borderColor,
              scannerColor: widget.scannerColor),
          willChange: true,
          child: widget.child));
}

/// 扫码框+浅色背景
/// Code scanning box + light background
class ScannerPainter extends CustomPainter {
  ScannerPainter({
    double? hornStrokeWidth,
    double? scannerStrokeWidth,
    double? hornWidth,
    Color? scannerColor,
    Color? borderColor,
    Color? backgroundColor,
    this.scannerSize,
    required this.value,
  })  : scannerColor = scannerColor ?? Colors.white,
        borderColor = borderColor ?? Colors.white,
        backgroundColor = backgroundColor ?? Colors.black45,
        hornStrokeWidth = hornStrokeWidth ?? 4,
        hornWidth = hornWidth ?? 15,
        scannerStrokeWidth = scannerStrokeWidth ?? 2;
  final double value;
  final Color borderColor;
  final Color scannerColor;
  final Color backgroundColor;

  /// 扫描框大小
  /// Scan frame size
  final Size? scannerSize;

  /// 四角线宽度
  /// Width of quadrangular line
  final double hornStrokeWidth;

  /// 四角线长度
  /// Length of quadrangular line
  final double hornWidth;

  /// 识别框中间的线
  /// Line in the middle of the identification frame
  final double scannerStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    late final Paint paintValue = Paint()..color = backgroundColor;
    final Size boxSize = scannerSize ?? size;
    double width = boxSize.width;
    double height = boxSize.height;
    if (scannerSize != null && boxSize != size) {
      if (width > size.width) width = size.width;
      if (height > size.height) height = size.height;

      final double w = (size.width - boxSize.width) / 2;
      final double h = (size.height - boxSize.height) / 2;
      final Path pathShadow = Path();
      pathShadow.addRect(Rect.fromLTWH(0, 0, w, size.height));
      pathShadow.addRect(Rect.fromLTWH(w, 0, boxSize.width, h));
      pathShadow.addRect(Rect.fromLTWH(size.width - w, 0, w, size.height));
      pathShadow.addRect(Rect.fromLTWH(w, size.height - h, boxSize.width, h));
      canvas.drawPath(pathShadow, paintValue);
    }
    paintValue
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    paintValue.strokeWidth = scannerStrokeWidth;
    final double top = (size.height - height) / 2;
    final double left = (size.width - width) / 2;
    final Rect rect = Rect.fromLTWH(left, top, boxSize.width, boxSize.height);
    canvas.drawRect(rect, paintValue);
    paintValue.strokeWidth = hornStrokeWidth;
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
    canvas.drawPath(path, paintValue);
    final Rect scanRect = Rect.fromLTWH(
        10 + left, value * (height - 20) + top + 10, width - 20, 0);
    final List<double> stop = <double>[0.0, 0.5, 1];
    paintValue.shader = LinearGradient(colors: <Color>[
      scannerColor.withValues(alpha: 0.2),
      scannerColor,
      scannerColor.withValues(alpha: 0.2),
    ], stops: stop)
        .createShader(scanRect);
    paintValue.strokeWidth = scannerStrokeWidth;
    canvas.drawRect(scanRect, paintValue);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
