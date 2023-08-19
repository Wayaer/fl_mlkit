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
* Remove usebackcamera, add availablecameras and select the camera you need. The rear camera is used by default
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
