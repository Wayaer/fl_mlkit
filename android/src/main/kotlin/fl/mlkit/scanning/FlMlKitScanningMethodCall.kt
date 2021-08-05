package fl.mlkit.scanning

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.Rect
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.Barcode
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import fl.camera.FlCameraMethodCall
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlMlKitScanningMethodCall(
    activityPlugin: ActivityPluginBinding,
    plugin: FlutterPlugin.FlutterPluginBinding
) :
    FlCameraMethodCall(activityPlugin, plugin) {

    private var options: BarcodeScannerOptions =
        BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
    private var scan = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startPreview" -> startPreview(imageAnalyzer, call, result)
            "setBarcodeFormat" -> {
                setBarcodeFormat(call)
                result.success(true)
            }
            "scanImageByte" -> scanImageByte(call, result)
            "scan" -> {
                val argument = call.arguments as Boolean
                if (argument != scan) {
                    scan = argument
                }
                result.success(true)
            }
            else -> {
                super.onMethodCall(call, result)
            }
        }
    }

    private fun scanImageByte(call: MethodCall, result: MethodChannel.Result) {
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

    @SuppressLint("UnsafeOptInUsageError")
    private val imageAnalyzer = ImageAnalysis.Analyzer { imageProxy ->
        val mediaImage = imageProxy.image
        if (mediaImage != null && scan) {
            val inputImage =
                InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            analysis(inputImage, null, imageProxy)
        } else {
            imageProxy.close()
        }
    }

    private fun setBarcodeFormat(call: MethodCall) {
        val barcodeFormats = call.argument<List<String>?>("barcodeFormats")
        val builder = BarcodeScannerOptions.Builder()
        if (!barcodeFormats.isNullOrEmpty()) {
            barcodeFormats.forEach { type ->
                when (type) {
                    "unknown" -> builder.setBarcodeFormats(Barcode.FORMAT_UNKNOWN)
                    "all" -> builder.setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
                    "code128" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_128)
                    "code39" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_39)
                    "code93" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_93)
                    "code_bar" -> builder.setBarcodeFormats(Barcode.FORMAT_CODABAR)
                    "data_matrix" -> builder.setBarcodeFormats(Barcode.FORMAT_DATA_MATRIX)
                    "ean13" -> builder.setBarcodeFormats(Barcode.FORMAT_EAN_13)
                    "ean8" -> builder.setBarcodeFormats(Barcode.FORMAT_EAN_8)
                    "itf" -> builder.setBarcodeFormats(Barcode.FORMAT_ITF)
                    "qr_code" -> builder.setBarcodeFormats(Barcode.FORMAT_QR_CODE)
                    "upc_a" -> builder.setBarcodeFormats(Barcode.FORMAT_UPC_A)
                    "upc_e" -> builder.setBarcodeFormats(Barcode.FORMAT_UPC_E)
                    "pdf417" -> builder.setBarcodeFormats(Barcode.FORMAT_PDF417)
                    "aztec" -> builder.setBarcodeFormats(Barcode.FORMAT_AZTEC)
                }
            }
        } else {
            builder.setBarcodeFormats((Barcode.FORMAT_QR_CODE))
        }
        options = builder.build()
    }

    private fun analysis(
        inputImage: InputImage,
        result: MethodChannel.Result?,
        imageProxy: ImageProxy?
    ) {
        val barcodeList: ArrayList<Map<String, Any?>> = ArrayList()
        val scanner: BarcodeScanner = BarcodeScanning.getClient(options)
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                for (barcode in barcodes) {
                    barcodeList.add(barcode.data)
                }
                if (result == null) {
                    flCameraEvent?.sendEvent(barcodeList)
                } else {
                    result.success(barcodeList)
                }
            }
            .addOnFailureListener { result?.success(barcodeList) }
            .addOnCompleteListener { imageProxy?.close() }
    }


    private val Barcode.data: Map<String, Any?>
        get() = mapOf(
            "value" to rawValue,
            "type" to valueType,
            "cornerPoints" to cornerPoints?.map { corner -> corner.data },
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
        get() = mapOf("top" to top, "bottom" to bottom, "left" to left, "right" to right)

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())

    private val Barcode.CalendarEvent.data: Map<String, Any?>
        get() = mapOf(
            "description" to description, "end" to end?.rawValue, "location" to location,
            "organizer" to organizer, "start" to start?.rawValue, "status" to status,
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
        get() = mapOf(
            "address" to address,
            "body" to body,
            "subject" to subject,
            "type" to type
        )

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
