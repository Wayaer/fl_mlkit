package fl.camera

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.util.Size
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.TorchState
import androidx.camera.core.UseCase
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * CameraX 封装。
 *
 * 每次 [initCameraX] 都会重新创建纹理并绑定生命周期；
 * 没有图像订阅者时不会创建 ImageAnalysis，以降低 CPU 与内存开销。
 */
class FlCameraX(
    private val activity: Activity,
    private val textureRegistry: TextureRegistry,
) {
    private val mainExecutor = ContextCompat.getMainExecutor(activity)
    private val lifecycleOwner: LifecycleOwner? = activity as? LifecycleOwner
    private var cameraProvider: ProcessCameraProvider? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var camera: Camera? = null
    private var analysisExecutor: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var preview: Preview? = null
    private var cameraSelector: CameraSelector? = null
    private var owner: LifecycleOwner? = null
    private var requestedPreviewSize: Size? = null
    private var imageAnalyzer: ImageAnalysis.Analyzer? = null
    private var analysis: ImageAnalysis? = null

    /** 初始化序号，用于丢弃 stop / dispose 之后才返回的异步初始化结果。 */
    private var generation = 0

    private fun checkPermission(): Boolean =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

    /** 图像分析使用独立后台线程，避免占用主线程。 */
    private fun getAnalysisExecutor(): ExecutorService {
        val current = analysisExecutor
        if (current != null && !current.isShutdown) return current
        return Executors.newSingleThreadExecutor().also { analysisExecutor = it }
    }

    @SuppressLint("RestrictedApi")
    fun initCameraX(
        previewSize: Size,
        cameraSelector: CameraSelector,
        result: MethodChannel.Result,
        imageAnalyzer: ImageAnalysis.Analyzer? = null
    ) {
        if (!checkPermission()) {
            result.error("permissionDenied", "Camera permission has not been granted.", null)
            return
        }
        val currentGeneration = ++generation
        val providerFuture = ProcessCameraProvider.getInstance(activity)
        providerFuture.addListener({
            if (currentGeneration != generation) {
                // 已 stopPreview / dispose，丢弃这次初始化结果。
                result.success(null)
                return@addListener
            }
            try {
                val owner = lifecycleOwner ?: throw IllegalStateException("Activity is not a LifecycleOwner")
                val provider = providerFuture.get()
                cameraProvider = provider
                if (!provider.hasCamera(cameraSelector)) {
                    result.error("cameraNotFound", "No camera matches the requested id.", null)
                    return@addListener
                }
                provider.unbindAll()
                releaseTexture()
                val surfaceTextureEntry = textureRegistry.createSurfaceTexture()
                textureEntry = surfaceTextureEntry
                val surfaceProvider = Preview.SurfaceProvider { request ->
                    try {
                        val texture = surfaceTextureEntry.surfaceTexture()
                        val resolution = request.resolution
                        texture.setDefaultBufferSize(resolution.width, resolution.height)
                        val surface = Surface(texture)
                        request.provideSurface(surface, mainExecutor) { surface.release() }
                    } catch (error: Exception) {
                        // 纹理可能已被 stopPreview / dispose 释放，避免向已释放的纹理提供画面。
                        Log.e("fl_camera", "provideSurface failed", error)
                        request.willNotProvideSurface()
                    }
                }
                val preview = Preview.Builder()
                    .setResolutionSelector(createResolutionSelector(previewSize))
                    .build()
                    .apply { setSurfaceProvider(surfaceProvider) }
                this.owner = owner
                this.cameraSelector = cameraSelector
                this.requestedPreviewSize = previewSize
                this.imageAnalyzer = imageAnalyzer
                this.preview = preview

                val useCases = mutableListOf<UseCase>(preview)
                createAnalysis(previewSize)?.let { useCases.add(it) }

                camera = provider.bindToLifecycle(
                    owner,
                    cameraSelector,
                    *useCases.toTypedArray()
                )
                observeCameraState(owner)

                val resolution = preview.attachedSurfaceResolution ?: previewSize
                val portrait = camera?.cameraInfo?.sensorRotationDegrees?.let { it % 180 == 0 } ?: true
                val width = resolution.width.toDouble()
                val height = resolution.height.toDouble()
                result.success(
                    mapOf(
                        "textureId" to surfaceTextureEntry.id(),
                        "width" to if (portrait) width else height,
                        "height" to if (portrait) height else width
                    )
                )
            } catch (error: Exception) {
                Log.e("fl_camera", "initCameraX failed", error)
                try {
                    cameraProvider?.unbindAll()
                } catch (_: Exception) {
                    // 忽略重复解绑异常
                }
                releaseTexture()
                camera = null
                cameraProvider = null
                analysis = null
                preview = null
                result.error("cameraInitFailed", error.message ?: "Camera initialization failed.", null)
            }
        }, mainExecutor)
    }

    /** 创建（或复用）ImageAnalysis；没有图像订阅者时不创建。 */
    private fun createAnalysis(size: Size): ImageAnalysis? {
        val analyzer = imageAnalyzer ?: return null
        if (!FlCamera.hasImageListener) return null
        analysis?.let { return it }
        val created = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setResolutionSelector(createResolutionSelector(size))
            .build()
            .apply {
                setAnalyzer(getAnalysisExecutor()) { imageProxy ->
                    if (FlCamera.hasImageListener) {
                        analyzer.analyze(imageProxy)
                    } else {
                        imageProxy.close()
                    }
                }
            }
        analysis = created
        return created
    }

    /**
     * 预览启动后再注册图像监听时，重新绑定并挂载 ImageAnalysis。
     *
     * CameraX 不支持单独追加 UseCase，这里会短暂 unbind 再 bind；
     * 纹理保持不变，Flutter 侧不会切换 textureId。
     */
    fun attachImageAnalysis() {
        mainHandler.post {
            val owner = owner ?: return@post
            val provider = cameraProvider ?: return@post
            val preview = preview ?: return@post
            val selector = cameraSelector ?: return@post
            val size = requestedPreviewSize ?: return@post
            if (analysis != null) return@post
            val analysis = createAnalysis(size) ?: return@post
            // 重绑会重置闪光灯与缩放，先记录用户当前设置，绑定后恢复。
            val wasTorchOn = camera?.cameraInfo?.torchState?.value == TorchState.ON
            val previousZoom = camera?.cameraInfo?.zoomState?.value?.zoomRatio
            try {
                provider.unbindAll()
                camera = provider.bindToLifecycle(owner, selector, preview, analysis)
                observeCameraState(owner)
            } catch (error: Exception) {
                Log.e("fl_camera", "attachImageAnalysis failed", error)
                this.analysis = null
                try {
                    camera = provider.bindToLifecycle(owner, selector, preview)
                    observeCameraState(owner)
                } catch (restoreError: Exception) {
                    Log.e("fl_camera", "restore preview failed", restoreError)
                }
            }
            camera?.cameraControl?.enableTorch(wasTorchOn)
            previousZoom?.let { camera?.cameraControl?.setZoomRatio(it) }
        }
    }

    /**
     * 订阅者全部取消后解绑 ImageAnalysis。
     *
     * 只解绑分析用例，预览与纹理保持不变，不会闪黑帧，也不会重置闪光灯与缩放。
     */
    fun detachImageAnalysis() {
        mainHandler.post {
            val current = analysis ?: return@post
            analysis = null
            try {
                cameraProvider?.unbind(current)
            } catch (error: Exception) {
                Log.e("fl_camera", "detachImageAnalysis failed", error)
            }
        }
    }

    /** 监听闪光灯与缩放状态；重复调用前会先移除旧监听，避免泄漏。 */
    private fun observeCameraState(owner: LifecycleOwner) {
        val cameraInfo = camera?.cameraInfo ?: return
        cameraInfo.torchState.removeObservers(owner)
        cameraInfo.zoomState.removeObservers(owner)
        cameraInfo.torchState.observe(owner) { state ->
            // TorchState.OFF = 0; TorchState.ON = 1
            FlCamera.sendEvent(mapOf("flash" to state))
        }
        cameraInfo.zoomState.observe(owner) { state ->
            // CameraX 返回 Float，StandardMessageCodec 只支持 Double，必须先转换。
            FlCamera.sendEvent(
                mapOf(
                    "maxZoomRatio" to state.maxZoomRatio.toDouble(),
                    "zoomRatio" to state.zoomRatio.toDouble()
                )
            )
        }
    }

    /**
     * 打开或关闭闪光灯。
     *
     * @return 设备无闪光灯或相机未初始化时返回 false。
     */
    fun setFlashMode(state: Boolean): Boolean {
        val current = camera ?: return false
        if (!current.cameraInfo.hasFlashUnit()) return false
        current.cameraControl.enableTorch(state)
        return true
    }

    /**
     * 设置缩放比例，超出范围时由 CameraX 自动收敛到合法区间。
     *
     * @return 相机未初始化时返回 false。
     */
    fun setZoomRatio(ratio: Float): Boolean {
        val current = camera ?: return false
        current.cameraControl.setZoomRatio(ratio)
        return true
    }

    /** 解绑所有用例并释放纹理。 */
    fun dispose() {
        generation++
        val currentOwner = lifecycleOwner
        val cameraInfo = camera?.cameraInfo
        if (currentOwner != null) {
            cameraInfo?.torchState?.removeObservers(currentOwner)
            cameraInfo?.zoomState?.removeObservers(currentOwner)
        }
        try {
            cameraProvider?.unbindAll()
        } catch (_: Exception) {
            // 忽略重复解绑异常
        }
        releaseTexture()
        analysisExecutor?.shutdown()
        analysisExecutor = null
        analysis = null
        preview = null
        cameraSelector = null
        owner = null
        requestedPreviewSize = null
        imageAnalyzer = null
        camera = null
        cameraProvider = null
    }

    /** 构建分辨率选择器：优先选择与目标尺寸最接近的档位。 */
    private fun createResolutionSelector(size: Size): ResolutionSelector =
        ResolutionSelector.Builder()
            .setResolutionStrategy(
                ResolutionStrategy(size, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER)
            )
            .build()

    private fun releaseTexture() {
        textureEntry?.release()
        textureEntry = null
    }
}
