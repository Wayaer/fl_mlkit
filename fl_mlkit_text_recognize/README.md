# fl_mlkit_text_recognize

基于[Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2)实现快速稳定识别文字功能，支持Android\IOS

Realize fast and stable text recognition function based
on [Google ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2), and support Android \ IOS

相机相关功能依赖于 [fl_camera](https://pub.dev/packages/fl_camera)

Camera related functions depend on [fl_camera](https://pub.dev/packages/fl_camera)

### 使用 use

- ios 添加相机权限 Add camera permissions to IOS

```plist
<key>NSCameraUsageDescription</key>
<string>是否允许FlMlKitTextRecognize使用你的相机？</string>
```

- 预览 preview

```dart

Widget build(BuildContext context) {
  return FlMlKitTextRecognize(

    /// 如果你设置为10, 2次解析数据间隔为10 毫秒，数字越小 在ios上cpu占有率越高，数字越大，识别速度会变慢，建议设置500-100
    /// If you set it to 10, The interval between data parsing is 10 milliseconds
    /// The larger the number, the slower the parsing,If the number is too small, the CPU percentage will be too high on ios
    /// Therefore, the recommended setting range is 500 to 1000
      frequency: 500,

      /// 需要预览的相机
      /// Camera ID to preview
      camera: camera,

      /// 预览相机支持的分辨率
      /// Preview the resolution supported by the camera
      resolution: CameraResolution.high,

      /// 是否自动扫描 默认为[true]
      /// Auto scan defaults to [true]
      autoScanning: false,

      /// 显示在预览上层
      /// Display above preview box
      overlay: const ScannerLine(),

      /// 相机预览位置
      /// How a camera box should be inscribed into another box.
      fit: BoxFit.fitWidth,

      /// 闪光灯状态
      /// Flash status
      onFlashChanged: (FlashState state) {
        showToast('$state');
      },

      /// 缩放变化
      /// zoom ratio
      onFlashChanged: (FlashState state) {
        showToast('$state');
      },

      /// 相机在未初始化时显示的UI
      /// The UI displayed when the camera is not initialized
      uninitialized: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child:
          const Text(
              'Camera not initialized', style: TextStyle(color: Colors.white))),

      /// 识别文本的语言类型
      /// Identifies the language type of the text
      recognizedLanguage: RecognizedLanguage.latin,

      /// 文本识别回调
      /// Text recognized callback
      onDataChanged: (AnalysisTextModel data) {
        if (data.text != null && data.text!.isNotEmpty) {

        }
      });
}

```

- 方法 method

```dart
void func() {

  /// 设置识别文本的语言类型
  /// Sets the language type that identifies the text
  controller.setRecognizedLanguage();

  /// 识别图片字节
  /// Identify picture bytes
  controller.scanImageByte();

  /// 打开\关闭 闪光灯 
  /// Turn flash on / off
  controller.setFlashMode();

  /// 相机缩放
  /// Camera zoom
  controller.setZoomRatio();

  /// 暂停识别
  /// Pause recognition
  controller.pause();

  /// 开始识别
  /// Start recognition
  controller.start();
}

```

| image                                                                                                        | scan                                                                                                       |
|--------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| <img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_text_recognize/main/example/assets/image.jpg" /> | <img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_text_recognize/main/example/assets/scan.jpg"/> |

<img src="https://raw.githubusercontent.com/Wayaer/fl_mlkit_text_recognize/main/example/assets/test.jpg"/>
