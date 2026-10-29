# fl_mlkit_text_recognize

[![pub package](https://img.shields.io/pub/v/fl_mlkit_text_recognize.svg)](https://pub.dev/packages/fl_mlkit_text_recognize)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit/blob/main/fl_mlkit_text_recognize/LICENSE)

基于 [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2) 的 Flutter
文字识别（OCR）插件，支持 Android 与 iOS。

Camera preview is provided by [fl_camera](https://pub.dev/packages/fl_camera).

## 特性 Features

- 相机实时识别，支持拉丁语系、中文、日语、韩语、天城文
- 图片字节识别，支持旋转角度（Android）
- 返回文字块（`TextBlock`）、行（`TextLine`）、元素（`TextElement`）及坐标
- 识别频率、暂停 / 继续、闪光灯、缩放、分辨率、前后摄像头切换
- 支持自定义浮层，可绘制文字块 / 行 / 元素区域

## 平台要求 Requirements

| 平台 | 要求 |
| --- | --- |
| Flutter | >= 3.35.0 |
| Dart | >= 3.9.0 |
| Android | minSdk 23，compileSdk 36，AGP 9.1.0，Kotlin 2.4.0 |
| iOS | 15.5+（Google ML Kit 9.0.0 要求） |

> Google ML Kit iOS 官方仅提供 CocoaPods，本插件使用 CocoaPods 集成。
> 若使用 Flutter 3.47 且开启了 Swift Package Manager，请先执行
> `flutter config --no-enable-swift-package-manager`。

## 安装 Installation

```yaml
dependencies:
  fl_mlkit_text_recognize: ^4.0.0
```

### iOS

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>是否允许 FlMlKitTextRecognize 使用你的相机？</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>是否允许 FlMlKitTextRecognize 访问你的相册？</string>
```

> Google ML Kit 的 iOS 静态库不支持 arm64 模拟器，请使用真机或 Rosetta 模拟器调试。

## 使用 Usage

### 相机实时识别

```dart
FlMlKitTextRecognize(
  recognizedLanguage: RecognizedLanguage.chinese,
  resolution: CameraResolution.high,
  frequency: 800,
  autoRecognize: true,
  overlay: const ScannerLine(),
  onDataChanged: (AnalysisTextModel data) {
    debugPrint(data.text);
  },
)
```

### 图片识别

```dart
final FlMlKitTextRecognizeController controller = FlMlKitTextRecognizeController();
await controller.setRecognizedLanguage(RecognizedLanguage.chinese);
final AnalysisTextModel? result = await controller.recognizeImageByte(bytes, rotationDegrees: 0);
```

### 控制器

| 方法 | 说明 |
| --- | --- |
| `initialize()` | 初始化相机与事件通道 |
| `startPreview(camera, resolution:)` | 开始预览 |
| `stopPreview()` | 停止预览 |
| `setRecognizedLanguage(language)` | 设置识别语言 |
| `setParams(frequency:, canRecognize:)` | 设置识别间隔与暂停状态 |
| `startRecognize()` / `pauseRecognize()` | 继续 / 暂停识别 |
| `recognizeImageByte(bytes, rotationDegrees:)` | 识别图片字节 |
| `setFlashMode(state)` / `setZoomRatio(ratio)` | 闪光灯 / 缩放 |
| `switchCamera(camera)` / `resetCamera()` | 切换 / 重置相机 |
| `dispose()` | 释放资源 |

## 数据模型 Data Model

`AnalysisTextModel` 包含：

| 字段 | 说明 |
| --- | --- |
| `text` | 全部识别文字 |
| `textBlocks` / `blockList` | 文字块列表 |
| `width` / `height` | 原图尺寸（像素） |

`TextBlock`、`TextLine`、`TextElement` 均包含 `text`、`boundingBox`、`corners`，
Android 额外提供 `recognizedLanguage`，iOS 额外提供 `recognizedLanguages`。

## 示例 Example

完整示例见 [example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_text_recognize/example)。
