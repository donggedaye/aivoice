import 'package:flutter/services.dart';

import '../../domain/entities/playback.dart';

/// `PlaybackBridge` 的 Dart 端封裝：播一個本機音檔、停止、聽結束事件。
class PlaybackChannel {
  const PlaybackChannel();

  static const MethodChannel _method =
      MethodChannel('app.aivoice.mobile/playback');
  static const EventChannel _events =
      EventChannel('app.aivoice.mobile/playback_events');

  /// 回傳播放器自己解析出來的時長，可以拿來對照切出來的段落對不對。
  Future<Duration> play(String path) async {
    final result = await _method.invokeMapMethod<String, dynamic>(
      'play',
      {'path': path},
    );
    return Duration(milliseconds: (result?['durationMs'] as num? ?? 0).toInt());
  }

  Future<void> stop() => _method.invokeMethod<void>('stop');

  Stream<PlaybackEvent> events() {
    return _events.receiveBroadcastStream().map((dynamic raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      switch (map['type'] as String?) {
        case 'completed':
          return const PlaybackCompleted();
        default:
          return PlaybackFailed(map['message'] as String? ?? 'unknown');
      }
    });
  }
}
