## 5.2.0

* Update gradle version

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
