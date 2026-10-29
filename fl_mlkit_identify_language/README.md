# fl_mlkit_identify_language

[![pub package](https://img.shields.io/pub/v/fl_mlkit_identify_language.svg)](https://pub.dev/packages/fl_mlkit_identify_language)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit/blob/main/fl_mlkit_identify_language/LICENSE)

使用 Google ML Kit 识别文本语言，支持 Android 与 iOS。

支持的语言列表见
[官方文档](https://developers.google.com/ml-kit/language/identification/langid-support)。

## 特性 Features

- 识别最可能的语言，返回 BCP-47 语言代码
- 识别所有可能语言及置信度
- 可设置 / 读取置信度阈值

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
  fl_mlkit_identify_language: ^2.0.0
```

> Google ML Kit 的 iOS 静态库不支持 arm64 模拟器，请使用真机或 Rosetta 模拟器调试。

## 使用 Usage

```dart
final FlMlKitIdentifyLanguage identifier = FlMlKitIdentifyLanguage();

// 识别最可能的语言
final IdentifiedLanguageModel? best = await identifier.identifyLanguage('Hello world');
debugPrint('${best?.languageTag}'); // en

// 识别所有可能语言及真实置信度
final List<IdentifiedLanguageModel> possible =
    await identifier.identifyPossibleLanguages('Hello world');

// 置信度阈值，取值范围 0.01 ~ 1
await identifier.setConfidence(0.7);
final double confidence = await identifier.getCurrentConfidence();

// 释放识别器
await identifier.dispose();
```

## API

| 方法 | 说明 |
| --- | --- |
| `identifyLanguage(text)` | 返回最可能的语言，失败返回 `null` |
| `identifyPossibleLanguages(text)` | 返回所有可能语言及置信度 |
| `setConfidence(confidence)` | 设置置信度阈值 |
| `getCurrentConfidence()` | 读取原生置信度阈值 |
| `dispose()` | 释放识别器 |

## 说明 Notes

- 无法确定语言时返回 `und`（undetermined）。
- `identifyLanguage` 的原生接口只返回语言代码，因此返回结果中的 `confidence`
  为当前置信度阈值；真实置信度请使用 `identifyPossibleLanguages`。
- 置信度超出 `0.01 ~ 1` 时不会设置，并返回 `false`。

## 示例 Example

完整示例见 [example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_identify_language/example)。
