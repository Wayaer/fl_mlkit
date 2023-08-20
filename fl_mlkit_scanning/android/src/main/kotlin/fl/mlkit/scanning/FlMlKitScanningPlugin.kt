package fl.mlkit.scanning

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.Rect
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import fl.camera.FlCamera
import fl.channel.FlDataStreamHandlerCancel
import fl.channel.FlEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlMlKitScanningPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var options = BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS).build()
    private var scanner: BarcodeScanner? = null
    private var lastCurrentTime = 0L

    private var imageProxyHandler: FlDataStreamHandlerCancel? = null

    override fun onAttachedToEngine(pluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(pluginBinding.binaryMessenger, "fl.mlkit.scanning")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setParams" -> {
                val frequency = call.argument<Int>("frequency")!!.toLong()
                val canScanning = call.argument<Boolean>("canScanning")!!
                imageProxyHandler?.invoke()
                imageProxyHandler = null
                imageProxyHandler = FlCamera.flDataStream.listen { imageProxy ->
                    val mediaImage = imageProxy.image
                    val currentTime = System.currentTimeMillis()
                    if (currentTime - lastCurrentTime >= frequency && mediaImage != null && canScanning) {
                        val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                        analysis(inputImage, null, imageProxy)
                        lastCurrentTime = currentTime
                    } else {
                        imageProxy.close()
                    }
                }
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
                imageProxyHandler?.invoke()
                imageProxyHandler = null
                scanner?.close()
                scanner = null
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun scanningImageByte(call: MethodCall, result: MethodChannel.Result) {
        val useEvent = call.argument<Boolean>("useEvent")!!
        val byteArray = call.argument<ByteArray>("byte")!!
        var rotationDegrees = call.argument<Int>("rotationDegrees")
        val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
        if (bitmap == null) {
            result.success(null)
            return
        }
        if (rotationDegrees == null) rotationDegrees = 0
        val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
        analysis(inputImage, if (useEvent) null else result, null)
    }

    private fun setBarcodeFormat(call: MethodCall) {
        val barcodeFormats = call.arguments as List<*>
        val builder = BarcodeScannerOptions.Builder()
        if (barcodeFormats.isNotEmpty()) {
            val formats = barcodeFormats.map { type -> getBarcodeFormat(type as String) }
            builder.setBarcodeFormats(formats.first(), *formats.toIntArray())
        } else {
            builder.setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS, Barcode.FORMAT_CODE_39)
        }
        options = builder.build()
    }

    private fun getBarcodeFormat(type: String): Int {
        when (type) {
            "unknown" -> return Barcode.FORMAT_UNKNOWN
            "all" -> return Barcode.FORMAT_ALL_FORMATS
            "code128" -> return Barcode.FORMAT_CODE_128
            "code39" -> return Barcode.FORMAT_CODE_39
            "code93" -> return Barcode.FORMAT_CODE_93
            "codaBar" -> return Barcode.FORMAT_CODABAR
            "dataMatrix" -> return Barcode.FORMAT_DATA_MATRIX
            "ean13" -> return Barcode.FORMAT_EAN_13
            "ean8" -> return Barcode.FORMAT_EAN_8
            "itf" -> return Barcode.FORMAT_ITF
            "qrCode" -> return Barcode.FORMAT_QR_CODE
            "upcA" -> return Barcode.FORMAT_UPC_A
            "upcE" -> return Barcode.FORMAT_UPC_E
            "pdf417" -> return Barcode.FORMAT_PDF417
            "aztec" -> return Barcode.FORMAT_AZTEC
        }
        return Barcode.FORMAT_UNKNOWN
    }


    private fun analysis(inputImage: InputImage, result: MethodChannel.Result?, imageProxy: ImageProxy?) {
        val list: ArrayList<Map<String, Any?>> = ArrayList()
        getBarcodeScanner().process(inputImage).addOnSuccessListener { barcodes ->
            for (barcode in barcodes) {
                list.add(barcode.data)
            }
            var width = inputImage.width
            var height = inputImage.height
            if (width > height) {
                width -= height
                height += width
                width = height - width
            }

            val map = mapOf("height" to height.toDouble(), "width" to width.toDouble(), "barcodes" to list)
            if (result == null) {
                if (list.isNotEmpty()) {
                    FlEvent.send(map)
                }
            } else {
                result.success(map)
            }
        }.addOnFailureListener { result?.success(null) }.addOnCompleteListener { imageProxy?.close() }
    }

    private fun getBarcodeScanner(): BarcodeScanner {
        if (scanner == null) {
            scanner = BarcodeScanning.getClient(options)
        }
        return scanner!!
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
                "bytes" to rawBytes,
        )
    private val Rect.data: Map<String, Int>
        get() = mapOf("top" to top, "bottom" to bottom, "left" to left, "right" to right, "width" to width(), "height" to height())

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())

    private val Barcode.CalendarEvent.data: Map<String, Any?>
        get() = mapOf("description" to description, "end" to end?.rawValue, "location" to location, "organizer" to organizer, "start" to start?.rawValue, "status" to status, "summary" to summary)

    private val Barcode.ContactInfo.data: Map<String, Any?>
        get() = mapOf("addresses" to addresses.map { address -> address.data }, "emails" to emails.map { email -> email.data }, "name" to name?.data, "organization" to organization, "phones" to phones.map { phone -> phone.data }, "title" to title, "urls" to urls)

    private val Barcode.Address.data: Map<String, Any?>
        get() = mapOf("addressLines" to addressLines, "type" to type)

    private val Barcode.PersonName.data: Map<String, Any?>
        get() = mapOf("first" to first, "formattedName" to formattedName, "last" to last, "middle" to middle, "prefix" to prefix, "pronunciation" to pronunciation, "suffix" to suffix)

    private val Barcode.DriverLicense.data: Map<String, Any?>
        get() = mapOf("addressCity" to addressCity, "addressState" to addressState, "addressStreet" to addressStreet, "addressZip" to addressZip, "birthDate" to birthDate, "documentType" to documentType, "expiryDate" to expiryDate, "firstName" to firstName, "gender" to gender, "issueDate" to issueDate, "issuingCountry" to issuingCountry, "lastName" to lastName, "licenseNumber" to licenseNumber, "middleName" to middleName)

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
