package fl.mlkit.scanning

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import fl.camera.FlCamera
import fl.channel.FlChannelPlugin
import fl.channel.FlDataStreamHandlerCancel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 条码扫描插件。
 *
 * 相机帧来自 fl_camera 的 FlDataStream；图片扫描在后台线程解码，
 * 识别结果通过 MethodChannel 或事件通道返回。
 */
class FlMlKitScanningPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private companion object {
        /** 扫码结果事件通道，与相机通道区分。 */
        const val EVENT_CHANNEL_NAME = "fl.camera.scanning.event"
    }

    private var channel: MethodChannel? = null
    private var options = BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS).build()
    private var scanner: BarcodeScanner? = null
    private var lastCurrentTime = 0L
    private var frequency = 500L
    private var canScanning = true
    private var imageProxyHandler: FlDataStreamHandlerCancel? = null
    private val decoder = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(pluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(pluginBinding.binaryMessenger, "fl.mlkit.scanning")
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        releaseResources()
        decoder.shutdown()
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setParams" -> {
                frequency = (call.argument<Number>("frequency"))?.toLong() ?: 500L
                canScanning = call.argument<Boolean>("canScanning") ?: true
                ensureImageListener()
                result.success(true)
            }

            "setBarcodeFormat" -> {
                setBarcodeFormat(call)
                scanner?.close()
                scanner = null
                result.success(true)
            }

            "scanningImageByte" -> scanningImageByte(call, result)

            "dispose" -> {
                releaseResources()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    /** 仅注册一次相机帧监听，参数变化时无需反复注册。 */
    private fun ensureImageListener() {
        if (imageProxyHandler != null) return
        imageProxyHandler = FlCamera.listenImageProxy { imageProxy ->
            val mediaImage = imageProxy.image
            val currentTime = System.currentTimeMillis()
            if (mediaImage != null && canScanning && currentTime - lastCurrentTime >= frequency) {
                lastCurrentTime = currentTime
                val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                analysis(inputImage, null, imageProxy)
            } else {
                imageProxy.close()
            }
        }
    }

    private fun releaseResources() {
        imageProxyHandler?.invoke()
        imageProxyHandler = null
        scanner?.close()
        scanner = null
        lastCurrentTime = 0
    }

    private fun scanningImageByte(call: MethodCall, result: MethodChannel.Result) {
        val byteArray = call.argument<ByteArray>("byte")
        if (byteArray == null) {
            result.success(null)
            return
        }
        val rotationDegrees = (call.argument<Number>("rotationDegrees"))?.toInt() ?: 0
        decoder.execute {
            val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
            if (bitmap == null) {
                mainHandler.post { result.success(null) }
                return@execute
            }
            val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
            analysis(inputImage, result)
        }
    }

    private fun setBarcodeFormat(call: MethodCall) {
        val barcodeFormats = call.arguments as? List<*> ?: emptyList<Any?>()
        val formats = barcodeFormats.mapNotNull { type ->
            (type as? String)?.let { getBarcodeFormat(it) }
        }.distinct()
        options = if (formats.isEmpty()) {
            BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS).build()
        } else {
            BarcodeScannerOptions.Builder()
                .setBarcodeFormats(formats.first(), *formats.drop(1).toIntArray())
                .build()
        }
    }

    private fun getBarcodeFormat(type: String): Int = when (type) {
        "unknown" -> Barcode.FORMAT_UNKNOWN
        "all" -> Barcode.FORMAT_ALL_FORMATS
        "code128" -> Barcode.FORMAT_CODE_128
        "code39" -> Barcode.FORMAT_CODE_39
        "code93" -> Barcode.FORMAT_CODE_93
        "codaBar" -> Barcode.FORMAT_CODABAR
        "dataMatrix" -> Barcode.FORMAT_DATA_MATRIX
        "ean13" -> Barcode.FORMAT_EAN_13
        "ean8" -> Barcode.FORMAT_EAN_8
        "itf" -> Barcode.FORMAT_ITF
        "qrCode" -> Barcode.FORMAT_QR_CODE
        "upcA" -> Barcode.FORMAT_UPC_A
        "upcE" -> Barcode.FORMAT_UPC_E
        "pdf417" -> Barcode.FORMAT_PDF417
        "aztec" -> Barcode.FORMAT_AZTEC
        else -> Barcode.FORMAT_UNKNOWN
    }

    private fun analysis(
        inputImage: InputImage,
        result: MethodChannel.Result? = null,
        imageProxy: ImageProxy? = null
    ) {
        val list: ArrayList<Map<String, Any?>> = ArrayList()
        getBarcodeScanner().process(inputImage).addOnSuccessListener { barcodes ->
            for (barcode in barcodes) {
                list.add(barcode.data)
            }
            // ML Kit 的坐标基于旋转后的图片，InputImage 的宽高是未旋转的原始尺寸。
            val rotation = ((inputImage.rotationDegrees % 360) + 360) % 360
            val swap = rotation == 90 || rotation == 270
            val width = if (swap) inputImage.height else inputImage.width
            val height = if (swap) inputImage.width else inputImage.height
            val map = mapOf("width" to width.toDouble(), "height" to height.toDouble(), "barcodes" to list)
            if (result == null) {
                if (list.isNotEmpty()) {
                    sendEvent(map)
                }
            } else {
                result.success(map)
            }
        }.addOnFailureListener {
            result?.success(null)
        }.addOnCompleteListener {
            imageProxy?.close()
        }
    }

    /** 扫码结果使用独立的事件通道，避免与相机 / OCR 控制器共用同一通道。 */
    private fun sendEvent(data: Any?) {
        FlChannelPlugin.getEventChannel(EVENT_CHANNEL_NAME)?.send(data)
    }

    private fun getBarcodeScanner(): BarcodeScanner {
        val current = scanner
        if (current != null) return current
        return BarcodeScanning.getClient(options).also { scanner = it }
    }

    private val Barcode.data: Map<String, Any?>
        get() = mapOf(
            "value" to rawValue,
            "type" to valueType,
            "corners" to cornerPoints?.map { corner -> corner.data },
            "boundingBox" to boundingBox?.data,
            "displayValue" to displayValue,
            "format" to format,
            "calendarEvent" to calendarEvent?.data,
            "contactInfo" to contactInfo?.data,
            "driverLicense" to driverLicense?.data,
            "email" to email?.data,
            "geoPoint" to geoPoint?.data,
            "phone" to phone?.data,
            "sms" to sms?.data,
            "url" to url?.data,
            "wifi" to wifi?.data,
            "bytes" to rawBytes
        )

    private val Rect.data: Map<String, Int>
        get() = mapOf(
            "top" to top,
            "bottom" to bottom,
            "left" to left,
            "right" to right,
            "width" to width(),
            "height" to height()
        )

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())

    private val Barcode.CalendarEvent.data: Map<String, Any?>
        get() = mapOf(
            "description" to description,
            "end" to end?.rawValue,
            "location" to location,
            "organizer" to organizer,
            "start" to start?.rawValue,
            "status" to status,
            "summary" to summary
        )

    private val Barcode.ContactInfo.data: Map<String, Any?>
        get() = mapOf(
            "addresses" to addresses.map { address -> address.data },
            "emails" to emails.map { email -> email.data },
            "name" to name?.data,
            "organization" to organization,
            "phones" to phones.map { phone -> phone.data },
            "title" to title,
            "urls" to urls
        )

    private val Barcode.Address.data: Map<String, Any?>
        get() = mapOf("addressLines" to addressLines, "type" to type)

    private val Barcode.PersonName.data: Map<String, Any?>
        get() = mapOf(
            "first" to first,
            "formattedName" to formattedName,
            "last" to last,
            "middle" to middle,
            "prefix" to prefix,
            "pronunciation" to pronunciation,
            "suffix" to suffix
        )

    private val Barcode.DriverLicense.data: Map<String, Any?>
        get() = mapOf(
            "addressCity" to addressCity,
            "addressState" to addressState,
            "addressStreet" to addressStreet,
            "addressZip" to addressZip,
            "birthDate" to birthDate,
            "documentType" to documentType,
            "expiryDate" to expiryDate,
            "firstName" to firstName,
            "gender" to gender,
            "issueDate" to issueDate,
            "issuingCountry" to issuingCountry,
            "lastName" to lastName,
            "licenseNumber" to licenseNumber,
            "middleName" to middleName
        )

    private val Barcode.Email.data: Map<String, Any?>
        get() = mapOf("address" to address, "body" to body, "subject" to subject, "type" to type)

    private val Barcode.GeoPoint.data: Map<String, Any?>
        get() = mapOf("latitude" to lat, "longitude" to lng)

    private val Barcode.Phone.data: Map<String, Any?>
        get() = mapOf("number" to number, "type" to type)

    private val Barcode.Sms.data: Map<String, Any?>
        get() = mapOf("message" to message, "phoneNumber" to phoneNumber)

    private val Barcode.UrlBookmark.data: Map<String, Any?>
        get() = mapOf("title" to title, "url" to url)

    private val Barcode.WiFi.data: Map<String, Any?>
        get() = mapOf("encryptionType" to encryptionType, "password" to password, "ssid" to ssid)
}
