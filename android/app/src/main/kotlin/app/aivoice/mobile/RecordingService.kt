package app.aivoice.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import java.io.File
import java.io.FileOutputStream
import kotlin.math.sqrt

/**
 * 前景服務錄音。
 *
 * AudioRecord 全程不停，只輪替輸出檔，所以分片邊界不掉音。
 * 輸出為 AAC-LC ADTS 裸流，分片可用位元組直接串接。
 */
class RecordingService : Service() {

    interface Listener {
        fun onAmplitude(rms: Double, elapsedMs: Long)
        fun onChunk(path: String, index: Int)
        fun onError(message: String)

        /**
         * 錄音迴圈結束。[interrupted] 為 true 代表不是使用者按停止，
         * 而是被系統打斷（權限被撤回、音訊裝置被搶走、例外）。
         */
        fun onStopped(interrupted: Boolean, message: String?)
    }

    companion object {
        const val ACTION_START = "app.aivoice.mobile.action.START"
        const val ACTION_STOP = "app.aivoice.mobile.action.STOP"
        const val EXTRA_OUTPUT_DIR = "outputDir"

        const val SAMPLE_RATE = 16000
        const val BIT_RATE = 32000
        const val CHUNK_SECONDS = 30

        /** 每個 AAC-LC 幀固定 1024 個取樣。 */
        private const val SAMPLES_PER_FRAME = 1024
        private const val CHUNK_SAMPLES = SAMPLE_RATE * CHUNK_SECONDS

        /** 每次從 AudioRecord 讀 100 ms。 */
        private const val READ_BYTES = SAMPLE_RATE / 10 * 2

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "recording"

        @Volatile
        var isRecording = false
            private set

        @Volatile
        var elapsedMs = 0L
            private set

        @Volatile
        var listener: Listener? = null
    }

    private var worker: Thread? = null
    private var wakeLock: PowerManager.WakeLock? = null

    @Volatile
    private var running = false

