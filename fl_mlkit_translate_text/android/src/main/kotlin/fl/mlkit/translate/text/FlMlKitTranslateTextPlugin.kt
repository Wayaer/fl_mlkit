package fl.mlkit.translate.text

import androidx.annotation.NonNull
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.translate.*

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlMlKitTranslateTextPlugin */
class FlMlKitTranslateTextPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    private var options: TranslatorOptions? = null
    private var conditions: DownloadConditions? = null
    private var modelManager: RemoteModelManager? = null
    private var translator: Translator? = null
    private var currentSource = TranslateLanguage.ENGLISH
    private var currentTarget = TranslateLanguage.CHINESE


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl_mlkit_translate_text")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "translate" -> {
                val text = call.argument<String>("text")!!
                val downloadModelIfNeeded = call.argument<Boolean>("downloadModelIfNeeded")!!
                if (downloadModelIfNeeded) {
                    getTranslation().downloadModelIfNeeded(getConditions()).addOnSuccessListener {
                        getTranslation().translate(text).addOnSuccessListener { translatedText ->
                            result.success(translatedText)
                        }.addOnFailureListener {
                            result.success(null)
                        }
                    }.addOnFailureListener {
                        result.success(null)
                    }
                } else {
                    getTranslation().translate(text).addOnSuccessListener { translatedText ->
                        result.success(translatedText)
                    }.addOnFailureListener {
                        result.success(null)
                    }
                }
            }
            "switchLanguage" -> {
                val source = call.argument<String>("source")
                val target = call.argument<String>("target")
                dispose()
                currentSource = getTranslateLanguage(source!!)
                currentTarget = getTranslateLanguage(target!!)
                result.success(true)
            }
            "getCurrentLanguage" -> {
                val map = mapOf(
                    "source" to currentSource,
                    "target" to currentTarget,
                )
                result.success(map)
            }
            "getDownloadedModels" -> {
                getModelManager().getDownloadedModels(TranslateRemoteModel::class.java)
                    .addOnSuccessListener { models ->
                        result.success(models.map { model -> model.data })
                    }
                    .addOnFailureListener {
                        result.success(null)
                    }
            }
            "deleteDownloadedModel" -> {
                val model = getTranslateRemoteModel(call.arguments as String)
                getModelManager().deleteDownloadedModel(model).addOnSuccessListener {
                    result.success(true)
                }.addOnFailureListener {
                    result.success(false)
                }
            }
            "downloadedModel" -> {
                val model = getTranslateRemoteModel(call.arguments as String)
                getModelManager().download(model, getConditions()).addOnSuccessListener {
                    result.success(true)
                }.addOnFailureListener {
                    result.success(false)
                }
            }
            "isModelDownloaded" -> {
                val model = getTranslateRemoteModel(call.arguments as String)
                getModelManager().isModelDownloaded(model).addOnSuccessListener { hasModel ->
                    result.success(hasModel)
                }.addOnFailureListener {
                    result.success(false)
                }
            }
            "dispose" -> {
                dispose()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun dispose() {
        options = null
        conditions = null
        modelManager = null
        translator?.close()
        translator = null
    }


    private val TranslateRemoteModel.data: Map<String, Any?>
        get() = mapOf(
            "language" to language,
            "isBaseModel" to isBaseModel,
            "modelType" to modelType.name,
        )

    private fun getTranslateLanguage(language: String): String {
        return TranslateLanguage.fromLanguageTag(language)!!
    }

    private fun getTranslateRemoteModel(language: String): TranslateRemoteModel {
        val translateLanguage = getTranslateLanguage(language)
        return TranslateRemoteModel.Builder(translateLanguage).build()
    }

    private fun getConditions(): DownloadConditions {
        if (conditions == null) {
            conditions = DownloadConditions.Builder()
                .requireWifi()
                .build()
        }
        return conditions!!
    }

    private fun getModelManager(): RemoteModelManager {
        if (modelManager == null) {
            modelManager = RemoteModelManager.getInstance()
        }
        return modelManager!!
    }

    private fun getTranslation(): Translator {
        if (translator == null) {
            translator = Translation.getClient(getTranslatorOptions())
        }
        return translator!!
    }

    private fun getTranslatorOptions(): TranslatorOptions {
        if (options == null) {
            options = TranslatorOptions.Builder()
                .setSourceLanguage(currentSource)
                .setTargetLanguage(currentTarget)
                .build()
        }
        return options!!
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
