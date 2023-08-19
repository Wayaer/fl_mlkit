package fl.mlkit.text.recognize

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class FlMlKitTextRecognizePlugin : FlutterPlugin, ActivityAware {

    private lateinit var channel: MethodChannel
    private var plugin: FlutterPlugin.FlutterPluginBinding? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl.mlkit.text.recognize")
        plugin = flutterPluginBinding

    }


    override fun onAttachedToActivity(pluginBinding: ActivityPluginBinding) {
        channel.setMethodCallHandler(
            FlMlKitTextRecognizeMethodCall(
                pluginBinding.activity, plugin!!
            )
        )
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        plugin = null
    }

}
