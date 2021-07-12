package fl.mlkit.scanning

import android.annotation.SuppressLint
import android.util.Log
import androidx.camera.core.ImageAnalysis
import com.google.mlkit.vision.common.InputImage
import fl.camera.FlCameraMethodCall
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlMlKitScanningMethodCall(
    activityPlugin: ActivityPluginBinding,
    plugin: FlutterPlugin.FlutterPluginBinding
) :
    FlCameraMethodCall(activityPlugin, plugin) {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i("flutter", call.method)
        when (call.method) {
            "startPreview" -> {
                Log.i("flutter", (flCameraEvent == null).toString())
                startPreview(imageAnalyzer, call, result)
            }
            else -> {
                super.onMethodCall(call, result)
            }
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private val imageAnalyzer = ImageAnalysis.Analyzer { imageProxy ->
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            val map: MutableMap<String, Any> = HashMap()
            map["width"] = imageProxy.width
            map["height"] = imageProxy.height
            Log.i("imageProxyflutter", (flCameraEvent == null).toString())
            flCameraEvent?.sendEvent(map)
        }
//        imageProxy.close()
    }

}