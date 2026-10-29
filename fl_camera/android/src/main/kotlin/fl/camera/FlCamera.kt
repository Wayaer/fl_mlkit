package fl.camera

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.media.CamcorderProfile
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Size
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageProxy
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import fl.channel.FlChannelPlugin
import fl.channel.FlDataStream
import fl.channel.FlDataStreamHandler
import fl.channel.FlDataStreamHandlerCancel
import fl.channel.FlEventChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * fl_camera 原生实现入口。
 *
 * 负责 MethodChannel 方法分发、摄像头枚举、预览尺寸计算，并向下游
 * （如 fl_mlkit_scanning / fl_mlkit_text_recognize）暴露图像数据流与事件通道。
 */
object FlCamera {
    /** 相机权限请求码，插件与 Activity 回调共用。 */
    const val CAMERA_PERMISSION_REQUEST_CODE = 0x43414D

    /** 默认事件通道名称。 */
    const val DEFAULT_EVENT_CHANNEL = "fl.camera.event"

    /** 相机图像数据流，供扫码、文字识别等插件订阅。 */
    var flDataStream = FlDataStream<ImageProxy>()

    /** 各控制器注册的事件通道，按通道名区分相机 / 扫码 / OCR。 */
    private val eventChannels = ConcurrentHashMap<String, FlEventChannel>()

    private var imageListenerCount = 0
    private var cameraX: FlCameraX? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /** 正在等待权限弹窗结果的 Flutter 回调。 */
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** 摄像头枚举与预览尺寸计算放在后台线程，避免阻塞 MethodChannel 主线程。 */
    private val queryExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    /** 是否存在图像订阅者；没有订阅者时不创建 ImageAnalysis，避免无谓的性能消耗。 */
    val hasImageListener: Boolean
        get() = imageListenerCount > 0

    /**
     * 订阅相机图像帧，返回取消订阅的函数。
     *
     * 内部维护订阅计数，用于决定是否启用 ImageAnalysis。
     * 若在预览启动后才订阅，会尝试给当前预览动态挂载 ImageAnalysis。
     */
    fun listenImageProxy(handler: FlDataStreamHandler<ImageProxy>): FlDataStreamHandlerCancel {
        val firstListener = imageListenerCount == 0
        imageListenerCount++
        val cancel = flDataStream.listen(handler)
        if (firstListener) cameraX?.attachImageAnalysis()
        var cancelled = false
        return {
            // 取消函数可能被下游重复调用，这里保证计数只减一次。
            if (!cancelled) {
                cancelled = true
                cancel()
                imageListenerCount = (imageListenerCount - 1).coerceAtLeast(0)
                // 没有订阅者后解绑 ImageAnalysis，避免继续以预览分辨率出帧并空转。
                if (imageListenerCount == 0) cameraX?.detachImageAnalysis()
            }
        }
    }

    /** 检查相机权限是否已授予。 */
    fun hasCameraPermission(activity: Activity): Boolean =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

