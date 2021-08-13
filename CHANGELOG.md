## [2.0.0]
 * add camera zoom function and add `onZoomChange`
 * modify the `onListen` callback value and add the width and height of the 
   parsed picture to calculate the bar code rectangle and coordinate points displayed on the screen
 * remove `useBackCamera`, add `availableCameras` and select the camera you need.
   The rear camera is used by default
 * remove `zoomQuality`, add `resolution`, and set the resolution you need, 
 * add `updatereset`. Do you need to reinitialize the camera preview when calling didupdatewidget
 * Update [`fl_camera`](https://pub.dev/packages/fl_camera)
## [1.0.1]
 * fix the problem that there is no data in the boundingbox
## [1.0.0]
 * upgrade Android Gradle
## [0.0.6]
 * Remove useless files
## [0.0.5]
 * Add `start` and `pause` scan methods
## [0.0.2]
 * `FlMlKitScanning` add `useBackCamera`、`zoomQuality`
## [0.0.1]
* initial release.
