package fl.camera

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Size
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class FlCameraX(
    private val activity: Activity,
    private val textureRegistry: TextureRegistry,
    private val flCameraEvent: FlCameraEvent
) {
    private val executor = ContextCompat.getMainExecutor(activity)
    private var cameraProvider: ProcessCameraProvider? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var camera: Camera? = null

    private fun checkPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("RestrictedApi")
    fun initCameraX(
        previewSize: Size,
        cameraSelector: CameraSelector,
        result: MethodChannel.Result,
        imageAnalyzer: ImageAnalysis.Analyzer?
    ) {
        if (!checkPermission()) {
            result.success(null)
            return
        }
        val provider = ProcessCameraProvider.getInstance(activity)
        provider.addListener({
            cameraProvider = provider.get()
            textureEntry = textureRegistry.createSurfaceTexture()
            val surfaceProvider = Preview.SurfaceProvider { request ->
                val texture = textureEntry!!.surfaceTexture()
                val resolution = request.resolution
                texture.setDefaultBufferSize(
                    resolution.width, resolution.height
                )
                val surface = Surface(texture)
                request.provideSurface(surface, executor) { }
            }
            val preview = Preview.Builder().setTargetResolution(previewSize).build()
                .apply { setSurfaceProvider(surfaceProvider) }
            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setTargetResolution(previewSize).build().apply {
                    if (imageAnalyzer != null) {
                        setAnalyzer(executor, imageAnalyzer)
                    }
                }
            val owner = activity as LifecycleOwner
            try {
                cameraProvider!!.unbindAll()
                camera = cameraProvider!!.bindToLifecycle(
                    owner, cameraSelector, preview, analysis
                )
                camera!!.cameraInfo.torchState.observe(owner) { state ->
                    // TorchState.OFF = 0; TorchState.ON = 1
                    flCameraEvent.sendEvent(mapOf("flash" to state))
                }
                camera!!.cameraInfo.zoomState.observe(owner) { state ->
                    flCameraEvent.sendEvent(
                        mapOf(
                            "maxZoomRatio" to state.maxZoomRatio, "zoomRatio" to state.zoomRatio
                        )
                    )
                }
                val resolution = preview.attachedSurfaceResolution!!
                val map: MutableMap<String, Any> = HashMap()
                val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
                val w = resolution.width.toDouble()
                val h = resolution.height.toDouble()
                map["textureId"] = textureEntry!!.id()
                if (portrait) {
                    map["width"] = w
                    map["height"] = h
                } else {
                    map["width"] = h
                    map["height"] = w
                }
                result.success(map)

            } catch (e: Exception) {
                result.success(null)
            }
        }, executor)
    }

    fun setFlashMode(state: Boolean) {
        camera?.cameraControl?.enableTorch(state)
    }

    fun setZoomRatio(ratio: Float) {
        camera?.cameraControl?.setZoomRatio(ratio)
    }

    fun dispose() {
        val owner = activity as LifecycleOwner
        camera?.cameraInfo?.torchState?.removeObservers(owner)
        camera?.cameraInfo?.zoomState?.removeObservers(owner)
        cameraProvider?.unbindAll()
        textureEntry?.release()
        camera = null
        textureEntry = null
        cameraProvider = null
    }

}
