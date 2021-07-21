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

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startPreview" -> startPreview(imageAnalyzer, call, result)
            "setBarcodeFormats" -> {
                setBarcodeFormats(call)
                result.success(true)
            }
            "scanImageByte" -> scanImageByte(call, result)
            else -> {
                super.onMethodCall(call, result)
            }
        }
    }

    private fun scanImageByte(call: MethodCall, result: MethodChannel.Result) {
        val byteArray = call.argument<ByteArray>("byte")!!
        var rotationDegrees = call.argument<Int>("rotationDegrees")
        val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
        if (bitmap == null) {
            result.success(null)
            return
        }
        if (rotationDegrees == null) rotationDegrees = 0
        val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
        analysis(inputImage, result, null)

    }

    @SuppressLint("UnsafeOptInUsageError")
    private val imageAnalyzer = ImageAnalysis.Analyzer { imageProxy ->
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            analysis(inputImage, null, imageProxy)
        } else {
            imageProxy.close()
        }
    }

    private fun setBarcodeFormats(call: MethodCall) {
        val barcodeFormats = call.argument<List<String>?>("barcodeFormats")
        val builder = BarcodeScannerOptions.Builder()
        if (!barcodeFormats.isNullOrEmpty()) {
            barcodeFormats.forEach { type ->
                when (type) {
                    "upcA" -> builder.setBarcodeFormats(Barcode.FORMAT_UPC_A)
                    "upcE" -> builder.setBarcodeFormats(Barcode.FORMAT_UPC_E)
                    "ean13" -> builder.setBarcodeFormats(Barcode.FORMAT_EAN_13)
                    "ean8" -> builder.setBarcodeFormats(Barcode.FORMAT_EAN_8)
                    "codaBar" -> builder.setBarcodeFormats(Barcode.FORMAT_CODABAR)
                    "code39" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_39)
                    "code93" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_93)
                    "code128" -> builder.setBarcodeFormats(Barcode.FORMAT_CODE_128)
                    "itf" -> builder.setBarcodeFormats(Barcode.FORMAT_ITF)
                    "qrCode" -> builder.setBarcodeFormats(Barcode.FORMAT_QR_CODE)
                    "aztec" -> builder.setBarcodeFormats(Barcode.FORMAT_AZTEC)
                    "dataMatrix" -> builder.setBarcodeFormats(Barcode.FORMAT_DATA_MATRIX)
                    "pdf417" -> builder.setBarcodeFormats(Barcode.FORMAT_PDF417)
                }
            }
        } else {
            builder.setBarcodeFormats((Barcode.FORMAT_QR_CODE))
        }
        options = builder.build()
    }

    private fun analysis(inputImage: InputImage, result: MethodChannel.Result?, imageProxy: ImageProxy?) {
        val barcodeList: ArrayList<MutableMap<String, Any?>> = ArrayList()
        val scanner: BarcodeScanner = BarcodeScanning.getClient(options)
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                for (barcode in barcodes) {
                    val map: MutableMap<String, Any?> = HashMap()
                    map["value"] = barcode.rawValue
                    map["type"] = barcode.valueType
                    map["cornerPoints"] = getCornerPoints(barcode.cornerPoints)
                    map["boundingBox"] = getBoundingBox(barcode.boundingBox)
                    map["displayValue"] = barcode.displayValue
                    map["format"] = barcode.format
                    when (barcode.valueType) {
                        Barcode.TYPE_UNKNOWN -> {

                        }
                        Barcode.TYPE_CONTACT_INFO -> {
                            val contactInfo: MutableMap<String, Any?> = HashMap()
                            contactInfo["title"] = barcode.contactInfo!!.title

                            val emails: ArrayList<MutableMap<String, Any?>> = ArrayList()
                            barcode.contactInfo!!.emails.forEach { email -> emails.add(getEmail(email)) }
                            contactInfo["emails"] = emails

                            val phones: ArrayList<MutableMap<String, Any?>> = ArrayList()
                            barcode.contactInfo!!.phones.forEach { phone -> phones.add(getPhone(phone)) }
                            contactInfo["phones"] = phones

                            val addresses: ArrayList<MutableMap<String, Any?>> = ArrayList()
                            barcode.contactInfo!!.addresses.forEach { address -> addresses.add(getAddress(address)) }
                            contactInfo["addresses"] = addresses

                            contactInfo["name"] = getContactInfoName(barcode.contactInfo!!.name)
                            contactInfo["organization"] = barcode.contactInfo!!.organization

                            map["contactInfo"] = contactInfo
                        }
                        Barcode.TYPE_EMAIL -> {
                            map["email"] = getEmail(barcode.email)
                        }
                        Barcode.TYPE_ISBN -> {
                        }
                        Barcode.TYPE_PHONE -> {
                            map["phone"] = getPhone(barcode.phone)
                        }
                        Barcode.TYPE_PRODUCT -> {

                        }
                        Barcode.TYPE_SMS -> {
                            map["sms"] = getSMS(barcode.sms)
                        }
                        Barcode.TYPE_TEXT -> {

                        }
                        Barcode.TYPE_URL -> {
                            val url: MutableMap<String, Any?> = HashMap()
                            url["title"] = barcode.url!!.title
                            url["url"] = barcode.url!!.url
                            map["url"] = url
                        }
                        Barcode.TYPE_WIFI -> {
                            val wifi: MutableMap<String, Any?> = HashMap()
                            wifi["ssid"] = barcode.wifi!!.ssid
                            wifi["password"] = barcode.wifi!!.password
                            wifi["type"] = barcode.wifi!!.encryptionType
                            map["wifi"] = wifi
                        }
                        Barcode.TYPE_GEO -> {
                            map["geoPoint"] = getGeoPoint(barcode.geoPoint)
                        }
                        Barcode.TYPE_CALENDAR_EVENT -> {
                            map["calendarEvent"] = getCalendarEvent(barcode.calendarEvent)
                        }
                        Barcode.TYPE_DRIVER_LICENSE -> {
                            map["driverLicense"] = getDriverLicense(barcode.driverLicense)
                        }
                    }
                    barcodeList.add(map)
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


    private fun getBoundingBox(boundingBox: Rect?): MutableMap<String, Any?> {
        val map: MutableMap<String, Any?> = HashMap()
        map["top"] = boundingBox?.top
        map["bottom"] = boundingBox?.bottom
        map["left"] = boundingBox?.left
        map["right"] = boundingBox?.right
        return map
    }

    private fun getCornerPoints(cornerPoints: Array<Point>?): ArrayList<MutableMap<String, Any?>> {
        val points: ArrayList<MutableMap<String, Any?>> = ArrayList()
        cornerPoints?.forEach { point ->
            val map: MutableMap<String, Any?> = HashMap()
            map["x"] = point.x
            map["y"] = point.y
            points.add(map)
        }
        return points
    }

    private fun getAddress(barcodeAddress: Barcode.Address?): MutableMap<String, Any?> {
        val address: MutableMap<String, Any?> = HashMap()
        address["addressLines"] = barcodeAddress?.addressLines
        address["type"] = barcodeAddress?.type
        return address
    }

    private fun getContactInfoName(barcodeName: Barcode.PersonName?): MutableMap<String, Any?> {
        val name: MutableMap<String, Any?> = HashMap()
        name["first"] = barcodeName?.first
        name["formattedName"] = barcodeName?.formattedName
        name["prefix"] = barcodeName?.prefix
        name["suffix"] = barcodeName?.suffix
        name["last"] = barcodeName?.last
        name["middle"] = barcodeName?.middle
        name["pronunciation"] = barcodeName?.pronunciation
        return name
    }

    private fun getDriverLicense(barcodeDriverLicense: Barcode.DriverLicense?): MutableMap<String, Any?> {
        val driverLicense: MutableMap<String, Any?> = HashMap()
        driverLicense["addressCity"] = barcodeDriverLicense?.addressCity
        driverLicense["addressState"] = barcodeDriverLicense?.addressState
        driverLicense["addressStreet"] = barcodeDriverLicense?.addressStreet
        driverLicense["addressZip"] = barcodeDriverLicense?.addressZip
        driverLicense["birthDate"] = barcodeDriverLicense?.birthDate
        driverLicense["documentType"] = barcodeDriverLicense?.documentType
        driverLicense["expiryDate"] = barcodeDriverLicense?.expiryDate
        driverLicense["firstName"] = barcodeDriverLicense?.firstName
        driverLicense["gender"] = barcodeDriverLicense?.gender
        driverLicense["issueDate"] = barcodeDriverLicense?.issueDate
        driverLicense["issuingCountry"] = barcodeDriverLicense?.issuingCountry
        return driverLicense
    }

    private fun getCalendarEvent(barcodeCalendarEvent: Barcode.CalendarEvent?): MutableMap<String, Any?> {
        val calendarEvent: MutableMap<String, Any?> = HashMap()
        calendarEvent["description"] = barcodeCalendarEvent?.description
        calendarEvent["location"] = barcodeCalendarEvent?.location
        calendarEvent["status"] = barcodeCalendarEvent?.status
        calendarEvent["summary"] = barcodeCalendarEvent?.summary
        calendarEvent["end"] = barcodeCalendarEvent?.end?.rawValue
        calendarEvent["start"] = barcodeCalendarEvent?.start?.rawValue
        calendarEvent["organizer"] = barcodeCalendarEvent?.organizer
        return calendarEvent
    }

    private fun getGeoPoint(barcodeGeoPoint: Barcode.GeoPoint?): MutableMap<String, Any?> {
        val geoPoint: MutableMap<String, Any?> = HashMap()
        geoPoint["lat"] = barcodeGeoPoint?.lat
        geoPoint["lng"] = barcodeGeoPoint?.lng
        return geoPoint
    }

    private fun getSMS(barcodeSMS: Barcode.Sms?): MutableMap<String, Any?> {
        val sms: MutableMap<String, Any?> = HashMap()
        sms["message"] = barcodeSMS?.message
        sms["phoneNumber"] = barcodeSMS?.phoneNumber
        return sms
    }

    private fun getPhone(barcodePhone: Barcode.Phone?): MutableMap<String, Any?> {
        val phone: MutableMap<String, Any?> = HashMap()
        phone["number"] = barcodePhone?.number
        phone["type"] = barcodePhone?.type
        return phone
    }


    private fun getEmail(barcodeEmail: Barcode.Email?): MutableMap<String, Any?> {
        val email: MutableMap<String, Any?> = HashMap()
        email["address"] = barcodeEmail?.address
        email["body"] = barcodeEmail?.body
        email["type"] = barcodeEmail?.type
        email["subject"] = barcodeEmail?.subject
        return email
    }
}
