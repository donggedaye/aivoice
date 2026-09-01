import 'dart:io';

import '../../core/platform/asr_channel.dart';
import '../../core/storage/model_manager.dart';
import '../../core/utils/opencc.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/repositories/transcription_repository.dart';
import '../local/asr_worker.dart';

const int _sampleRate = 16000;

/// 轉寫用的中間產物。兩個都可以隨時從分片重建，所以用完就刪 ——
/// 「不自動刪除」保護的是原始錄音分片，不是這些暫存。
/// 未壓縮的 PCM 是 115 MB/小時，留著會比原始音訊還占空間。
const String _tempMergedName = 'transcode.aac';
const String _tempPcmName = 'transcode.pcm';

class TranscriptionRepositoryImpl implements TranscriptionRepository {
  const TranscriptionRepositoryImpl(
    this._asr,
    this._models,
    this._recordings,
    this._worker,
  );

  final AsrChannel _asr;
  final ModelManager _models;
  final RecordingRepository _recordings;
  final AsrWorker _worker;

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

      final raw = await _worker.transcribe(
        modelPath: await _models.pathOf(kSenseVoiceFiles[kModelIndex]),
        tokensPath: await _models.pathOf(kSenseVoiceFiles[kTokensIndex]),
        vadPath: await _models.pathOf(kSenseVoiceFiles[kVadIndex]),
        pcmPath: decoded.path,
      );

      // SenseVoice 輸出簡體，這裡統一轉成台灣正體再交給上層。
      final converter = await OpenCC.s2twp();

      return Transcript(
        recordingId: recording.id,
        segments: [
          for (var i = 0; i < raw.length; i++)
            TranscriptSegment(
              id: '${recording.id}-${i.toString().padLeft(4, '0')}',
              startMs: raw[i].startMs,
              endMs: raw[i].endMs,
              text: converter.convert(raw[i].text),
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
