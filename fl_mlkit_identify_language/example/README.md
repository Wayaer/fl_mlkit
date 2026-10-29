# fl_mlkit_identify_language example

演示 `fl_mlkit_identify_language` 的语言识别能力。

## 运行

```bash
flutter pub get
flutter run
```

## 功能

- 识别最可能的语言，返回 BCP-47 语言代码
- 识别所有可能语言，按置信度展示进度条
- 设置 / 读取置信度阈值（0.01 ~ 1）
