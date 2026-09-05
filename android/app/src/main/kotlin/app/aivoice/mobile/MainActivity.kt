package app.aivoice.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var recordingChannel: RecordingChannel? = null
    private var asrBridge: AsrBridge? = null
    private var playbackBridge: PlaybackBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        recordingChannel = RecordingChannel(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        asrBridge = AsrBridge(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        playbackBridge = PlaybackBridge(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (recordingChannel?.onRequestPermissionsResult(
                requestCode, permissions, grantResults,
            ) == true
        ) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        recordingChannel?.dispose()
        recordingChannel = null
        asrBridge?.dispose()
        asrBridge = null
        playbackBridge?.dispose()
        playbackBridge = null
        super.onDestroy()
    }
}
