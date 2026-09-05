import 'package:flutter/services.dart';

import '../../domain/entities/recording.dart';

/// `RecordingService` / `RecordingChannel` 的 Dart 端封裝。
class RecordingChannel {
  const RecordingChannel();

  static const MethodChannel _method =
      MethodChannel('app.aivoice.mobile/recording');
  static const EventChannel _events =
      EventChannel('app.aivoice.mobile/recording_events');

  Future<PermissionStatus> permissionStatus() async {
    final result = await _method.invokeMapMethod<String, String>(
      'permissionStatus',
    );
    return _parseStatus(result);
  }

  Future<PermissionStatus> requestPermissions() async {
    final result = await _method.invokeMapMethod<String, String>(
      'requestPermissions',
    );
    return _parseStatus(result);
  }

  Future<void> openAppSettings() => _method.invokeMethod<void>('openAppSettings');

  /// 所有錄音目錄的根。列表與刪除都以這個路徑為界。
  Future<String> recordingsDir() async {
    final path = await _method.invokeMethod<String>('recordingsDir');
    if (path == null) throw StateError('recordingsDir returned null');
    return path;
  }

  Future<Recording> start() async {
    final result = await _method.invokeMapMethod<String, String>('start');
    if (result == null) {
      throw StateError('start returned no recording');
    }
    return Recording(
      id: result['id']!,
      dirPath: result['dir']!,
      startedAt: DateTime.now(),
    );
  }

  Future<void> stop() => _method.invokeMethod<void>('stop');

  Future<bool> isRecording() async {
    final result = await _method.invokeMapMethod<String, dynamic>('state');
    return (result?['isRecording'] as bool?) ?? false;
  }

  Stream<RecordingEvent> events() {
    return _events.receiveBroadcastStream().map((dynamic raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      switch (map['type'] as String) {
        case 'amplitude':
          return AmplitudeEvent(
            rms: (map['rms'] as num).toDouble(),
            elapsed: Duration(milliseconds: map['elapsedMs'] as int),
          );
        case 'chunk':
          return ChunkEvent(
            path: map['path'] as String,
            index: map['index'] as int,
          );
        case 'stopped':
          return StoppedEvent(
            interrupted: map['interrupted'] as bool? ?? false,
            message: map['message'] as String?,
          );
        default:
          return RecordingErrorEvent(map['message'] as String? ?? 'unknown');
      }
    });
  }

  PermissionState _parseState(String? value) {
    switch (value) {
      case 'granted':
        return PermissionState.granted;
      case 'permanentlyDenied':
        return PermissionState.permanentlyDenied;
      default:
        return PermissionState.denied;
    }
  }

  PermissionStatus _parseStatus(Map<String, String>? result) {
    return PermissionStatus(
      microphone: _parseState(result?['microphone']),
      notifications: _parseState(result?['notifications']),
    );
  }
}
