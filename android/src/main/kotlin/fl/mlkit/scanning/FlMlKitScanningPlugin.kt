package fl.mlkit.scanning

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel


class FlMlKitScanningPlugin : FlutterPlugin, ActivityAware {

    private lateinit var channel: MethodChannel
    private var plugin: FlutterPlugin.FlutterPluginBinding? = null


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl.mlkit.scanning")
        plugin = flutterPluginBinding
    }


    override fun onAttachedToActivity(pluginBinding: ActivityPluginBinding) {
        channel.setMethodCallHandler(FlMlKitScanningMethodCall(pluginBinding, plugin!!))
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        plugin = null
    }

}
