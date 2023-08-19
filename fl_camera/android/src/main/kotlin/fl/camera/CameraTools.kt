package fl.camera

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.media.CamcorderProfile
import android.util.Size
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.CameraSelector

object CameraTools {
    fun getAvailableCameras(activity: Activity): List<Map<String, Any>> {
        val cameraManager = activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraNames = cameraManager.cameraIdList
        val cameras: MutableList<Map<String, Any>> = ArrayList()
        for (cameraName in cameraNames) {
            val details = HashMap<String, Any>()
            val characteristics = cameraManager.getCameraCharacteristics(cameraName)
            details["name"] = cameraName
            when (characteristics.get(CameraCharacteristics.LENS_FACING)!!) {
                CameraMetadata.LENS_FACING_FRONT -> details["lensFacing"] = "front"
                CameraMetadata.LENS_FACING_BACK -> details["lensFacing"] = "back"
                CameraMetadata.LENS_FACING_EXTERNAL -> details["lensFacing"] = "external"
            }
            cameras.add(details)
        }
        return cameras
    }

    private fun getBestAvailableCamcorderProfileForResolutionPreset(
        cameraId: Int, preset: String
    ): CamcorderProfile {
        return when (preset) {
            "max" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_HIGH)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_HIGH)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_2160P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_2160P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_1080P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_1080P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_720P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            "ultraHigh" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_2160P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_2160P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_1080P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_1080P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_720P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            "veryHigh" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_1080P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_1080P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_720P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            "high" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_720P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            "medium" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            "low" -> {
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
                    return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA)
                }
                if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                    CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
                } else {
                    throw IllegalArgumentException(
                        "No capture session available for current capture session."
                    )
                }
            }
            else -> if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
                CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW)
            } else {
                throw IllegalArgumentException(
                    "No capture session available for current capture session."
                )
            }
        }
    }

    fun computeBestPreviewSize(cameraId: String, preset: String): Size {
        val profile = getBestAvailableCamcorderProfileForResolutionPreset(cameraId.toInt(), preset)
        return Size(profile.videoFrameHeight, profile.videoFrameWidth)
    }

    @SuppressLint("UnsafeOptInUsageError")
    fun getCameraSelector(cameraId: String): CameraSelector {
        return CameraSelector.Builder()
            .addCameraFilter { cameras ->
                val result = cameras.filter {
                    cameraId == Camera2CameraInfo.from(it).cameraId
                }
                result
            }
            .build()
    }
}
