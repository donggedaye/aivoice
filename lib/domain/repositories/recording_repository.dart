import '../entities/recording.dart';

abstract class RecordingRepository {
  Future<PermissionStatus> permissionStatus();

  Future<PermissionStatus> requestPermissions();

  Future<void> openAppSettings();

  Future<Recording> start();

  Future<void> stop();

  Future<bool> isRecording();

  Stream<RecordingEvent> events();

  /// 讀取 [dirPath] 下的分片，量測分片數與總時長。
  Future<RecordingSummary> summarize(Recording recording);

  /// 把分片依序串成單一檔案，回傳輸出路徑。
  Future<String> mergeChunks(Recording recording);
}