    /**
     * 申请相机权限，只返回两种结果：授权成功或 FlutterError。
     *
     * 已有弹窗在等待结果时，本次请求直接返回失败，避免重复弹窗。
     */
    fun requestCameraPermission(activity: Activity, result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("permissionRequestInterrupted", "Camera permission request is already in progress.", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
    }

    /** Activity 权限回调入口：把结果转交给等待中的 Flutter 回调。 */
    fun onPermissionResult(granted: Boolean) {
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        if (granted) {
            result.success(true)
        } else {
            result.error("permissionDenied", "Camera permission has not been granted.", null)
        }
    }

    /** Activity 销毁时结束等待中的权限请求，避免 Flutter 回调一直挂起。 */
    fun cancelPendingPermission() {
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        result.error("permissionRequestInterrupted", "Camera permission request was interrupted.", null)
    }

    /** 注册控制器的事件通道，供发送相机事件时广播。 */
    fun registerEventChannel(name: String) {
        FlChannelPlugin.getEventChannel(name)?.let { eventChannels[name] = it }
    }

    /** 注销控制器的事件通道。 */
    fun unregisterEventChannel(name: String) {
        eventChannels.remove(name)
    }

    /** 向所有已注册的事件通道发送事件。 */
    fun sendEvent(data: Any?) {
        eventChannels.values.forEach { it.send(data) }
    }

    /** 向除 [excluded] 外的所有事件通道发送事件。 */
    fun sendEventExcept(excluded: String?, data: Any?) {
        eventChannels.forEach { (name, channel) ->
            if (name != excluded) channel.send(data)
        }
    }

    /** 释放相机并清空事件通道，供插件 detach 时调用。 */
    fun disposeAll() {
        cancelPendingPermission()
        disposeCamera()
        eventChannels.clear()
        // 不能重置 imageListenerCount：下游插件会缓存取消函数，重置后 hasImageListener
        // 变为 false 会导致下次预览不再创建 ImageAnalysis，扫码 / OCR 静默失效。
    }

    /** 仅释放相机，保留事件通道注册，供单个控制器 dispose 时调用。 */
    private fun releaseCamera() {
        cancelPendingPermission()
        disposeCamera()
    }

    /** 仅释放相机，保留事件通道，供 Activity 重建后复用。 */
    fun disposeCamera() {
        cameraX?.dispose()
        cameraX = null
    }

    fun binding(
        activity: Activity,
        pluginBinding: FlutterPlugin.FlutterPluginBinding
    ): MethodChannel {
        cameraX?.dispose()
        cameraX = FlCameraX(activity, pluginBinding.textureRegistry)
        val channel = MethodChannel(pluginBinding.binaryMessenger, "fl.camera")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "availableCameras" -> {
                    val context = activity.applicationContext
                    queryExecutor.execute {
                        val cameras = getAvailableCameras(context)
                        mainHandler.post { result.success(cameras) }
                    }
                }

                "initialize" -> {
                    // 每个控制器使用独立事件通道，初始化时重新注册。
                    val eventChannelName = call.argument<String>("eventChannelName") ?: DEFAULT_EVENT_CHANNEL
                    registerEventChannel(eventChannelName)
                    if (cameraX == null) {
                        cameraX = FlCameraX(activity, pluginBinding.textureRegistry)
                    }
                    // 未授权时由插件发起运行时权限申请，权限结果通过插件注册的回调回传。
                    if (hasCameraPermission(activity)) {
                        result.success(true)
                    } else {
                        requestCameraPermission(activity, result)
                    }
                }

                "startPreview" -> {
                    val resolution = call.argument<String>("resolution")
                    val cameraId = call.argument<String>("cameraId")
                    if (resolution == null || cameraId == null) {
                        result.error("invalidArguments", "cameraId and resolution are required.", null)
                        return@setMethodCallHandler
                    }
                    val camera = cameraX
                    if (camera == null) {
                        result.error("notInitialized", "Camera has not been initialized.", null)
                        return@setMethodCallHandler
                    }
                    queryExecutor.execute {
                        val previewSize = computeBestPreviewSize(cameraId, resolution)
                        val cameraSelector = getCameraSelector(cameraId)
                        mainHandler.post {
                            if (cameraX !== camera) {
                                // 计算期间已被 stopPreview / dispose。
                                result.success(null)
                                return@post
                            }
                            camera.initCameraX(previewSize, cameraSelector, result) { imageProxy ->
                                flDataStream.send(imageProxy)
                            }
                        }
                    }
                }

                "stopPreview" -> {
                    val camera = cameraX
                    if (camera == null) {
                        result.success(false)
                    } else {
                        camera.dispose()
                        result.success(true)
                    }
                }

                "setFlashMode" -> {
                    val state = call.arguments as? Int
                    val camera = cameraX
                    if (state == null || camera == null) {
                        result.success(false)
                    } else {
                        // 0 = off, 1 = on, 2 = auto；Android 仅支持开关，auto 按关闭处理
                        result.success(camera.setFlashMode(state == 1))
                    }
                }

                "setZoomRatio" -> {
                    val ratio = call.arguments as? Double
                    val camera = cameraX
                    if (ratio == null || camera == null) {
                        result.success(false)
                    } else {
                        result.success(camera.setZoomRatio(ratio.toFloat()))
                    }
                }

                "dispose" -> {
                    val eventChannelName = call.argument<String>("eventChannelName") ?: DEFAULT_EVENT_CHANNEL
                    // 原生相机只能有一个，释放后通知其他仍挂载的控制器重新初始化。
                    sendEventExcept(eventChannelName, mapOf("disposed" to true))
                    unregisterEventChannel(eventChannelName)
                    releaseCamera()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
        return channel
    }

    private fun getAvailableCameras(context: Context): List<Map<String, Any>> {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameras: MutableList<Map<String, Any>> = ArrayList()
        for (cameraName in cameraManager.cameraIdList) {
            val details = HashMap<String, Any>()
            val characteristics = try {
                cameraManager.getCameraCharacteristics(cameraName)
            } catch (error: Exception) {
                null
            } ?: continue
            details["name"] = cameraName
            when (characteristics.get(CameraCharacteristics.LENS_FACING)) {
                CameraMetadata.LENS_FACING_FRONT -> details["lensFacing"] = "front"
                CameraMetadata.LENS_FACING_BACK -> details["lensFacing"] = "back"
                CameraMetadata.LENS_FACING_EXTERNAL -> details["lensFacing"] = "external"
                else -> details["lensFacing"] = "external"
            }
            cameras.add(details)
        }
        return cameras
    }

    /**
     * 根据预设分辨率，返回设备支持的预览尺寸。
     *
     * 依次尝试预设中的档位，取第一个设备支持的档位；全部不支持时抛出异常。
     */
    private fun getBestAvailablePreviewSize(cameraId: String, preset: String): Size {
        val id = cameraId.toIntOrNull() ?: throw IllegalArgumentException("Camera id is not numeric.")
        val qualities = when (preset) {
            "max" -> intArrayOf(
                CamcorderProfile.QUALITY_HIGH,
                CamcorderProfile.QUALITY_2160P,
                CamcorderProfile.QUALITY_1080P,
                CamcorderProfile.QUALITY_720P,
                CamcorderProfile.QUALITY_480P,
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            "ultraHigh" -> intArrayOf(
                CamcorderProfile.QUALITY_2160P,
                CamcorderProfile.QUALITY_1080P,
                CamcorderProfile.QUALITY_720P,
                CamcorderProfile.QUALITY_480P,
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            "veryHigh" -> intArrayOf(
                CamcorderProfile.QUALITY_1080P,
                CamcorderProfile.QUALITY_720P,
                CamcorderProfile.QUALITY_480P,
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            "high" -> intArrayOf(
                CamcorderProfile.QUALITY_720P,
                CamcorderProfile.QUALITY_480P,
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            "medium" -> intArrayOf(
                CamcorderProfile.QUALITY_480P,
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            "low" -> intArrayOf(
                CamcorderProfile.QUALITY_QVGA,
                CamcorderProfile.QUALITY_LOW
            )

            else -> intArrayOf(CamcorderProfile.QUALITY_LOW)
        }
        for (quality in qualities) {
            if (CamcorderProfile.hasProfile(id, quality)) {
                return getCamcorderPreviewSize(cameraId, quality)
            }
        }
        throw IllegalArgumentException("No capture session available for current capture session.")
    }

    /** API 31 起使用非弃用的 EncoderProfiles，低版本回退到旧的 CamcorderProfile 接口。 */
    private fun getCamcorderPreviewSize(cameraId: String, quality: Int): Size {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val profiles = CamcorderProfile.getAll(cameraId, quality)
            val videoProfile = profiles?.videoProfiles?.firstOrNull()
            if (videoProfile != null) return Size(videoProfile.height, videoProfile.width)
            throw IllegalArgumentException("No camcorder profile for quality $quality.")
        }
        return getLegacyCamcorderPreviewSize(cameraId.toInt(), quality)
    }

    @Suppress("DEPRECATION")
    private fun getLegacyCamcorderPreviewSize(cameraId: Int, quality: Int): Size {
        val profile = CamcorderProfile.get(cameraId, quality)
            ?: throw IllegalArgumentException("No camcorder profile for quality $quality.")
        return Size(profile.videoFrameHeight, profile.videoFrameWidth)
    }

    /** 计算预览尺寸；部分设备摄像头 ID 非数字，使用预设尺寸兜底。 */
    private fun computeBestPreviewSize(cameraId: String, preset: String): Size {
        try {
            return getBestAvailablePreviewSize(cameraId, preset)
        } catch (_: Exception) {
            // 忽略并使用兜底尺寸
        }
        return when (preset) {
            "low" -> Size(288, 352)
            "medium" -> Size(480, 640)
            "high" -> Size(720, 1280)
            "veryHigh" -> Size(1080, 1920)
            "ultraHigh" -> Size(2160, 3840)
            else -> Size(720, 1280)
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun getCameraSelector(cameraId: String): CameraSelector =
        CameraSelector.Builder().addCameraFilter { cameras ->
            cameras.filter { cameraId == Camera2CameraInfo.from(it).cameraId }
        }.build()
}
