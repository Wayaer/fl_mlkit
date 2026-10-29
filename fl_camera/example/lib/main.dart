import 'package:example/camera_page.dart';
import 'package:example/overlay_pages.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlCameraApp());
}

/// FlCamera 示例应用。
class FlCameraApp extends StatelessWidget {
  const FlCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlCamera',
      debugShowCheckedModeBanner: false,
      navigatorKey: FlExtended().navigatorKey,
      scaffoldMessengerKey: FlExtended().scaffoldMessengerKey,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB))),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.dark),
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
                  child: Icon(Icons.photo_camera_outlined, size: 32, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlText('FlCamera', fontSize: 26),
                      SizedBox(height: 2),
                      FlText('Android CameraX / iOS AVFoundation', fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              icon: Icons.camera_alt_outlined,
              title: '相机预览',
              subtitle: '闪光灯、缩放、分辨率、前后摄像头切换、开始 / 停止预览',
              onTap: () => _open(const CameraPage()),
            ),
            _FeatureCard(
              icon: Icons.qr_code_scanner,
              title: 'ScannerBox 扫码框',
              subtitle: '带四角高亮与扫描线的取景框浮层',
              onTap: () => _open(const ScannerBoxPage()),
            ),
            _FeatureCard(
              icon: Icons.linear_scale,
              title: 'ScannerLine 扫描线',
              subtitle: '发光扫描线浮层，可自定义颜色',
              onTap: () => _open(const ScannerLinePage()),
            ),
            const SizedBox(height: 20),
            const FlText('使用说明', fontSize: 16),
            const SizedBox(height: 8),
            const FlText(
              '• 首次预览时插件会自动申请相机权限，拒绝后可在系统设置中开启\n'
              '• 预览组件默认锁定竖屏，退出后由应用自行管理\n'
              '• FlashState.auto 仅 iOS 生效，Android 按关闭处理',
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget page) {
    push(page);
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
