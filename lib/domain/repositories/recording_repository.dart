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

  /// 依錄音順序列出分片路徑。回放要靠這個順序算幀的編號。
  Future<List<String>> chunkPaths(Recording recording);

  /// 把分片依序串成單一檔案，回傳輸出路徑。
  /// [outputName] 預設是使用者按「合併」時要保留的 `full.aac`；
  /// 轉寫那種用完就丟的中間產物請自己指定別的檔名。
  Future<String> mergeChunks(Recording recording, {String outputName});
}
