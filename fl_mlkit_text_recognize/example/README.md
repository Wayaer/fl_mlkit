# fl_mlkit_text_recognize example

演示 `fl_mlkit_text_recognize` 的文字识别能力。

## 运行

iOS 走 CocoaPods，需要先关闭 Swift Package Manager：

```bash
flutter config --no-enable-swift-package-manager
flutter pub get
flutter run
```

## 页面

- 相机实时识别：拉丁语系 / 中文 / 日语 / 韩语 / 天城文、识别频率、文字块 / 行 / 元素浮层
- 图片识别：从相册选择图片，调整旋转角度，查看文字块、行、元素及坐标

需要授予相机权限。图片选择使用系统选择器，无需存储权限。
