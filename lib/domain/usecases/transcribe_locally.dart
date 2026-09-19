import '../entities/recording.dart';
import '../entities/transcript.dart';
import '../repositories/transcript_repository.dart';
import '../repositories/transcription_repository.dart';

/// 端側轉寫。音訊不離開手機。
///
/// 轉過的結果會存起來，再點開同一筆錄音直接拿舊的 ——
/// 10 分鐘的音檔要轉 30 秒，不該每次點開都重來。
class TranscribeLocally {
  const TranscribeLocally(this._transcription, this._store);

  final TranscriptionRepository _transcription;
  final TranscriptRepository _store;

  /// [force] 給「重新轉寫」用：忽略存起來的結果，重轉並覆寫。
  Future<Transcript> call(Recording recording, {bool force = false}) async {
    if (!force) {
      final stored = await _store.load(recording.id);
      if (stored != null) return stored;
    }

    final transcript = await _transcription.transcribe(recording);
    await _store.save(transcript, source: _transcription.source);
    return transcript;
  }
}
