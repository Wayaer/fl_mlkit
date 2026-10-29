# fl_mlkit

Google ML Kit 系列 Flutter 插件集合，全部支持 Android 与 iOS。

A collection of Google ML Kit plugins for Flutter, supporting Android and iOS only.

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.47.0-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.13.0-blue)](https://dart.dev)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit)

## 插件 Packages

| 插件 | 版本 | 说明 |
| --- | --- | --- |
| [fl_camera](https://pub.dev/packages/fl_camera) | 5.0.0 | 相机预览（Android CameraX / iOS AVFoundation），扫码框与扫描线浮层 |
| [fl_mlkit_scanning](https://pub.dev/packages/fl_mlkit_scanning) | 6.0.0 | 条码 / 二维码扫描，支持相机与图片，返回坐标与结构化数据 |
| [fl_mlkit_text_recognize](https://pub.dev/packages/fl_mlkit_text_recognize) | 4.0.0 | 文字识别（OCR），支持拉丁语系、中文、日语、韩语、天城文 |
| [fl_mlkit_translate_text](https://pub.dev/packages/fl_mlkit_translate_text) | 2.0.0 | 端侧文本翻译，支持 59 种语言与模型管理 |
| [fl_mlkit_identify_language](https://pub.dev/packages/fl_mlkit_identify_language) | 2.0.0 | 语言识别，返回语言代码与置信度 |

## 平台要求 Requirements

| 平台 | 要求 |
| --- | --- |
| Flutter | >= 3.35.0 |
| Dart | >= 3.9.0 |
| Android | minSdk 23，compileSdk 36，AGP 9.1.0，Kotlin 2.4.0 |
| iOS | 15.5+ |

当前只支持 Android 与 iOS，其他平台会安全返回空结果。

> `fl_camera` 的 iOS 侧同时支持 CocoaPods 与 Swift Package Manager。
> 其余 ML Kit 插件依赖的 Google ML Kit iOS 官方仅提供 CocoaPods，
> 因此在开启 Swift Package Manager 的 Flutter 3.47 项目中，请先执行
> `flutter config --no-enable-swift-package-manager` 再构建 iOS。

## 快速开始 Quick Start

```yaml
dependencies:
  fl_mlkit_scanning: ^6.0.0
```

```dart
FlMlKitScanning(
  barcodeFormats: const <BarcodeFormat>[BarcodeFormat.all],
  overlay: const ScannerBox(scannerSize: Size(260, 260)),
  onDataChanged: (AnalysisImageModel model) {
    for (final Barcode barcode in model.barcodeList) {
      debugPrint(barcode.value);
    }
  },
)
```

iOS 需要在 `Info.plist` 中添加相机 / 相册权限说明，具体见各插件 README。

## 示例 Examples

每个插件目录下都有完整示例程序，覆盖该插件全部能力：

- [fl_camera example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_camera/example)
- [fl_mlkit_scanning example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_scanning/example)
- [fl_mlkit_text_recognize example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_text_recognize/example)
- [fl_mlkit_translate_text example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_translate_text/example)
- [fl_mlkit_identify_language example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_identify_language/example)

## 开发 Development

```bash
# 格式化所有包
./format.sh

# 分析
dart analyze fl_camera/lib
dart analyze fl_mlkit_scanning/lib
```

### 本地联调

`fl_mlkit_scanning` 与 `fl_mlkit_text_recognize` 的 `pubspec.yaml` 使用 `fl_camera` 版本依赖，
本地联调通过各自的 `pubspec_overrides.yaml` 指向仓库内的 `fl_camera`，该文件不会被打包发布。

## 许可证 License

[MIT](https://github.com/Wayaer/fl_mlkit/blob/main/fl_camera/LICENSE)
