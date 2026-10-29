## 5.0.0

* 相机事件通道按控制器区分（相机 / 扫码 / OCR），相机事件广播给所有已注册通道，
  修复多个控制器共用 `fl.camera.event` 时监听被覆盖、释放后无法恢复的问题
* 新增预览尺寸变化事件；iOS `lockPortrait: false` 时预览跟随设备方向旋转并同步宽高
* 升级 `fl_channel` 至 2.0.0
* 升级 Android CameraX 至 1.6.2，compileSdk 36，minSdk 23
* iOS 最低支持 15.5，补充隐私清单
* 修复 `CameraZoomState.fromMap` 读取 `zoomRatio` 错误
* 修复事件通道为空、相机控制器重复初始化、iOS 相机初始化失败时的崩溃问题
* 修复 iOS 闪光灯自动模式、缩放上限、KVO 观察者泄漏问题
* 优化：无图像订阅时不创建 `ImageAnalysis`，避免相机帧无人消费导致的泄漏
* 新增 `CameraInfo` 相等性与 `isInitialized`
* iOS 同时提供 `Package.swift` 与 podspec，支持 Swift Package Manager / CocoaPods 两种依赖方式
* 最低支持版本对齐 Flutter 3.35 / Dart 3.9
* 修复 iOS 采集会话 start / stop 未串行化、stopRunning 阻塞主线程、设备方向非主线程读取问题
* 修复 Android 初始化竞态、Activity 重建后复用旧相机实例、纹理释放顺序问题
* 修复页面退出后未恢复屏幕方向、快速进出页面时 dispose 与 initialize 竞态问题
* 闪光灯 / 缩放接口现在会返回真实执行结果
* 修复 iOS 采集会话被系统中断后不恢复、启动失败仍返回成功、`max` 分辨率尺寸不一致问题
* Android 摄像头枚举与预览尺寸计算移到后台线程；支持预览启动后动态挂载图像分析
* 修复页面退出瞬间 `initialize` 与 `dispose` 的竞态，避免相机被重新打开后无人释放
* 修复快速打开、关闭相机页时，旧页面的延迟销毁会释放新页面相机、
  导致再次进入后无法预览的问题
* 修复切换摄像头 / 分辨率时未先停止预览，失败后仍引用已释放纹理导致的永久黑屏
* 预览失败时清空旧预览状态；新增 `permissionDenied` 错误码，
  权限授予后回到前台会自动重试初始化
* Google Play 会因 `CAMERA` 权限隐含相机为必需设备，补充 `uses-feature required="false"`
* 修复 Android 释放相机后下游图像监听失效（扫码 / OCR 静默不再出帧）；
  无订阅者时解绑 `ImageAnalysis`，不再持续空转出帧
* 修复 iOS `canAddOutput` 失败仍返回成功、事件通道复用、像素缓冲与纹理 ID 跨线程访问
* 新增 `FlCamera.lockPortrait`，可关闭相机页的全局竖屏锁定
* 插件在 `initialize` 时自动申请相机权限（Android 运行时权限 / iOS 系统授权）
* 相机初始化 / 预览失败统一枚举为 `FlCameraErrorCode`（权限拒绝、权限中断、未初始化、
  参数非法、摄像头不存在、初始化失败等），原生只返回成功或固定错误码，
  Dart 侧通过 `errorNotifier` 监听
* 修复首帧返回前调用 `stopPreview` 被忽略的问题
* 原生相机被释放（Activity 重建）后立即重建预览，不再依赖 lifecycle `resumed`
* 图像帧取消订阅改为幂等；Android 解绑 `ImageAnalysis` 只解绑分析用例，
  重绑时恢复闪光灯与缩放，避免闪黑帧与状态丢失
* iOS 补齐会话中断标记、KVO 设备读取的线程安全
* 修复 Android 缩放状态事件使用 Float 导致 Flutter 无法编码、缩放回调丢失
* 修复 iOS 相机帧已由 `AVCaptureVideoDataOutput` 物理旋转为竖屏、却又按设备方向二次旋转，
  导致扫码 / OCR 图像方向错误

## 4.3.2

* Update fl_channel

## 4.2.0

* Update gradle version

## 4.1.0

* Fixes known issues on android

## 4.0.1

* Use [fl_channel](https://pub.dev/packages/fl_channel)

## 3.1.3

* Nothing updated

## 3.1.2

* Fixed crash of exit page when not granted permissions

## 3.1.1

* Fix known problems and optimize some methods

## 3.0.0

* Compatible with flutter 3.0.0

## 2.2.1

* Break up the code

## 2.1.0

* Remove `FlCameraMethodCall()`
* Add `onCreateView` for `FlCamera()`
* Add `stopPreview()` for `FlCameraController()`
* Add `switchCamera()` for `FlCameraController()`
* Add `resetCamera()` for `FlCameraController()`
* Modify `onFlashChange` to `onFlashChanged`
* Modify `onZoomChange` to `onZoomChanged`
* Modify `uninitialized` to `notPreviewed`

## 1.3.2

* Fix bug for [2#issue](https://github.com/Wayaer/fl_camera/issues/2#issue-1008411936)

## 1.3.1

* Fix bug for `onFlashChange`
* Fix bug for [1#issue](https://github.com/Wayaer/fl_camera/issues/1#issue-1007140910)

## 1.2.0

* Remove instance , direct initialization

## 1.1.5

* Update gradle version
* Update kotlin version

## 1.1.3

* Fix bug

## 1.1.2

* Fixed the camera preview size problem of IOS in 1920x1080

## 1.1.1

* Add `fit`
* Optimize camera preview box

## 1.1.0

* Add camera zoom function and add onzoomchange
* Remove usebackcamera, add availablecameras and select the camera you need. The rear camera is used
  by default
* Remove zoomquality, add resolution, and set the resolution you need,
* Add updatereset. Do you need to reinitialize the camera preview when calling didupdatewidget
* Modify FLCameraEvent to FlCameraEvent

## 1.0.2

* Fix bug for Android

## 1.0.0

* Upgrade Android Gradle
* Upgrade CameraX

## 0.0.5

* Remove useless files
* Fix bug

## 0.0.3

* Add doc
* InitCamera() add useBackCamera、zoomQuality

## 0.0.1

* Initial release.
