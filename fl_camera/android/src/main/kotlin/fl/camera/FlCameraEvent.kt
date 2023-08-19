package fl.camera

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class FlCameraEvent(binaryMessenger: BinaryMessenger) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var eventChannel: EventChannel? = null
    private var lastArgs: Any? = null

    init {
        eventChannel = EventChannel(binaryMessenger, "fl.camera.event")
        eventChannel!!.setStreamHandler(this)
    }

    fun sendEvent(arguments: Any?) {
        if (lastArgs == arguments) return
        lastArgs = arguments
        eventSink?.success(arguments)
    }

    fun dispose() {
        eventSink?.endOfStream()
        eventSink = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onListen(arguments: Any?, event: EventChannel.EventSink?) {
        eventSink = event
    }

    override fun onCancel(arguments: Any?) {
        dispose()
    }
}