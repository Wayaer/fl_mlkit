package fl.mlkit.identify.language

import androidx.annotation.NonNull
import com.google.mlkit.nl.languageid.IdentifiedLanguage
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.languageid.LanguageIdentificationOptions
import com.google.mlkit.nl.languageid.LanguageIdentifier

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlMlKitIdentifyLanguagePlugin */
class FlMlKitIdentifyLanguagePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    private var languageIdentifier: LanguageIdentifier? = null
    private var options: LanguageIdentificationOptions? = null
    private var currentConfidence: Float = 0.5f

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl_mlkit_identify_language")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "identifyLanguage" -> {
                val text = call.arguments as String
                getLanguageIdentification().identifyLanguage(text)
                    .addOnSuccessListener { languageCode ->
                        result.success(languageCode)
                    }.addOnFailureListener {
                        result.success(null)
                    }
            }
            "identifyPossibleLanguages" -> {
                val text = call.arguments as String
                getLanguageIdentification().identifyPossibleLanguages(text)
                    .addOnSuccessListener { identifiedLanguages ->
                        result.success(identifiedLanguages.map { model -> model.data })
                    }.addOnFailureListener {
                        result.success(null)
                    }
            }
            "setConfidence" -> {
                currentConfidence = (call.arguments as Double).toFloat()
                dispose()
                result.success(true)
            }
            "getCurrentConfidence" -> result.success(currentConfidence)
            "dispose" -> {
                dispose()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private val IdentifiedLanguage.data: Map<String, Any?>
        get() = mapOf(
            "languageTag" to languageTag,
            "confidence" to confidence,
        )

    private fun dispose() {
        options = null
        languageIdentifier?.close()
        languageIdentifier = null
    }


    private fun getLanguageIdentification(): LanguageIdentifier {
        if (languageIdentifier == null) {
            languageIdentifier = LanguageIdentification.getClient(getOptions())
        }
        return languageIdentifier!!
    }

    private fun getOptions(): LanguageIdentificationOptions {
        if (options == null) {
            options = LanguageIdentificationOptions.Builder()
                .setConfidenceThreshold(currentConfidence)
                .build()
        }
        return options!!
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
