# fl_mlkit_scanning example

演示 `fl_mlkit_scanning` 的条码扫描能力。

## 运行

iOS 走 CocoaPods，需要先关闭 Swift Package Manager：

```bash
flutter config --no-enable-swift-package-manager
flutter pub get
flutter run
```

## 页面

- 相机实时扫码：全部条码格式、扫描频率、暂停 / 继续、分辨率、扫码框与识别区域浮层
- 图片扫描：从相册选择图片，调整旋转角度，查看条码坐标与结构化解析结果

需要授予相机权限。图片选择使用系统选择器，无需存储权限。