    /** 只有走 ACTION_STOP 才算使用者主動停止；被系統回收服務不算。 */
    @Volatile
    private var stopRequestedByUser = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val dir = intent.getStringExtra(EXTRA_OUTPUT_DIR)
                if (dir == null) {
                    listener?.onError("outputDir is missing")
                    stopSelf()
                } else {
                    start(File(dir))
                }
            }
            ACTION_STOP -> {
                stopRequestedByUser = true
                stop()
            }
            else -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stop()
        super.onDestroy()
    }

    private fun start(outputDir: File) {
        if (running) return
        outputDir.mkdirs()

        startForegroundNotification()
        acquireWakeLock()

        running = true
        isRecording = true
        elapsedMs = 0L
        stopRequestedByUser = false

        worker = Thread({ recordLoop(outputDir) }, "aivoice-recorder").apply {
            priority = Thread.MAX_PRIORITY
            start()
        }
    }

    private fun stop() {
        if (!running && worker == null) return
        running = false
        worker?.join(10_000)
        worker = null
        isRecording = false
        releaseWakeLock()
        stopForegroundCompat()
        stopSelf()
    }

    // ---------------------------------------------------------------- recording

    private fun recordLoop(outputDir: File) {
        var recorder: AudioRecord? = null
        var codec: MediaCodec? = null
        var writer: ChunkWriter? = null
        var failure: String? = null

        try {
            val minBuffer = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            if (minBuffer <= 0) {
                failure = "AudioRecord.getMinBufferSize failed: $minBuffer"
                listener?.onError(failure)
                return
            }

            recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBuffer, READ_BYTES * 4),
            )
            if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                failure = "AudioRecord is not initialized"
                listener?.onError(failure)
                return
            }

            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC, SAMPLE_RATE, 1,
            ).apply {
                setInteger(
                    MediaFormat.KEY_AAC_PROFILE,
                    MediaCodecInfo.CodecProfileLevel.AACObjectLC,
                )
                setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, READ_BYTES * 4)
            }
            codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            codec.start()

            writer = ChunkWriter(outputDir)
            recorder.startRecording()

            val pcm = ByteArray(READ_BYTES)
            val info = MediaCodec.BufferInfo()
            var recordedSamples = 0L
            var encodedSamples = 0L

            while (running) {
                val read = recorder.read(pcm, 0, pcm.size)
                if (read < 0) {
                    // 權限被中途撤回、或音訊裝置被搶走，都會走到這裡。
                    failure = "AudioRecord.read failed: $read"
                    listener?.onError(failure)
                    break
                }
                if (read == 0) continue

                recordedSamples += read / 2
                elapsedMs = recordedSamples * 1000 / SAMPLE_RATE
                listener?.onAmplitude(rms(pcm, read), elapsedMs)

                // 這一批 PCM 必須全部餵進編碼器。沒有可用的輸入緩衝就先排空
                // 輸出再試，不能直接丟掉 —— 丟掉就是真的掉音。
                var offset = 0
                while (offset < read) {
                    val index = codec.dequeueInputBuffer(10_000)
                    if (index >= 0) {
                        val buffer = codec.getInputBuffer(index)
                        if (buffer == null) {
                            codec.queueInputBuffer(index, 0, 0, 0, 0)
                        } else {
                            buffer.clear()
                            val size = minOf(buffer.remaining(), read - offset)
                            buffer.put(pcm, offset, size)
                            codec.queueInputBuffer(
                                index,
                                0,
                                size,
                                encodedSamples * 1_000_000 / SAMPLE_RATE,
                                0,
                            )
                            encodedSamples += size / 2
                            offset += size
                        }
                    }
                    drain(codec, info, writer)
                }
            }

            // 收尾：送出結束旗標，把編碼器裡剩下的幀全部取出來。
            val index = codec.dequeueInputBuffer(100_000)
            if (index >= 0) {
                codec.queueInputBuffer(
                    index,
                    0,
                    0,
                    encodedSamples * 1_000_000 / SAMPLE_RATE,
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                )
                var attempts = 0
                while (attempts < 100 && !drain(codec, info, writer)) {
                    attempts++
                }
            }

            writer.finish()
            writer = null
        } catch (e: Exception) {
            failure = e.message ?: e.toString()
            listener?.onError(failure)
        } finally {
            try {
                writer?.finish()
            } catch (_: Exception) {
            }
            try {
                if (recorder?.state == AudioRecord.STATE_INITIALIZED) recorder.stop()
                recorder?.release()
            } catch (_: Exception) {
            }
            try {
                codec?.stop()
                codec?.release()
            } catch (_: Exception) {
            }
            // running 仍為 true 代表迴圈是被中斷的；服務被系統回收時
            // 也會走到 stop()，但沒有經過 ACTION_STOP，同樣算中斷。
            val interrupted = failure != null || running || !stopRequestedByUser
            running = false
            isRecording = false
            listener?.onStopped(interrupted, failure)
            if (interrupted) {
                // 被打斷時沒有人會呼叫 stop()，通知與 WakeLock 必須自己收掉。
                Handler(Looper.getMainLooper()).post { stop() }
            }
        }
    }

    /** 取出編碼器輸出並落盤。回傳 true 代表已看到結束旗標。 */
    private fun drain(
        codec: MediaCodec,
        info: MediaCodec.BufferInfo,
        writer: ChunkWriter,
    ): Boolean {
        while (true) {
            val index = codec.dequeueOutputBuffer(info, 0)
            if (index < 0) return false

            val endOfStream = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0

            if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                // ADTS 標頭自帶設定，csd 不需要寫檔。
                codec.releaseOutputBuffer(index, false)
                continue
            }
            if (info.size > 0) {
                val buffer = codec.getOutputBuffer(index)
                if (buffer != null) {
                    val frame = ByteArray(info.size + 7)
                    writeAdtsHeader(frame, frame.size)
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    buffer.get(frame, 7, info.size)
                    writer.write(frame)
                }
            }
            codec.releaseOutputBuffer(index, false)
            if (endOfStream) return true
        }
    }

    /** 依取樣數輪替輸出檔，每片 [CHUNK_SECONDS] 秒。 */
    private inner class ChunkWriter(private val dir: File) {
        private var index = 0
        private var samples = 0
        private var stream = FileOutputStream(chunkFile(0))
        private var finished = false

        fun write(frame: ByteArray) {
            stream.write(frame)
            samples += SAMPLES_PER_FRAME
            if (samples >= CHUNK_SAMPLES) {
                closeStream()
                index += 1
                samples = 0
                stream = FileOutputStream(chunkFile(index))
            }
        }

        fun finish() {
            if (finished) return
            finished = true
            closeStream()
        }

        private fun closeStream() {
            stream.flush()
            stream.fd.sync()
            stream.close()
            listener?.onChunk(chunkFile(index).absolutePath, index)
        }

        private fun chunkFile(i: Int) = File(dir, String.format("chunk_%04d.aac", i))
    }

    /** 7 位元組 ADTS 標頭：AAC-LC、16 kHz、單聲道、無 CRC。 */
    private fun writeAdtsHeader(packet: ByteArray, packetLength: Int) {
        val profile = 2 // AAC-LC
        val samplingFrequencyIndex = 8 // 16000 Hz
        val channelConfig = 1

        packet[0] = 0xFF.toByte()
        packet[1] = 0xF1.toByte()
        packet[2] = (((profile - 1) shl 6) +
            (samplingFrequencyIndex shl 2) +
            (channelConfig shr 2)).toByte()
        packet[3] = (((channelConfig and 3) shl 6) + (packetLength shr 11)).toByte()
        packet[4] = ((packetLength and 0x7FF) shr 3).toByte()
        packet[5] = (((packetLength and 7) shl 5) + 0x1F).toByte()
        packet[6] = 0xFC.toByte()
    }

    private fun rms(pcm: ByteArray, length: Int): Double {
        var sum = 0.0
        var i = 0
        while (i + 1 < length) {
            val sample = ((pcm[i + 1].toInt() shl 8) or (pcm[i].toInt() and 0xFF)).toShort()
            sum += sample.toDouble() * sample.toDouble()
            i += 2
        }
        val count = length / 2
        if (count == 0) return 0.0
        return sqrt(sum / count) / Short.MAX_VALUE
    }

    // ------------------------------------------------------------ notification

    private fun startForegroundNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "錄音中",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) }
            manager.createNotificationChannel(channel)
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pending = launch?.let {
            PendingIntent.getActivity(
                this, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val notification: Notification =
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("錄音中")
                .setContentText("AI 工作副駕駛正在錄音")
                .setSmallIcon(android.R.drawable.presence_audio_online)
                .setOngoing(true)
                .setContentIntent(pending)
                .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun acquireWakeLock() {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "aivoice:recording").apply {
            setReferenceCounted(false)
            acquire(4 * 60 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {
        }
        wakeLock = null
    }
}
