# fl_camera

支持 Android / IOS, Android 使用CameraX

Support Android / IOS, Android uses camerax

主要为原生提供相机预览的封装和消息通道

It mainly provides encapsulation and message channel for native camera preview

- ios 添加相机权限

```plist
<key>NSCameraUsageDescription</key>
<string>是否允许FlCamera使用你的相机？</string>
```

- 相机预览 （ Camera preview ）
  
  [FlCamera()](https://github.com/Wayaer/fl_camera/blob/main/lib/src/fl_camera.dart)

- 相机消息通道 ( Camera message channel ) 
  
  [FlCameraEvent()](https://github.com/Wayaer/fl_camera/blob/main/lib/src/fl_camera_event.dart)

- 相机方法 ( Camera method ) 
  
  [FlCameraController()](https://github.com/Wayaer/fl_camera/blob/main/lib/src/controller.dart)

- 预览框方形遮罩 ( Preview box square mask ) 
  
  [ScannerBox()](https://github.com/Wayaer/fl_camera/blob/main/lib/src/shade/scanner_box.dart)

- 预览框线条遮罩 ( Preview box line mask ) 
  
  [ScannerLine()](https://github.com/Wayaer/fl_camera/blob/main/lib/src/shade/scanner_line.dart)

* [run example](https://github.com/Wayaer/fl_camera/blob/main/example)