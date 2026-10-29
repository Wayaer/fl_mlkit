# fl_mlkit_scanning

[![pub package](https://img.shields.io/pub/v/fl_mlkit_scanning.svg)](https://pub.dev/packages/fl_mlkit_scanning)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Wayaer/fl_mlkit/blob/main/fl_mlkit_scanning/LICENSE)

基于 [Google ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning) 的 Flutter
条码扫描插件，支持 Android 与 iOS。

Camera preview is provided by [fl_camera](https://pub.dev/packages/fl_camera).

## 特性 Features

- 相机实时扫码，支持二维码、条形码等全部 ML Kit 格式
- 图片字节扫码，支持旋转角度（Android）
- 条码坐标：外接矩形、四角坐标、原图宽高
- 结构化解析：网址、WiFi、邮件、电话、短信、地理位置、日历事件、联系人、驾照 / 身份证
- 扫描频率、暂停 / 继续、闪光灯、缩放、分辨率、前后摄像头切换
- 支持 `ScannerBox` / `ScannerLine` 浮层

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
  fl_mlkit_scanning: ^6.0.0
```

### iOS

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>是否允许 FlMlKitScanning 使用你的相机？</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>是否允许 FlMlKitScanning 访问你的相册？</string>
```

从相册选择图片时，建议使用 `file_picker` 等基于系统选择器的插件，无需申请存储权限。

> Google ML Kit 的 iOS 静态库不支持 arm64 模拟器，请使用真机或 Rosetta 模拟器调试。

## 使用 Usage

### 相机实时扫码

```dart
FlMlKitScanning(
  barcodeFormats: const <BarcodeFormat>[BarcodeFormat.all],
  resolution: CameraResolution.high,
  frequency: 600,
  autoScanning: true,
  overlay: const ScannerBox(scannerSize: Size(260, 260)),
  onDataChanged: (AnalysisImageModel data) {
    for (final Barcode barcode in data.barcodeList) {
      debugPrint('${barcode.format} ${barcode.value}');
    }
  },
)
```

### 图片扫码

```dart
final FlMlKitScanningController controller = FlMlKitScanningController();
await controller.setBarcodeFormat(<BarcodeFormat>[BarcodeFormat.all]);
final AnalysisImageModel? result = await controller.scanningImageByte(bytes, rotationDegrees: 0);
```

### 控制器

| 方法 | 说明 |
| --- | --- |
| `initialize()` | 初始化相机与事件通道 |
| `startPreview(camera, resolution:)` | 开始预览 |
| `stopPreview()` | 停止预览 |
| `setBarcodeFormat(formats)` | 设置需要识别的条码格式 |
| `setParams(frequency:, canScanning:)` | 设置扫描间隔与暂停状态 |
| `startScanning()` / `pauseScanning()` | 继续 / 暂停扫描 |
| `scanningImageByte(bytes, rotationDegrees:)` | 识别图片字节 |
| `setFlashMode(state)` / `setZoomRatio(ratio)` | 闪光灯 / 缩放 |
| `switchCamera(camera)` / `resetCamera()` | 切换 / 重置相机 |
| `dispose()` | 释放资源 |

## 数据模型 Data Model

`AnalysisImageModel` 包含 `width`、`height` 与 `barcodeList`。
`Barcode` 的坐标均基于原图尺寸，如果需要绘制到屏幕上，请按照预览的缩放与裁剪方式换算。

解析结果字段：

| 字段 | 类型 |
| --- | --- |
| `value` / `displayValue` / `bytes` | 原始内容 |
| `format` | `BarcodeFormat` |
| `type` | `BarcodeType` |
| `boundingBox` / `corners` | 位置 |
| `url` | `UrlBookmark` |
| `wifi` | `WiFi` |
| `email` | `Email` |
| `phone` | `Phone` |
| `sms` | `SMS` |
| `geoPoint` | `GeoPoint` |
| `calendarEvent` | `CalendarEvent` |
| `contactInfo` | `ContactInfo` |
| `driverLicense` | `DriverLicense` |

## 示例 Example

完整示例见 [example](https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_scanning/example)。
