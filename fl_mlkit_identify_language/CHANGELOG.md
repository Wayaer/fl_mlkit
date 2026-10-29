## 2.0.0

* 最低版本与 `fl_camera` 对齐：Flutter 3.35 / Dart 3.9，Android minSdk 23
* iOS 最低支持 15.5，Google ML Kit 9.0.0
* 修复 `dispose(double confidence)` 多余参数，改为无参 `dispose()`
* 修复置信度在 release 模式下缺少校验的问题
* 新增平台支持判断，非 Android / iOS 平台安全返回
* 修复 Android 置信度以 Float 返回导致平台通道编码失败（改为 Double）

## 1.2.2

* Update gradle version

## 1.0.0

* Upgrade Flutter@3.0.0

## 0.0.2

* Initial release.
