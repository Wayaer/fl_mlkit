# fl_camera

[![pub package](https://img.shields.io/pub/v/fl_camera.svg)](https://pub.dev/packages/fl_camera)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit/blob/main/fl_camera/LICENSE)

一个轻量的 Flutter 相机预览插件：Android 使用 CameraX，iOS 使用 AVFoundation。

A lightweight camera preview plugin for Flutter: CameraX on Android, AVFoundation on iOS.

## 特性 Features

- 相机预览、开始 / 停止预览、重置预览
- 前后摄像头切换、可用摄像头枚举
- 闪光灯开关（iOS 支持自动模式）
- 缩放（自动收敛到设备支持的最大缩放比例）
- 多种预览分辨率
- 内置扫码框 `ScannerBox` 与扫描线 `ScannerLine` 浮层
- 相机图像数据流，可被扫码 / OCR 插件复用
- 无图像订阅时不会创建 `ImageAnalysis`，减少 CPU 与内存开销

## 平台要求 Requirements

| 平台 | 要求 |
| --- | --- |
| Flutter | >= 3.35.0 |
| Dart | >= 3.9.0 |
| Android | minSdk 23，compileSdk 36，AGP 9.1.0，Kotlin 2.4.0 |
| iOS | 15.5+ |

仅支持 Android 与 iOS。

> iOS 侧同时支持 CocoaPods 与 Swift Package Manager（SPM 从 Flutter 3.24 起可用，
> 自 Flutter 3.44 起默认启用），无需关闭 SPM。
> 示例程序使用 Swift Package Manager 集成；CocoaPods 工程无需任何额外配置，Flutter 会自动回退。
> 若同时使用 `fl_mlkit_scanning` 或 `fl_mlkit_text_recognize`（依赖 Google ML Kit，官方仅提供
> CocoaPods），请执行 `flutter config --no-enable-swift-package-manager` 后再构建 iOS。

## 安装 Installation

```yaml
dependencies:
  fl_camera: ^5.0.0
```

### Android

相机权限由插件在 `initialize` 时自动申请（运行时权限），宿主无需再接入权限库。
初始化 / 预览失败时原生只返回「成功」或固定错误码，Dart 侧统一映射为
`FlCameraErrorCode`，可监听 `FlCameraController().errorNotifier` 展示对应引导。

| 错误码 | 含义 |
| --- | --- |
| `platformUnsupported` | 当前平台不支持相机 |
| `permissionDenied` | 用户拒绝相机权限，或系统限制了相机访问 |
| `permissionRequestInterrupted` | 权限申请被 Activity 销毁或重复请求打断 |
| `notInitialized` | 未初始化就调用预览，或原生相机实例已释放 |
| `invalidArguments` | 摄像头 ID / 分辨率等参数缺失或非法 |
| `cameraNotFound` | 指定的摄像头不存在 |
| `cameraInitFailed` | 相机绑定、输入输出、纹理创建或采集会话启动失败 |
| `unknown` | 未分类异常 |

### iOS

插件同时提供 `ios/fl_camera/Package.swift` 与 `ios/fl_camera.podspec`：

- 开启 SPM 的工程（`flutter config --enable-swift-package-manager`）自动使用 Swift Package Manager；
- 未开启 SPM 时自动通过 CocoaPods 集成，无需修改 Podfile。

在 `ios/Runner/Info.plist` 中添加相机权限说明：

```xml
<key>NSCameraUsageDescription</key>
<string>是否允许 FlCamera 使用你的相机？</string>
```

插件会在 `initialize` 时调用系统授权弹窗；用户拒绝时同样返回 `permissionDenied`。

## 使用 Usage

### 预览 Preview

```dart
import 'package:fl_camera/fl_camera.dart';

FlCamera(
  resolution: CameraResolution.high,
  fit: BoxFit.cover,
  uninitialized: const Center(child: Text('相机未初始化')),
  onFlashChanged: (FlashState state) => debugPrint('flash: $state'),
  onZoomChanged: (CameraZoomState state) => debugPrint('zoom: ${state.zoomRatio}'),
  overlay: const ScannerBox(scannerSize: Size(260, 260)),
)
```

`FlCamera` 会锁定竖屏，并在退出页面时释放相机。

### 控制器 Controller

```dart
final FlCameraController controller = FlCameraController();

await controller.initialize();
final List<CameraInfo>? cameras = controller.cameras;
await controller.startPreview(cameras!.first, resolution: CameraResolution.high);

await controller.setFlashMode(FlashState.on);
await controller.setZoomRatio(2);
await controller.switchCamera(cameras.last);
await controller.stopPreview();
await controller.resetCamera();
await controller.dispose();
```

所有坐标 / 尺寸相关 API 均为像素单位。

## API

| 类型 | 说明 |
| --- | --- |
| `FlCamera` | 相机预览组件 |
| `FlCameraState<T>` | 可复用的相机预览状态基类 |
| `FlCameraController` | 相机控制器单例 |
| `FlCameraErrorCode` | 初始化 / 预览失败原因枚举 |
| `CameraInfo` | 摄像头信息（名称、前后位置） |
| `FlCameraOptions` | 预览纹理与尺寸 |
| `CameraZoomState` | 当前 / 最大缩放比例 |
| `FlashState` | 闪光灯状态：`off` / `on` / `auto` |
| `CameraResolution` | 预览分辨率预设 |
| `CameraLensFacing` | 摄像头位置 |
| `ScannerBox` / `ScannerPainter` | 扫码框浮层 |
| `ScannerLine` | 扫描线浮层 |

## 说明 Notes

- `FlashState.auto` 仅 iOS 生效，Android 会按关闭处理。
- 预览分辨率会按设备能力就近选择，实际尺寸以 `FlCameraOptions` 为准。
- 通过 `FlCamera(lockPortrait: false)` 可关闭竖屏锁定；此时 iOS 预览会跟随设备方向旋转，
  Android 由 CameraX 自动处理。默认 `true` 时退出相机页会把方向恢复为
  「允许所有方向」，宿主若有自定义方向锁需在退出后自行重新设置，相机页设置的状态栏样式也不会自动恢复。
- 相机 / 扫码 / OCR 控制器各自使用独立事件通道（`fl.camera.event`、`fl.camera.scanning.event`、
  `fl.camera.ocr.event`），原生会把闪光灯、缩放、预览尺寸与相机释放事件广播给所有已注册的通道，
  避免多个控制器共用同一通道时监听互相覆盖。
- 同一路相机帧只应由一个下游消费者处理，不要同时订阅扫码与文字识别，否则同一个
  `ImageProxy` 会被重复关闭。
- 同一 FlutterEngine 同一时间只支持一个相机预览；暂不支持 add-to-app 多引擎同时使用相机。
- iOS 目前仅枚举广角摄像头（前置 / 后置 wide），不包含超广角、长焦与外置摄像头。
- 下游插件若直接使用原生 `listenImageProxy` / `listenImageBuffer`，建议在 `startPreview`
  之前注册监听；Android 在预览启动后注册会动态重新绑定，iOS 注册后即可收到帧。
- 插件只负责相机预览与数据流，条码识别请使用
  [fl_mlkit_scanning](https://pub.dev/packages/fl_mlkit_scanning)，文字识别请使用
  [fl_mlkit_text_recognize](https://pub.dev/packages/fl_mlkit_text_recognize)。

## 示例 Example

完整示例见 [example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_camera/example)。
