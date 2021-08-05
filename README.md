# fl_mlkit_scanning

基于[Google ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning)实现快速稳定扫码功能，支持Android \ IOS 

Realize fast and stable code scanning function based on [Google ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning), and support Android \ IOS

### 使用 use

-ios 添加相机权限  Add camera permissions to IOS

```xml
<key>NSCameraUsageDescription</key>    
<string>是否允许FlMlKitScanning使用你的相机？</string>
```

- 预览 preview

```dart

Widget build(BuildContext context) {
  return FlMlKitScanning(

      /// 相机预览缩放质量
      ///  Camera preview zoom quality
      zoomQuality: ZoomQuality.low,

      /// 是否使用后置摄像头
      /// Using the back camera
      useBackCamera: true,

      /// 是否自动扫描 默认为[true]
      /// Auto scan defaults to [true]
      autoStartScan: false,

      /// 显示在预览上层
      /// Display above preview box
      overlay: const ScannerLine(),

      /// 是否全屏预览（由于原生相机预览为固定尺寸 设置全屏 会裁剪预览）
      /// Full screen (Because the native camera preview is set to a fixed size, the full screen will crop the preview)
      isFullScreen: true,

      /// 闪光灯状态
      /// Flash status
      onFlashChange: (FlashState state) {
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

      /// 二维码识别类型  默认仅识别qr_code，需要识别几种就添加几种
      /// Identification type Only QRcode is recognized by default
      barcodeFormats: <BarcodeFormat>[BarcodeFormat.qr_code],

      /// 扫码回调
      /// Code scanning callback
      onListen: (List<BarcodeModel> barcodes) {
        if (barcodes.isNotEmpty) {
          /// 返回数组 可识别多个码
          /// Return array
        }
      });
}

```

- 方法 method

```dart
void func() {
  
  /// 设置设别码类型
  /// Set type
  FlMLKitScanningMethodCall.instance.setBarcodeFormat();

  /// 识别图片字节
  /// Identify picture bytes
  FlMLKitScanningMethodCall.instance.scanImageByte();

  /// 打开\关闭 闪光灯 
  /// Turn flash on / off
  FlMLKitScanningMethodCall.instance.setFlashMode();

  /// 暂停扫描
  /// Pause scanning
  FlMLKitScanningMethodCall.instance.pause();

  /// 开始扫描
  /// Start scanncing
  FlMLKitScanningMethodCall.instance.start();
  
}

```