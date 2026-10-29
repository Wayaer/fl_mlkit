## 6.0.0

* 修复快速切换页面时 `dispose` 与重新初始化并发，导致帧监听被取消、扫码不再返回结果的问题
* 扫码结果改用独立事件通道 `fl.camera.scanning.event`，可与相机 / OCR 控制器共存
* 修复图片扫码返回的宽高与条码坐标不一致（Android 按 `rotationDegrees`、iOS 按 EXIF 方向计算旋转后尺寸）
* 最低版本与 `fl_camera` 对齐：Flutter 3.35 / Dart 3.9，Android minSdk 23，iOS 15.5（Google ML Kit 9.0.0）
* 升级 `fl_camera` 至 5.0.0、`fl_channel` 至 2.0.0、Google ML Kit Barcode Scanning 至 17.3.0
* 修复 Android 频率参数类型转换导致的崩溃
* 修复图片扫描结果在识别失败时 Future 不返回的问题
* 图片扫描改为后台线程解码，避免阻塞 UI
* 新增 `barcodeList`、`isEmpty` 等便捷 API，模型字段改为不可变
* 修正 WiFi 加密类型枚举命名
* 修复 iOS 条码原始字节直接传 `Data` 导致平台通道编码失败
* 修复 iOS 未知条码格式（0）被误映射为 `BarcodeFormat.all`

## 5.3.0

* Update dependencies

## 5.2.2

* Update gradle version
* Update dependencies

## 5.1.0

* Update dependencies

## 5.0.1

* Add `namespace` in Android

## 5.0.0

* Update `fl_camera`

## 4.0.6

* Update version

## 4.0.1+1

* Fixed uninitialized not updating

## 4.0.0+1

* I didn't change anything, just want to send a version

## 4.0.0

* Compatible with flutter 3.0.0
* Fix known problems and optimize some methods

## 3.1.1

* Fix bug [#10](https://github.com/Wayaer/fl_mlkit_scanning/issues/10#issue-1071446534)

## 3.1.0

* Optimization can switch languages without destroying the camera
* Optimize some problems

## 3.0.1

* Add doc

## 3.0.0

* Add intercept callback
* Remove `FlMlKitScanningMethodCall()`
* Add `onCreateView` for `FlMlKitScanning()`
* Add `frequency` for `FlMlKitScanning()`
* Add `stopPreview()` for `FlMlKitScanningController()`
* Add `switchCamera()` for `FlMlKitScanningController()`
* Add `resetCamera()` for `FlMlKitScanningController()`
* Modify `onFlashChange` to `onFlashChanged`
* Modify `onZoomChange` to `onZoomChanged`
* Modify `onListen` to `onDataChanged`

## 2.2.2

* Update [`fl_camera`](https://pub.dev/packages/fl_camera)
* Fix invalid `uninitialized`

## 2.2.0

* Remove instance , direct initialization

## 2.1.0

* Add method `getScanState`
* Remove `isFullScreen` and add `fit`

## 2.0.0

* Add camera zoom function and add `onZoomChange`
* Modify the `onListen` callback value and add the width and height of the parsed picture to
  calculate the bar code rectangle and coordinate points displayed on the screen
* Remove `useBackCamera`, add `availableCameras` and select the camera you need. The rear camera is
  used by default
* Remove `zoomQuality`, add `resolution`, and set the resolution you need,
* Add `updatereset`. Do you need to reinitialize the camera preview when calling didupdatewidget
* Update [`fl_camera`](https://pub.dev/packages/fl_camera)
* Modify `FlMLKitScanningMethodCall` to `FlMlKitScanningMethodCall`

## 1.0.1

* Fix the problem that there is no data in the `boundingbox`

## 1.0.0

* Upgrade Android Gradle

## 0.0.6

* Remove useless files

## 0.0.5

* Add `start` and `pause` scan methods

## 0.0.2

* `FlMlKitScanning` add `useBackCamera`、`zoomQuality`

## 0.0.1

* Initial release.
