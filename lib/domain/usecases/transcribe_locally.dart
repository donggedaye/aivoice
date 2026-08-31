import '../entities/recording.dart';
import '../entities/transcript.dart';
import '../repositories/transcription_repository.dart';

/// 端側轉寫。音訊不離開手機。
class TranscribeLocally {
  const TranscribeLocally(this._repository);

  final TranscriptionRepository _repository;

  Future<Transcript> call(Recording recording) =>
      _repository.transcribe(recording);
}
