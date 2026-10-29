package fl.camera

import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class FlCameraPlugin : FlutterPlugin, ActivityAware {

    private var channel: MethodChannel? = null
    private var plugin: FlutterPlugin.FlutterPluginBinding? = null
    private var activityBinding: ActivityPluginBinding? = null

    /** 相机权限申请结果回调，交回 [FlCamera] 处理。 */
    private val permissionResultListener =
        PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode == FlCamera.CAMERA_PERMISSION_REQUEST_CODE) {
                FlCamera.onPermissionResult(
                    grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                )
                true
            } else {
                false
            }
        }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        plugin = flutterPluginBinding
    }

    override fun onAttachedToActivity(pluginBinding: ActivityPluginBinding) {
        activityBinding = pluginBinding
        pluginBinding.addRequestPermissionsResultListener(permissionResultListener)
        val binding = plugin ?: return
        channel = FlCamera.binding(pluginBinding.activity, binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = null
        // Activity 即将销毁，结束挂起的权限请求并释放相机。
        FlCamera.cancelPendingPermission()
        FlCamera.sendEvent(mapOf("disposed" to true))
        FlCamera.disposeCamera()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        FlCamera.disposeAll()
        plugin = null
    }
}
