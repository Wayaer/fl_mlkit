## 2.0.0

* 修复翻译 / 模型下载过程中切换语言导致本次调用使用错误语言对的问题（提前持有翻译器实例）
* iOS 模型下载增加超时兜底，避免下载通知丢失时 Future 一直挂起
* iOS 校验语言代码，未知语言不再被当作合法语言；源语言与目标语言相同时 `switchLanguage` 返回 false
* iOS 已下载 / 内置模型直接返回成功，避免下载通知不触发时 Future 一直挂起
* 最低版本与 `fl_camera` 对齐：Flutter 3.35 / Dart 3.9，Android minSdk 23
* 升级 Google ML Kit Translate 至 17.0.3
* iOS 最低支持 15.5，Google ML Kit 9.0.0
* 新增 `requireWifi` 参数，模型下载可限制为仅 WiFi
* 修复 iOS 模型下载完成回调崩溃、失败时 Future 不返回的问题
* 修复 Android 语言代码非法时的空指针异常
* 修复 `toAbbreviations` 可能抛 `LateInitializationError` 的问题，改为静态映射
* 修复 `getCurrentLanguage` 对未知语言标签的强制解包

## 1.2.2

* Update version

## 1.2.1

* Update gradle version

## 1.1.3

* Add `namespace` in Android

## 1.1.2

* Update version

## 1.0.0

* Upgrade Flutter@3.0.0

## 0.1.1

* Optimize some methods
* Add some parameters

## 0.0.2

* Fix bugs on ios

## 0.0.1

* Initial release.
