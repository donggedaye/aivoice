import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../core/platform/asr_channel.dart';
import '../../core/storage/model_manager.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/repositories/transcription_repository.dart';

const int _sampleRate = 16000;

/// 轉寫用的中間產物。兩個都可以隨時從分片重建，所以用完就刪 ——
/// 「不自動刪除」保護的是原始錄音分片，不是這些暫存。
/// 未壓縮的 PCM 是 115 MB/小時，留著會比原始音訊還占空間。
const String _tempMergedName = 'transcode.aac';
const String _tempPcmName = 'transcode.pcm';

class TranscriptionRepositoryImpl implements TranscriptionRepository {
  const TranscriptionRepositoryImpl(this._asr, this._models, this._recordings);

  final AsrChannel _asr;
  final ModelManager _models;
  final RecordingRepository _recordings;

  @override
  Future<Transcript> transcribe(Recording recording) async {
    final separator = Platform.pathSeparator;
    final mergedPath = '${recording.dirPath}$separator$_tempMergedName';
    final pcmPath = '${recording.dirPath}$separator$_tempPcmName';

    try {
      final merged = await _recordings.mergeChunks(
        recording,
        outputName: _tempMergedName,
      );

      final decoded = await _asr.decodeToPcm(input: merged, output: pcmPath);
      if (decoded.sampleRate != _sampleRate) {
        throw StateError('解碼後取樣率是 ${decoded.sampleRate} Hz，不是 $_sampleRate Hz');
      }
      if (decoded.bytes <= 0) {
        throw StateError('解碼後沒有音訊資料');
      }

      final modelPath = await _models.pathOf(kSenseVoiceFiles[0]);
      final tokensPath = await _models.pathOf(kSenseVoiceFiles[1]);

      // 辨識是同步的 FFI 呼叫，放在主 isolate 會把畫面凍住，所以整段丟到獨立
      // isolate。代價是每次都要重新載入模型，9/4 接 VAD 時再改成常駐。
      final text = await Isolate.run(
        () => _recognize(
          modelPath: modelPath,
          tokensPath: tokensPath,
          pcmPath: decoded.path,
        ),
      );

      final durationMs = (decoded.bytes ~/ 2) * 1000 ~/ _sampleRate;
      return Transcript(
        recordingId: recording.id,
        segments: [
          TranscriptSegment(
            id: '${recording.id}-0000',
            startMs: 0,
            endMs: durationMs,
            text: text.trim(),
          ),
        ],
      );
    } finally {
      // 失敗也要清，不然重試會一直堆暫存。
      await _discard(mergedPath);
      await _discard(pcmPath);
    }
  }

  Future<void> _discard(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // 清不掉就算了，下一次轉寫會覆寫同名檔案。
    }
  }
}

/// 在獨立 isolate 執行：載入模型、讀 PCM、辨識、釋放。
String _recognize({
  required String modelPath,
  required String tokensPath,
  required String pcmPath,
}) {
  sherpa.initBindings();

  final recognizer = sherpa.OfflineRecognizer(
    sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        senseVoice: sherpa.OfflineSenseVoiceModelConfig(
          model: modelPath,
          useInverseTextNormalization: true,
        ),
        tokens: tokensPath,
        modelType: 'sense_voice',
        numThreads: 2,
        debug: false,
      ),
    ),
  );

  try {
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(
        samples: _readSamples(File(pcmPath)),
        sampleRate: _sampleRate,
      );
      recognizer.decode(stream);
      return recognizer.getResult(stream).text;
    } finally {
      stream.free();
    }
  } finally {
    recognizer.free();
  }
}

/// 16-bit 小端序 PCM 轉成 sherpa-onnx 要的 -1..1 float。
Float32List _readSamples(File file) {
  final bytes = file.readAsBytesSync();
  final view = ByteData.sublistView(bytes);
  final count = bytes.length ~/ 2;
  final samples = Float32List(count);
  for (var i = 0; i < count; i++) {
    samples[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return samples;
}
