package app.aivoice.mobile

import android.media.AudioAttributes
import android.media.MediaPlayer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 段落回放。
 *
 * Dart 端已經把要播的幀切成一個小的 ADTS 檔（幾秒鐘約 20 KB），
 * 這裡只負責播它，不做 seek —— ADTS 沒有索引，seek 是用位元率估的，對不準。
 *
 * 檔案小又在本機，所以同步 prepare 就好，不必開執行緒。
 * 一次只有一個播放器；換段一定先 release 舊的。
 */
class PlaybackBridge(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val CHANNEL = "app.aivoice.mobile/playback"
        private const val EVENTS = "app.aivoice.mobile/playback_events"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENTS)
    private var events: EventChannel.EventSink? = null
    private var player: MediaPlayer? = null

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        release()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        events = null
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("args", "path is required", null)
                    return
                }
                try {
                    result.success(mapOf("durationMs" to play(File(path))))
                } catch (e: Exception) {
                    release()
                    result.error("failed", e.message ?: e.toString(), null)
                }
            }
            "stop" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun play(file: File): Int {
        if (!file.isFile) throw IllegalStateException("no such file: ${file.name}")
        release()

        val instance = MediaPlayer()
        instance.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        instance.setDataSource(file.absolutePath)
        instance.prepare()
        instance.setOnCompletionListener {
            release()
            emit(mapOf("type" to "completed"))
        }
        instance.setOnErrorListener { _, what, extra ->
            release()
            emit(mapOf("type" to "error", "message" to "player error $what/$extra"))
            true
        }
        instance.start()
        player = instance
        return instance.duration
    }

    private fun release() {
        val instance = player ?: return
        player = null
        try {
            instance.setOnCompletionListener(null)
            instance.setOnErrorListener(null)
            instance.stop()
        } catch (_: IllegalStateException) {
            // 還沒開始播就被停掉，直接往下釋放。
        }
        instance.release()
    }

    /** 事件一律在主執行緒送出：MediaPlayer 的回呼本來就在建立它的執行緒上。 */
    private fun emit(payload: Map<String, Any>) {
        events?.success(payload)
    }
}
