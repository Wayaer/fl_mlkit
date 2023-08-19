package fl.camera

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class FlCameraPlugin : FlutterPlugin, ActivityAware {

    private lateinit var channel: MethodChannel
    private var plugin: FlutterPlugin.FlutterPluginBinding? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fl.camera")
        plugin = flutterPluginBinding
    }


    override fun onAttachedToActivity(pluginBinding: ActivityPluginBinding) {
        channel.setMethodCallHandler(FlCameraMethodCall(pluginBinding.activity, plugin!!))
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }


    override fun onDetachedFromActivity() {

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        plugin = null
    }
}
