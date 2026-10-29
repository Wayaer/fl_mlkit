# fl_mlkit_translate_text

[![pub package](https://img.shields.io/pub/v/fl_mlkit_translate_text.svg)](https://pub.dev/packages/fl_mlkit_translate_text)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit/blob/main/fl_mlkit_translate_text/LICENSE)

基于 Google ML Kit 的 Flutter 端侧文本翻译插件，支持 Android 与 iOS。
模型下载后可完全离线翻译。

## 特性 Features

- 59 种语言互译
- 缺少模型时自动下载
- 模型下载 / 删除 / 查询、已下载模型列表
- 支持仅 WiFi 下载
- 翻译语言切换与交换

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
  fl_mlkit_translate_text: ^2.0.0
```

Android 需要网络权限用于下载模型：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

> Google ML Kit 的 iOS 静态库不支持 arm64 模拟器，请使用真机或 Rosetta 模拟器调试。

## 使用 Usage

```dart
final FlMlKitTranslateText translator = FlMlKitTranslateText();

// 切换语言
await translator.switchLanguage(TranslateLanguage.english, TranslateLanguage.chinese);

// 翻译，缺少模型时自动下载（可限制仅 WiFi）
final String? result = await translator.translate(
  'Hello world',
  downloadModelIfNeeded: true,
  requireWifi: false,
);

// 模型管理
final List<TranslateRemoteModel> models = await translator.getDownloadedModels();
final bool downloaded = await translator.isModelDownloaded(TranslateLanguage.english);
final bool success = await translator.downloadedModel(TranslateLanguage.chinese);
final bool deleted = await translator.deleteDownloadedModel(TranslateLanguage.chinese);

// 不再使用时释放
await translator.dispose();
```

## API

| 方法 | 说明 |
| --- | --- |
| `translate(text, downloadModelIfNeeded:, requireWifi:)` | 翻译文本，失败返回 `null` |
| `switchLanguage(source, target)` | 切换源语言与目标语言 |
| `getCurrentLanguage()` | 从原生同步当前语言 |
| `getDownloadedModels()` | 获取已下载模型 |
| `downloadedModel(language, requireWifi:)` | 下载指定语言模型 |
| `deleteDownloadedModel(language)` | 删除指定语言模型 |
| `isModelDownloaded(language)` | 判断模型是否已下载 |
| `toAbbreviations(language)` | 转换为语言代码，如 `zh` |
| `toTranslateLanguage(tag)` | 语言代码转枚举 |
| `dispose()` | 释放翻译器 |

## 说明 Notes

- 首次翻译某个语言对时需要下载源语言与目标语言模型。
- `TranslateRemoteModel.modelType` 与 `isBaseModel` 仅 Android 返回，iOS 为 `null`。
- iOS 模型下载通过 ML Kit 的下载通知判断成功 / 失败。

## 示例 Example

完整示例见 [example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_translate_text/example)。
