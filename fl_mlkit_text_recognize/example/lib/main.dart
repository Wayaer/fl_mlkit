import 'package:example/image_recognize.dart';
import 'package:example/text_recognize_page.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TextRecognizeApp());
}

/// ML Kit 文字识别示例应用。
class TextRecognizeApp extends StatelessWidget {
  const TextRecognizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlMlKitTextRecognize',
      debugShowCheckedModeBanner: false,
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED))),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED), brightness: Brightness.dark),
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
                  child: Icon(Icons.text_fields, size: 32, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlText('FlMlKitTextRecognize', fontSize: 22),
                      SizedBox(height: 2),
                      FlText('ML Kit 文字识别 · Android / iOS', fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              icon: Icons.camera_alt_outlined,
              title: '相机实时识别',
              subtitle: '切换语言与分辨率、识别频率、文字块 / 行 / 单词浮层',
              onTap: _openCamera,
            ),
            _FeatureCard(
              icon: Icons.image_outlined,
              title: '图片文件识别',
              subtitle: '从相册选择图片，查看文字块、行、元素及坐标',
              onTap: () => push(const ImageRecognizePage()),
            ),
            const SizedBox(height: 20),
            const FlText('支持的语言', fontSize: 16),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const <String>[
                '拉丁语系',
                '中文',
                '日语',
                '韩语',
                '天城文',
              ].map((String item) => Chip(label: Text(item))).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  void _openCamera() {
    push(const FlMlKitTextRecognizePage());
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
