import '../entities/playback.dart';
import '../entities/recording.dart';
import '../entities/transcript.dart';
import '../repositories/playback_repository.dart';

/// 回放轉寫段落。UI 只透過這個類別播音，不直接碰平台通道。
class PlaySegment {
  const PlaySegment(this._repository);

  final PlaybackRepository _repository;

  Future<Duration> call(Recording recording, TranscriptSegment segment) =>
      _repository.playSegment(
        recording,
        startMs: segment.startMs,
        endMs: segment.endMs,
      );

  Future<void> stop() => _repository.stop();

  Stream<PlaybackEvent> events() => _repository.events();
}
