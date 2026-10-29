# fl_camera example

演示 `fl_camera` 的相机预览与浮层能力。

## 运行

```bash
flutter config --enable-swift-package-manager
flutter pub get
flutter run
```

## iOS 依赖管理

示例使用 Swift Package Manager 集成，仓库中不再包含 Podfile / Pods。
首次构建 iOS 前请确认已开启 SPM；如需改用 CocoaPods，可在 `ios/` 下恢复 Podfile 后执行 `pod install`。

## 页面

- 相机预览：闪光灯、缩放、分辨率、前后摄像头切换、开始 / 停止预览、重置、相机信息
- ScannerBox：扫描框尺寸、四角长度、线宽、颜色实时调整
- ScannerLine：扫描线颜色切换

需要授予相机权限。
