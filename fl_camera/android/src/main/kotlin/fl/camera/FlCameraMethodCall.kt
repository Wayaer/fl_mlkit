package fl.camera

import android.app.Activity
import androidx.camera.core.ImageAnalysis
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

open class FlCameraMethodCall(
    private var activity: Activity, private var plugin: FlutterPlugin.FlutterPluginBinding
) : MethodChannel.MethodCallHandler {
    var flCameraEvent: FlCameraEvent? = null
    private var flCamera: FlCameraX? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "availableCameras" -> result.success(CameraTools.getAvailableCameras(activity))
            "initialize" -> {
                if (flCamera == null && flCameraEvent != null) {
                    flCamera = FlCameraX(
                        activity, plugin.textureRegistry, flCameraEvent!!
                    )
                }
                result.success(flCamera != null)
            }
            "startPreview" -> startPreview(null, call, result)
            "stopPreview" -> {
                flCamera?.dispose()
                result.success(flCamera != null)
            }
            "setFlashMode" -> {
                val state = call.arguments as Int
                flCamera?.setFlashMode(state == 1)
                result.success(flCamera != null)
            }
            "setZoomRatio" -> {
                flCamera?.setZoomRatio((call.arguments as Double).toFloat())
                result.success(flCamera != null)
            }
            "dispose" -> {
                dispose()
                result.success(flCamera == null)
            }
            "startEvent" -> {
                initEvent()
                result.success(flCameraEvent != null)
            }
            "sendEvent" -> {
                flCameraEvent?.sendEvent(call.arguments)
                result.success(flCameraEvent != null)
            }
            "stopEvent" -> {
                disposeEvent()
                result.success(flCameraEvent == null)
            }
            else -> result.notImplemented()
        }
    }

    open fun disposeEvent() {
        flCameraEvent?.dispose()
        flCameraEvent = null
    }

    open fun dispose() {
        disposeEvent()
        flCamera?.dispose()
        flCamera = null
    }

    private fun initEvent() {
        if (flCameraEvent == null) {
            flCameraEvent = FlCameraEvent(plugin.binaryMessenger)
        }
    }

    open fun startPreview(
        imageAnalyzer: ImageAnalysis.Analyzer?, call: MethodCall, result: MethodChannel.Result
    ) {
        val resolution = call.argument<String>("resolution")
        val cameraId = call.argument<String>("cameraId")
        val previewSize = CameraTools.computeBestPreviewSize(cameraId!!, resolution!!)
        val cameraSelector = CameraTools.getCameraSelector(cameraId)
        flCamera?.initCameraX(
            previewSize, cameraSelector, result, imageAnalyzer
        )
    }
}