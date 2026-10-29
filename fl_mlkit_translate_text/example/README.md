# fl_mlkit_translate_text example

演示 `fl_mlkit_translate_text` 的端侧翻译与模型管理能力。

## 运行

```bash
flutter pub get
flutter run
```

## 功能

- 源语言 / 目标语言选择（滚轮选择器）与一键交换
- 缺少模型时自动下载、仅 WiFi 下载
- 翻译结果展示与复制
- 模型管理：搜索语言、查看已下载模型、下载 / 删除模型

首次翻译某个语言对需要联网下载模型，下载完成后可离线翻译。
