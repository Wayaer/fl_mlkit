package fl.mlkit.translate.text

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * 文本翻译插件。
 *
 * 负责翻译器生命周期、模型下载/删除/查询，以及语言切换。
 * 模型下载默认不限制网络类型，可通过 requireWifi 参数限制为仅 WiFi。
 */
class FlMlKitTranslateTextPlugin : FlutterPlugin, MethodCallHandler {

    private var channel: MethodChannel? = null

    private var options: TranslatorOptions? = null
    private var modelManager: RemoteModelManager? = null
    private var translator: Translator? = null
    private var currentSource = TranslateLanguage.ENGLISH
    private var currentTarget = TranslateLanguage.CHINESE

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "fl_mlkit_translate_text")
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        dispose()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "translate" -> {
                val text = call.argument<String>("text")
                if (text.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                val downloadModelIfNeeded = call.argument<Boolean>("downloadModelIfNeeded") ?: false
                val requireWifi = call.argument<Boolean>("requireWifi") ?: false
                // 提前持有当前翻译器，下载 / 翻译期间切换语言不会影响本次调用的语言对。
                val translator = getTranslation()
                if (downloadModelIfNeeded) {
                    translator.downloadModelIfNeeded(getConditions(requireWifi))
                        .addOnSuccessListener {
                            translator.translate(text).addOnSuccessListener { translatedText ->
                                result.success(translatedText)
                            }.addOnFailureListener {
                                result.success(null)
                            }
                        }.addOnFailureListener {
                            result.success(null)
                        }
                } else {
                    translator.translate(text).addOnSuccessListener { translatedText ->
                        result.success(translatedText)
                    }.addOnFailureListener {
                        result.success(null)
                    }
                }
            }

            "switchLanguage" -> {
                val source = getTranslateLanguage(call.argument<String>("source"))
                val target = getTranslateLanguage(call.argument<String>("target"))
                if (source == null || target == null || source == target) {
                    result.success(false)
                    return
                }
                dispose()
                currentSource = source
                currentTarget = target
                result.success(true)
            }

            "getCurrentLanguage" -> {
                result.success(mapOf("source" to currentSource, "target" to currentTarget))
            }

            "getDownloadedModels" -> {
                getModelManager().getDownloadedModels(TranslateRemoteModel::class.java)
                    .addOnSuccessListener { models ->
                        result.success(models.map { model -> model.data })
                    }.addOnFailureListener {
                        result.success(null)
                    }
            }

            "deleteDownloadedModel" -> {
                val model = getTranslateRemoteModel(call.arguments as? String)
                if (model == null) {
                    result.success(false)
                    return
                }
                getModelManager().deleteDownloadedModel(model).addOnSuccessListener {
                    result.success(true)
                }.addOnFailureListener {
                    result.success(false)
                }
            }

            "downloadedModel" -> {
                val language = parseLanguageArgument(call) ?: run {
                    result.success(false)
                    return
                }
                val requireWifi = call.argument<Boolean>("requireWifi") ?: false
                val model = getTranslateRemoteModel(language)
                if (model == null) {
                    result.success(false)
                    return
                }
                getModelManager().download(model, getConditions(requireWifi))
                    .addOnSuccessListener {
                        result.success(true)
                    }.addOnFailureListener {
                        result.success(false)
                    }
            }

            "isModelDownloaded" -> {
                val model = getTranslateRemoteModel(call.arguments as? String)
                if (model == null) {
                    result.success(false)
                    return
                }
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

            else -> result.notImplemented()
        }
    }

    /** 释放翻译器与可回收的原生对象。 */
    private fun dispose() {
        options = null
        translator?.close()
        translator = null
    }

    private val TranslateRemoteModel.data: Map<String, Any?>
        get() = mapOf(
            "language" to language,
            "isBaseModel" to isBaseModel,
            "modelType" to modelType.name
        )

    private fun parseLanguageArgument(call: MethodCall): String? {
        val arguments = call.arguments
        val language = if (arguments is Map<*, *>) arguments["language"] as? String else arguments as? String
        return getTranslateLanguage(language)
    }

    private fun getTranslateLanguage(language: String?): String? {
        if (language == null) return null
        return TranslateLanguage.fromLanguageTag(language)
    }

    private fun getTranslateRemoteModel(language: String?): TranslateRemoteModel? {
        val translateLanguage = getTranslateLanguage(language) ?: return null
        return TranslateRemoteModel.Builder(translateLanguage).build()
    }

    private fun getConditions(requireWifi: Boolean): DownloadConditions {
        val builder = DownloadConditions.Builder()
        if (requireWifi) builder.requireWifi()
        return builder.build()
    }

    private fun getModelManager(): RemoteModelManager {
        val current = modelManager
        if (current != null) return current
        return RemoteModelManager.getInstance().also { modelManager = it }
    }

    private fun getTranslation(): Translator {
        val current = translator
        if (current != null) return current
        return Translation.getClient(getTranslatorOptions()).also { translator = it }
    }

    private fun getTranslatorOptions(): TranslatorOptions {
        val current = options
        if (current != null) return current
        return TranslatorOptions.Builder()
            .setSourceLanguage(currentSource)
            .setTargetLanguage(currentTarget)
            .build()
            .also { options = it }
    }
}
