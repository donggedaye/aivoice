package app.aivoice.mobile

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 錄音的平台通道。
 *
 * 權限一律在每次開始錄音前重新檢查，不快取結果 —— Android 11 起的「僅本次允許」
 * 會在 App 進入背景後被撤回，快取會讓下一次錄音靜默失敗。
 */
class RecordingChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, RecordingService.Listener {

    companion object {
        private const val METHOD_CHANNEL = "app.aivoice.mobile/recording"
        private const val EVENT_CHANNEL = "app.aivoice.mobile/recording_events"
        private const val REQUEST_CODE = 4101

        private const val GRANTED = "granted"
        private const val DENIED = "denied"
        private const val PERMANENTLY_DENIED = "permanentlyDenied"
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val main = Handler(Looper.getMainLooper())

    private var events: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** 送出請求前的 rationale 狀態，用來區分「拒絕」與「不再詢問」。 */
    private var rationaleBeforeRequest = mutableMapOf<String, Boolean>()

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        RecordingService.listener = this
    }

    fun dispose() {
        RecordingService.listener = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ------------------------------------------------------------- method call

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "permissionStatus" -> result.success(currentStatus())
            "requestPermissions" -> requestPermissions(result)
            "openAppSettings" -> {
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", activity.packageName, null),
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity.startActivity(intent)
                result.success(null)
            }
            "recordingsDir" -> result.success(recordingsDir().absolutePath)
            "start" -> start(result)
            "stop" -> {
                activity.startService(
                    Intent(activity, RecordingService::class.java).apply {
                        action = RecordingService.ACTION_STOP
                    },
                )
                result.success(null)
            }
            "state" -> result.success(
                mapOf(
                    "isRecording" to RecordingService.isRecording,
                    "elapsedMs" to RecordingService.elapsedMs,
                ),
            )
            else -> result.notImplemented()
        }
    }

    private fun recordingsDir(): File = File(activity.filesDir, "recordings")

    private fun start(result: MethodChannel.Result) {
        if (!isGranted(Manifest.permission.RECORD_AUDIO)) {
            result.error("permission", "RECORD_AUDIO is not granted", null)
            return
        }
        if (RecordingService.isRecording) {
            result.error("busy", "A recording is already running", null)
            return
        }

        val id = System.currentTimeMillis().toString()
        val dir = File(recordingsDir(), id)
        dir.mkdirs()

        val intent = Intent(activity, RecordingService::class.java).apply {
            action = RecordingService.ACTION_START
            putExtra(RecordingService.EXTRA_OUTPUT_DIR, dir.absolutePath)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }

        result.success(mapOf("id" to id, "dir" to dir.absolutePath))
    }

    // -------------------------------------------------------------- permission

    private fun requiredPermissions(): List<String> {
        val permissions = mutableListOf(Manifest.permission.RECORD_AUDIO)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        return permissions
    }

    private fun isGranted(permission: String): Boolean =
        activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun currentStatus(): Map<String, String> {
        val status = mutableMapOf<String, String>()
        status["microphone"] = statusOf(Manifest.permission.RECORD_AUDIO)
        status["notifications"] =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                statusOf(Manifest.permission.POST_NOTIFICATIONS)
            } else {
                GRANTED
            }
        return status
    }

    private fun statusOf(permission: String): String {
        if (isGranted(permission)) return GRANTED
        // 送出過請求、現在也不該顯示說明 → 使用者選了「不再詢問」。
        val asked = rationaleBeforeRequest.containsKey(permission)
        val rationale = activity.shouldShowRequestPermissionRationale(permission)
        return if (asked && !rationale) PERMANENTLY_DENIED else DENIED
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val missing = requiredPermissions().filterNot { isGranted(it) }
        if (missing.isEmpty()) {
            result.success(currentStatus())
            return
        }
        if (pendingPermissionResult != null) {
            result.error("busy", "A permission request is already in flight", null)
            return
        }
        pendingPermissionResult = result
        missing.forEach {
            rationaleBeforeRequest[it] = activity.shouldShowRequestPermissionRationale(it)
        }
        activity.requestPermissions(missing.toTypedArray(), REQUEST_CODE)
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        result.success(currentStatus())
        return true
    }

    // ------------------------------------------------------------------ events

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onAmplitude(rms: Double, elapsedMs: Long) {
        emit(mapOf("type" to "amplitude", "rms" to rms, "elapsedMs" to elapsedMs))
    }

    override fun onChunk(path: String, index: Int) {
        emit(mapOf("type" to "chunk", "path" to path, "index" to index))
    }

    override fun onError(message: String) {
        emit(mapOf("type" to "error", "message" to message))
    }

    private fun emit(payload: Map<String, Any?>) {
        main.post { events?.success(payload) }
    }
}
