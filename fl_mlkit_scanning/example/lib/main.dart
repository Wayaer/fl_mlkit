import 'package:example/image_scanning.dart';
import 'package:example/mlkit_scanning.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScanningApp());
}

/// ML Kit 扫码示例应用。
class ScanningApp extends StatelessWidget {
  const ScanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlMlKitScanning',
      debugShowCheckedModeBanner: false,
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E))),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E), brightness: Brightness.dark),
      ),
      home: const HomePage(),
    );
  }
}

/// 示例首页。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Universal(
          isScroll: true,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.qr_code_scanner, size: 32, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlText('FlMlKitScanning', fontSize: 24),
                      SizedBox(height: 2),
                      FlText('ML Kit 条码扫描 · Android / iOS', fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              icon: Icons.camera_alt_outlined,
              title: '相机实时扫描',
              subtitle: '条码格式、扫描频率、暂停 / 继续、闪光灯、缩放、自定义浮层',
              onTap: _openCamera,
            ),
            _FeatureCard(
              icon: Icons.image_outlined,
              title: '图片文件扫描',
              subtitle: '从相册选择图片，识别条码并展示结构化解析结果',
              onTap: () => push(const ImageScanningPage()),
            ),
            const SizedBox(height: 20),
            const FlText('支持的条码格式', fontSize: 16),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const <String>[
                'QR Code',
                'Code 128',
                'Code 39',
                'Code 93',
                'Codabar',
                'Data Matrix',
                'EAN-13',
                'EAN-8',
                'ITF',
                'UPC-A',
                'UPC-E',
                'PDF417',
                'Aztec',
              ].map((String item) => Chip(label: Text(item))).toList(growable: false),
            ),
            const SizedBox(height: 16),
            const FlText('解析类型', fontSize: 16),
            const SizedBox(height: 8),
            const FlText('网址、WiFi、邮件、电话、短信、地理位置、日历事件、联系人名片、驾照 / 身份证、纯文本', fontSize: 12),
          ],
        ),
      ),
    );
  }

  void _openCamera() {
    push(const FlMlKitScanningPage());
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Universal(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        direction: Axis.horizontal,
        children: <Widget>[
          IconLabel(icon: icon, size: 26, color: colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FlText(title, fontSize: 16, fontWeight: FontWeight.w600),
                const SizedBox(height: 4),
                FlText(subtitle, fontSize: 12),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.outline),
        ],
      ),
    );
  }
}
