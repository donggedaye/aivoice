import '../entities/playback.dart';
import '../entities/recording.dart';

abstract class PlaybackRepository {
  /// 播放 [recording] 裡 `[startMs, endMs)` 這段音訊。
  /// 回傳播放器解析出來的時長，用來核對切出來的段落。
  Future<Duration> playSegment(
    Recording recording, {
    required int startMs,
    required int endMs,
  });

  Future<void> stop();

  Stream<PlaybackEvent> events();
}
