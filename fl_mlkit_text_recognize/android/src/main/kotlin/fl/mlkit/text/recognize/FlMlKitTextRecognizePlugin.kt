package fl.mlkit.text.recognize

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.Rect
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
import fl.channel.FlEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class FlMlKitTextRecognizePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var options: TextRecognizerOptionsInterface = TextRecognizerOptions.DEFAULT_OPTIONS
    private var recognizer: TextRecognizer? = null
    private var lastCurrentTime = 0L
    private var frequency: Long = 10L
    private var canRecognize: Boolean = true
    private var job: Job? = null
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl.mlkit.text.recognize")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @OptIn(DelicateCoroutinesApi::class)
    @SuppressLint("UnsafeOptInUsageError")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setParams" -> {
                frequency = call.argument<Int>("frequency")!!.toLong()
                canRecognize = call.argument<Boolean>("canRecognize")!!
                if (job == null) {
                    job = GlobalScope.launch {
                        FlCamera.flow?.collect { imageProxy ->
                            val mediaImage = imageProxy?.image
                            val currentTime = System.currentTimeMillis()
                            if (currentTime - lastCurrentTime >= frequency && mediaImage != null && canRecognize) {
                                val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                                analysis(inputImage, null, imageProxy)
                                lastCurrentTime = currentTime
                            } else {
                                imageProxy?.close()
                            }
                        }
                    }
                }
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
                job?.cancel()
                job = null;
                recognizer?.close()
                recognizer = null
                result.success(true)
            }

            else -> result.notImplemented()
        }

    }

    private fun recognizeImageByte(call: MethodCall, result: MethodChannel.Result) {
        val useEvent = call.argument<Boolean>("useEvent")!!
        val byteArray = call.argument<ByteArray>("byte")!!
        var rotationDegrees = call.argument<Int>("rotationDegrees")
        val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
        if (bitmap == null) {
            result.success(null)
            return
        }
        if (rotationDegrees == null) rotationDegrees = 0
        val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
        analysis(inputImage, if (useEvent) null else result, null)
    }

    private fun setRecognizedLanguage(call: MethodCall) {
        when (call.arguments as String) {
            "latin" -> options = TextRecognizerOptions.DEFAULT_OPTIONS
            "chinese" -> options = ChineseTextRecognizerOptions.Builder().build()
            "japanese" -> options = JapaneseTextRecognizerOptions.Builder().build()
            "korean" -> options = KoreanTextRecognizerOptions.Builder().build()
            "devanagari" -> options = DevanagariTextRecognizerOptions.Builder().build()
        }
    }

    private fun analysis(inputImage: InputImage, result: MethodChannel.Result?, imageProxy: ImageProxy?) {
        getTextRecognition().process(inputImage).addOnSuccessListener { visionText ->
            var width = inputImage.width
            var height = inputImage.height
            if (width > height) {
                width -= height
                height += width
                width = height - width
            }
            val map: MutableMap<String, Any?> = HashMap()
            map.putAll(visionText.data)
            map["width"] = width.toDouble()
            map["height"] = height.toDouble()
            if (result == null) {
                FlEvent.send(map)
            } else {
                result.success(map)
            }
        }.addOnFailureListener { result?.success(null) }.addOnCompleteListener { imageProxy?.close() }

    }

    private fun getTextRecognition(): TextRecognizer {
        if (recognizer == null) {
            recognizer = TextRecognition.getClient(options)
        }
        return recognizer!!
    }


    private val Text.data: Map<String, Any?>
        get() = mapOf("text" to text, "textBlocks" to textBlocks.map { textBlock -> textBlock.data })

    private val Text.TextBlock.data: Map<String, Any?>
        get() = mapOf(
                "text" to text,
                "recognizedLanguage" to recognizedLanguage,
                "boundingBox" to boundingBox?.data,
                "corners" to cornerPoints?.map { corner -> corner.data },
                "lines" to lines.map { line -> line.data },
        )
    private val Text.Element.data: Map<String, Any?>
        get() = mapOf(
                "text" to text,
                "recognizedLanguage" to recognizedLanguage,
                "boundingBox" to boundingBox?.data,
                "corners" to cornerPoints?.map { corner -> corner.data },
        )
    private val Text.Line.data: Map<String, Any?>
        get() = mapOf(
                "text" to text,
                "recognizedLanguage" to recognizedLanguage,
                "boundingBox" to boundingBox?.data,
                "corners" to cornerPoints?.map { corner -> corner.data },
                "elements" to elements.map { element -> element.data },
        )

    private val Rect.data: Map<String, Int>
        get() = mapOf("top" to top, "bottom" to bottom, "left" to left, "right" to right)

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())
}
