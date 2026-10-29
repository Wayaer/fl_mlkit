package fl.mlkit.text.recognize

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.TextRecognizerOptionsInterface
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import fl.camera.FlCamera
import fl.channel.FlChannelPlugin
import fl.channel.FlDataStreamHandlerCancel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 文字识别插件。
 *
 * 相机帧来自 fl_camera 的 FlDataStream；图片识别在后台线程解码，
 * 识别结果通过 MethodChannel 或事件通道返回。
 */
class FlMlKitTextRecognizePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private companion object {
        /** 识别结果事件通道，与相机通道区分。 */
        const val EVENT_CHANNEL_NAME = "fl.camera.ocr.event"
    }

    private var channel: MethodChannel? = null
    private var options: TextRecognizerOptionsInterface = TextRecognizerOptions.DEFAULT_OPTIONS
    private var recognizer: TextRecognizer? = null
    private var lastCurrentTime = 0L
    private var frequency = 500L
    private var canRecognize = true
    private var imageProxyHandler: FlDataStreamHandlerCancel? = null
    private val decoder = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl.mlkit.text.recognize")
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        releaseResources()
        decoder.shutdown()
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setParams" -> {
                frequency = (call.argument<Number>("frequency"))?.toLong() ?: 500L
                canRecognize = call.argument<Boolean>("canRecognize") ?: true
                ensureImageListener()
                result.success(true)
            }

            "recognizeImageByte" -> recognizeImageByte(call, result)

            "setRecognizedLanguage" -> {
                setRecognizedLanguage(call)
                recognizer?.close()
                recognizer = null
                result.success(true)
            }

            "dispose" -> {
                releaseResources()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    /** 仅注册一次相机帧监听，参数变化时无需反复注册。 */
    private fun ensureImageListener() {
        if (imageProxyHandler != null) return
        imageProxyHandler = FlCamera.listenImageProxy { imageProxy ->
            val mediaImage = imageProxy.image
            val currentTime = System.currentTimeMillis()
            if (mediaImage != null && canRecognize && currentTime - lastCurrentTime >= frequency) {
                lastCurrentTime = currentTime
                val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                analysis(inputImage, null, imageProxy)
            } else {
                imageProxy.close()
            }
        }
    }

    private fun releaseResources() {
        imageProxyHandler?.invoke()
        imageProxyHandler = null
        recognizer?.close()
        recognizer = null
        lastCurrentTime = 0
    }

    private fun recognizeImageByte(call: MethodCall, result: MethodChannel.Result) {
        val byteArray = call.argument<ByteArray>("byte")
        if (byteArray == null) {
            result.success(null)
            return
        }
        val rotationDegrees = (call.argument<Number>("rotationDegrees"))?.toInt() ?: 0
        decoder.execute {
            val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
            if (bitmap == null) {
                mainHandler.post { result.success(null) }
                return@execute
            }
            val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
            analysis(inputImage, result)
        }
    }

    private fun setRecognizedLanguage(call: MethodCall) {
        options = when (call.arguments as? String) {
            "chinese" -> ChineseTextRecognizerOptions.Builder().build()
            "japanese" -> JapaneseTextRecognizerOptions.Builder().build()
            "korean" -> KoreanTextRecognizerOptions.Builder().build()
            "devanagari" -> DevanagariTextRecognizerOptions.Builder().build()
            else -> TextRecognizerOptions.DEFAULT_OPTIONS
        }
    }

    private fun analysis(
        inputImage: InputImage,
        result: MethodChannel.Result? = null,
        imageProxy: ImageProxy? = null
    ) {
        getTextRecognition().process(inputImage).addOnSuccessListener { visionText ->
            // ML Kit 的坐标基于旋转后的图片，InputImage 的宽高是未旋转的原始尺寸。
            val rotation = ((inputImage.rotationDegrees % 360) + 360) % 360
            val swap = rotation == 90 || rotation == 270
            val width = if (swap) inputImage.height else inputImage.width
            val height = if (swap) inputImage.width else inputImage.height
            val map: MutableMap<String, Any?> = HashMap()
            map.putAll(visionText.data)
            map["width"] = width.toDouble()
            map["height"] = height.toDouble()
            if (result == null) {
                sendEvent(map)
            } else {
                result.success(map)
            }
        }.addOnFailureListener {
            result?.success(null)
        }.addOnCompleteListener {
            imageProxy?.close()
        }
    }

    /** 识别结果使用独立的事件通道，避免与相机 / 扫码控制器共用同一通道。 */
    private fun sendEvent(data: Any?) {
        FlChannelPlugin.getEventChannel(EVENT_CHANNEL_NAME)?.send(data)
    }

    private fun getTextRecognition(): TextRecognizer {
        val current = recognizer
        if (current != null) return current
        return TextRecognition.getClient(options).also { recognizer = it }
    }

    private val Text.data: Map<String, Any?>
        get() = mapOf(
            "text" to text,
            "textBlocks" to textBlocks.map { textBlock -> textBlock.data }
        )

    private val Text.TextBlock.data: Map<String, Any?>
        get() = mapOf(
            "text" to text,
            "recognizedLanguage" to recognizedLanguage,
            "boundingBox" to boundingBox?.data,
            "corners" to cornerPoints?.map { corner -> corner.data },
            "lines" to lines.map { line -> line.data }
        )

    private val Text.Element.data: Map<String, Any?>
        get() = mapOf(
            "text" to text,
            "recognizedLanguage" to recognizedLanguage,
            "boundingBox" to boundingBox?.data,
            "corners" to cornerPoints?.map { corner -> corner.data }
        )

    private val Text.Line.data: Map<String, Any?>
        get() = mapOf(
            "text" to text,
            "recognizedLanguage" to recognizedLanguage,
            "boundingBox" to boundingBox?.data,
            "corners" to cornerPoints?.map { corner -> corner.data },
            "elements" to elements.map { element -> element.data }
        )

    private val Rect.data: Map<String, Int>
        get() = mapOf("top" to top, "bottom" to bottom, "left" to left, "right" to right)

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())
}
