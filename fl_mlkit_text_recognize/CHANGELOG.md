## 4.0.0

* 修复快速切换页面时 `dispose` 与重新初始化并发，导致帧监听被取消、识别不再返回结果的问题
* 识别结果改用独立事件通道 `fl.camera.ocr.event`，可与相机 / 扫码控制器共存
* 修复图片识别返回的宽高与文字坐标不一致（Android 按 `rotationDegrees`、iOS 按 EXIF 方向计算旋转后尺寸）
* 最低版本与 `fl_camera` 对齐：Flutter 3.35 / Dart 3.9，Android minSdk 23，iOS 15.5（Google ML Kit 9.0.0）
* 升级 `fl_camera` 至 5.0.0、`fl_channel` 至 2.0.0、Google ML Kit Text Recognition 至 16.0.1
* 修复 Android 频率参数类型转换导致的崩溃
* 修复图片识别结果在识别失败时 Future 不返回的问题
* 修复组件更新时语言 / 频率 / 自动识别参数不同步的问题
* 图片识别改为后台线程解码，避免阻塞 UI
* 新增 `blockList`、`lineList`、`elementList`、`isEmpty` 等便捷 API，模型字段改为不可变

## 3.3.0

* Update dependencies

## 3.2.2

* Update gradle
* Update `fl_camera`

## 3.1.0

* Update dependencies

## 3.0.1

* Add `namespace` in Android

## 3.0.0

* Update `fl_camera`

## 2.0.0

* Compatible with flutter 3.0.0
* Fix known problems and optimize some methods

## 1.1.0

* Added `Korean` and `Devanagari` support
* Optimization can switch languages without destroying the camera

## 1.0.0

* Update [`fl_camera`](https://pub.dev/packages/fl_camera)
* Add intercept callback
* Remove `FlMlKitTextRecognizeMethodCall()`
* Add `onCreateView` for `FlMlKitTextRecognizeController()`
* Add `frequency` for `FlMlKitTextRecognizeController()`
* Add `stopPreview()` for `FlMlKitTextRecognizeController()`
* Add `switchCamera()` for `FlMlKitTextRecognizeController()`
* Add `resetCamera()` for `FlMlKitTextRecognizeController()`
* Modify `onFlashChange` to `onFlashChanged`
* Modify `onZoomChange` to `onZoomChanged`
* Modify `onListen` to `onDataChanged`

## 0.1.2

* Update [`fl_camera`](https://pub.dev/packages/fl_camera)

## 0.1.1

* Fix invalid `uninitialized`

## 0.1.0

* Remove instance , direct initialization

## 0.0.3

* Update gradle version
* Update kotlin version

## 0.0.1

* Initial release.
