part of '../fl_camera.dart';

/// 扫描线动画浮层。
///
/// 在预览画面上绘制一条上下往返的发光扫描线，可直接作为 [FlCamera.overlay] 使用。
class ScannerLine extends StatefulWidget {
  /// 创建扫描线。
  const ScannerLine({super.key, Color? color}) : color = color ?? Colors.green;

  /// 扫描线颜色。
  final Color color;

  @override
  State<ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<ScannerLine> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> offsetAnimation;
  late final Animation<double> opacityAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    offsetAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(controller);
    opacityAnimation = CurvedAnimation(parent: controller, curve: _OpacityCurve());
    controller.repeat();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (BuildContext context, Widget? child) => Opacity(
      opacity: opacityAnimation.value,
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _LinePainter(offsetAnimation.value, widget.color),
      ),
    ),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _OpacityCurve extends Curve {
  @override
  double transform(double t) {
    if (t < 0.1) return t * 10;
    if (t <= 0.9) return 1;
    return (1 - t) * 10;
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.offset, this.color);

  final double offset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final double radius = size.width * 0.45;
    final Offset center = Offset(size.width / 2, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(colors: <Color>[color, color.withAlpha(26)], radius: 0.5).createShader(rect);
    canvas.translate(0, size.height * offset);
    canvas.scale(1, 0.1);
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, radius));
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.offset != offset || oldDelegate.color != color;
}
