package fl.mlkit.identify.language

import com.google.mlkit.nl.languageid.IdentifiedLanguage
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.languageid.LanguageIdentificationOptions
import com.google.mlkit.nl.languageid.LanguageIdentifier
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** 语言识别插件，负责识别器生命周期与置信度阈值设置。 */
class FlMlKitIdentifyLanguagePlugin : FlutterPlugin, MethodCallHandler {

    private var channel: MethodChannel? = null

    private var languageIdentifier: LanguageIdentifier? = null
    private var options: LanguageIdentificationOptions? = null
    private var currentConfidence: Float = 0.5f

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl_mlkit_identify_language")
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        dispose()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "identifyLanguage" -> {
                val text = call.arguments as? String
                if (text.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                getLanguageIdentification().identifyLanguage(text)
                    .addOnSuccessListener { languageCode ->
                        result.success(languageCode)
                    }.addOnFailureListener {
                        result.success(null)
                    }
            }

            "identifyPossibleLanguages" -> {
                val text = call.arguments as? String
                if (text.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                getLanguageIdentification().identifyPossibleLanguages(text)
                    .addOnSuccessListener { identifiedLanguages ->
                        result.success(identifiedLanguages.map { model -> model.data })
                    }.addOnFailureListener {
                        result.success(null)
                    }
            }

            "setConfidence" -> {
                val confidence = (call.arguments as? Number)?.toFloat()
                if (confidence == null || confidence < 0.01f || confidence > 1f) {
                    result.success(false)
                    return
                }
                currentConfidence = confidence
                dispose()
                result.success(true)
            }

            // Flutter StandardMessageCodec 不支持 Float，必须转为 Double。
            "getCurrentConfidence" -> result.success(currentConfidence.toDouble())

            "dispose" -> {
                dispose()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private val IdentifiedLanguage.data: Map<String, Any?>
        get() = mapOf(
            "languageTag" to languageTag,
            // Flutter StandardMessageCodec 不支持 Float，必须转为 Double。
            "confidence" to confidence.toDouble()
        )

    /** 释放识别器，设置置信度或退出时调用。 */
    private fun dispose() {
        options = null
        languageIdentifier?.close()
        languageIdentifier = null
    }

    private fun getLanguageIdentification(): LanguageIdentifier {
        val current = languageIdentifier
        if (current != null) return current
        return LanguageIdentification.getClient(getOptions()).also { languageIdentifier = it }
    }

    private fun getOptions(): LanguageIdentificationOptions {
        val current = options
        if (current != null) return current
        return LanguageIdentificationOptions.Builder()
            .setConfidenceThreshold(currentConfidence)
            .build()
            .also { options = it }
    }
}
