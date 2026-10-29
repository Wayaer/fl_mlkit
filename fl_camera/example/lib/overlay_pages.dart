import 'package:fl_camera/fl_camera.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

/// ScannerBox 浮层演示：可调整扫描框尺寸、四角长度、线宽与颜色。
class ScannerBoxPage extends StatefulWidget {
  const ScannerBoxPage({super.key});

  @override
  State<ScannerBoxPage> createState() => _ScannerBoxPageState();
}

class _ScannerBoxPageState extends State<ScannerBoxPage> {
  static const List<Color> colors = <Color>[
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  double scannerSize = 260;
  double hornWidth = 20;
  double hornStrokeWidth = 4;
  double scannerStrokeWidth = 2;
  Color color = colors.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          FlCamera(
            fit: BoxFit.cover,
            overlay: ScannerBox(
              scannerSize: Size.square(scannerSize),
              borderColor: color,
              scannerColor: color,
              hornWidth: hornWidth,
              hornStrokeWidth: hornStrokeWidth,
              scannerStrokeWidth: scannerStrokeWidth,
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: scannerSize / 3),
                  child: FlText('将二维码放入框内', color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
          Positioned(
            top: context.statusBarHeight + 8,
            left: 12,
            right: 12,
            child: Row(
              children: <Widget>[
                Universal(
                  onTap: pop,
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const Expanded(
                  child: FlText('ScannerBox', color: Colors.white, fontSize: 18, textAlign: TextAlign.center),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, context.mediaQuery.padding.bottom + 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _SliderRow(
                    label: '扫描框 ${scannerSize.toStringAsFixed(0)}',
                    value: scannerSize,
                    min: 160,
                    max: 340,
                    onChanged: (double value) => setState(() => scannerSize = value),
                  ),
                  _SliderRow(
                    label: '四角长度 ${hornWidth.toStringAsFixed(0)}',
                    value: hornWidth,
                    min: 8,
                    max: 44,
                    onChanged: (double value) => setState(() => hornWidth = value),
                  ),
                  _SliderRow(
                    label: '四角线宽 ${hornStrokeWidth.toStringAsFixed(1)}',
                    value: hornStrokeWidth,
                    min: 1,
                    max: 8,
                    onChanged: (double value) => setState(() => hornStrokeWidth = value),
                  ),
                  _SliderRow(
                    label: '扫描线宽 ${scannerStrokeWidth.toStringAsFixed(1)}',
                    value: scannerStrokeWidth,
                    min: 1,
                    max: 8,
                    onChanged: (double value) => setState(() => scannerStrokeWidth = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: colors
                        .map(
                          (Color item) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => color = item),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: item,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color == item ? Colors.white : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ScannerLine 浮层演示：可切换扫描线颜色。
class ScannerLinePage extends StatefulWidget {
  const ScannerLinePage({super.key});

  @override
  State<ScannerLinePage> createState() => _ScannerLinePageState();
}

class _ScannerLinePageState extends State<ScannerLinePage> {
  static const List<Color> colors = <Color>[
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  Color color = colors.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          FlCamera(
            fit: BoxFit.cover,
            overlay: ScannerLine(color: color),
          ),
          Positioned(
            top: context.statusBarHeight + 8,
            left: 12,
            right: 12,
            child: Row(
              children: <Widget>[
                Universal(
                  onTap: pop,
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const Expanded(
                  child: FlText('ScannerLine', color: Colors.white, fontSize: 18, textAlign: TextAlign.center),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, context.mediaQuery.padding.bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black87],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors
                    .map(
                      (Color item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => color = item),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: item,
                              shape: BoxShape.circle,
                              border: Border.all(color: color == item ? Colors.white : Colors.transparent, width: 2),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 带标签的滑杆行。
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 108, child: FlText(label, color: Colors.white70, fontSize: 12)),
        Expanded(
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
