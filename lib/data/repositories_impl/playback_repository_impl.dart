import 'dart:io';

import '../../core/platform/playback_channel.dart';
import '../../core/utils/adts.dart';
import '../../domain/entities/playback.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/repositories/recording_repository.dart';

/// 回放用的中間產物。播完就刪，跟轉寫的暫存一樣可以隨時從分片重建。
const String _segmentName = 'segment.aac';

class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl(this._channel, this._recordings);

  final PlaybackChannel _channel;
  final RecordingRepository _recordings;

  /// 正在播的那個暫存檔。停下來之後要刪掉它。
  File? _playing;

  /// 把段落涵蓋的 ADTS 幀抽出來寫成一個小檔再播。
  ///
  /// 不用 seek：ADTS 沒有索引，播放器只能靠位元率估位置。
  /// 每幀固定 64 ms，直接算幀編號才對得準，跨分片邊界也不用特別處理。
  @override
  Future<Duration> playSegment(
    Recording recording, {
    required int startMs,
    required int endMs,
  }) async {
    final paths = await _recordings.chunkPaths(recording);
    if (paths.isEmpty) {
      throw StateError('找不到這次錄音的分片');
    }

    final collector = AdtsRangeCollector(startMs: startMs, endMs: endMs);
    for (final path in paths) {
      // 收滿就不再讀，長錄音不會整包載進記憶體。
      if (collector.isDone) break;
      collector.add(await File(path).readAsBytes());
    }

    final bytes = collector.build();
    if (bytes.isEmpty) {
      throw StateError('這段時間沒有對應的音訊');
    }

    final output = File(
      '${recording.dirPath}${Platform.pathSeparator}$_segmentName',
    );
    await output.writeAsBytes(bytes, flush: true);
    _playing = output;
    return _channel.play(output.path);
  }

  @override
  Future<void> stop() async {
    await _channel.stop();
    final file = _playing;
    _playing = null;
    try {
      if (file != null && file.existsSync()) await file.delete();
    } catch (_) {
      // 刪不掉就算了，下一段會覆寫同名檔案。
    }
  }

  @override
  Stream<PlaybackEvent> events() => _channel.events();
}
