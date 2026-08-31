package app.aivoice.mobile

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * 轉寫相關的平台能力。
 *
 * 這裡只做 Dart 端做不到的事：把 AAC 解成 PCM、算大檔的 SHA-256、看網路型態。
 * 辨識本身由 sherpa_onnx 的 Flutter 外掛在 Dart 端執行。
 *
 * 解碼與雜湊都很慢，一律丟到背景執行緒，結果再回主執行緒，避免 ANR。
 */
class AsrBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "app.aivoice.mobile/asr"
        private const val TARGET_SAMPLE_RATE = 16000
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "modelsDir" -> result.success(modelsDir().absolutePath)
            "networkType" -> result.success(networkType())
            "sha256" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("args", "path is required", null)
                } else {
                    runInBackground(result) { mapOf("sha256" to sha256(File(path))) }
                }
            }
            "decodeToPcm" -> {
                val input = call.argument<String>("input")
                val output = call.argument<String>("output")
                if (input == null || output == null) {
                    result.error("args", "input and output are required", null)
                } else {
                    runInBackground(result) { decodeToPcm(File(input), File(output)) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun runInBackground(
        result: MethodChannel.Result,
        block: () -> Any?,
    ) {
        worker.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.message ?: e.toString(), null) }
            }
        }
    }

    private fun modelsDir(): File = File(context.filesDir, "models").apply { mkdirs() }

    // ----------------------------------------------------------------- network

    private fun networkType(): String {
        val manager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return "unknown"
        val network = manager.activeNetwork ?: return "none"
        val capabilities = manager.getNetworkCapabilities(network) ?: return "none"
        if (!capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) return "none"
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            else -> "other"
        }
    }

    // ------------------------------------------------------------------ sha256

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).use { input ->
            val buffer = ByteArray(1 shl 16)
            while (true) {
                val read = input.read(buffer)
                if (read <= 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    // ------------------------------------------------------------------ decode

    /**
     * 把 AAC（ADTS 裸流）解成 16-bit 小端序單聲道 PCM。
     * 回傳實際的取樣率與位元組數，讓 Dart 端可以驗證，而不是盲目相信。
     */
    private fun decodeToPcm(input: File, output: File): Map<String, Any> {
        val extractor = MediaExtractor()
        extractor.setDataSource(input.absolutePath)

        var trackIndex = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val candidate = extractor.getTrackFormat(i)
            val mime = candidate.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                trackIndex = i
                format = candidate
                break
            }
        }
        if (trackIndex < 0 || format == null) {
            extractor.release()
            throw IllegalStateException("no audio track in ${input.name}")
        }
        extractor.selectTrack(trackIndex)

        val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        codec.configure(format, null, null, 0)
        codec.start()

        var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        var written = 0L

        val stream = FileOutputStream(output)
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false

        try {
            while (!outputDone) {
                if (!inputDone) {
                    val index = codec.dequeueInputBuffer(10_000)
                    if (index >= 0) {
                        val buffer = codec.getInputBuffer(index)
                        val size = if (buffer == null) -1 else extractor.readSampleData(buffer, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(
                                index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                when (val index = codec.dequeueOutputBuffer(info, 10_000)) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val actual = codec.outputFormat
                        sampleRate = actual.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = actual.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    }
                    MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                    MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> Unit
                    else -> {
                        if (index >= 0) {
                            if (info.size > 0) {
                                val buffer = codec.getOutputBuffer(index)
                                if (buffer != null) {
                                    val bytes = ByteArray(info.size)
                                    buffer.position(info.offset)
                                    buffer.limit(info.offset + info.size)
                                    buffer.get(bytes)
                                    val mono = toMono(bytes, channels)
                                    stream.write(mono)
                                    written += mono.size
                                }
                            }
                            codec.releaseOutputBuffer(index, false)
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                outputDone = true
                            }
                        }
                    }
                }
            }
        } finally {
            stream.flush()
            stream.fd.sync()
            stream.close()
            try {
                codec.stop()
                codec.release()
            } catch (_: Exception) {
            }
            extractor.release()
        }

        return mapOf(
            "path" to output.absolutePath,
            "sampleRate" to sampleRate,
            "channels" to 1,
            "bytes" to written,
            "expectedSampleRate" to TARGET_SAMPLE_RATE,
        )
    }

    /** 解碼器理論上輸出單聲道，但真的拿到立體聲就取平均，不要靜默寫出錯的資料。 */
    private fun toMono(pcm: ByteArray, channels: Int): ByteArray {
        if (channels <= 1) return pcm
        val source = ByteBuffer.wrap(pcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val frames = source.remaining() / channels
        val target = ByteBuffer.allocate(frames * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until frames) {
            var sum = 0
            for (c in 0 until channels) sum += source.get(i * channels + c).toInt()
            target.putShort((sum / channels).toShort())
        }
        return target.array()
    }
}
