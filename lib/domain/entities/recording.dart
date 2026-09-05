/// 權限狀態。`permanentlyDenied` 代表使用者選了「不再詢問」，只能引導去系統設定。
enum PermissionState { granted, denied, permanentlyDenied }

class PermissionStatus {
  const PermissionStatus({
    required this.microphone,
    required this.notifications,
  });

  final PermissionState microphone;
  final PermissionState notifications;

  bool get canRecord => microphone == PermissionState.granted;
}

/// 一次錄音。分片檔案放在 [dirPath] 之下。
class Recording {
  const Recording({
    required this.id,
    required this.dirPath,
    required this.startedAt,
  });

  final String id;
  final String dirPath;
  final DateTime startedAt;
}

/// 單一分片的實測資訊。時長由 ADTS 幀數算出，不是服務回報的數字。
class ChunkInfo {
  const ChunkInfo({
    required this.path,
    required this.index,
    required this.bytes,
    required this.frames,
    required this.duration,
  });

  final String path;
  final int index;
  final int bytes;
  final int frames;
  final Duration duration;
}

/// 錄音結束後從檔案量測出來的結果，用來驗證「20 分鐘不丟」。
class RecordingSummary {
  const RecordingSummary({
    required this.id,
    required this.dirPath,
    required this.startedAt,
    required this.chunks,
    required this.duration,
    required this.totalBytes,
    required this.hasCorruptChunk,
  });

  final String id;
  final String dirPath;
  final DateTime startedAt;
  final List<ChunkInfo> chunks;
  final Duration duration;
  final int totalBytes;

  /// 任一分片的 ADTS 同步字失效，代表該檔尾端被截斷。
  final bool hasCorruptChunk;

  int get chunkCount => chunks.length;

  Recording get recording =>
      Recording(id: id, dirPath: dirPath, startedAt: startedAt);
}

sealed class RecordingEvent {
  const RecordingEvent();
}

class AmplitudeEvent extends RecordingEvent {
  const AmplitudeEvent({required this.rms, required this.elapsed});

  final double rms;
  final Duration elapsed;
}

class ChunkEvent extends RecordingEvent {
  const ChunkEvent({required this.path, required this.index});

  final String path;
  final int index;
}

class RecordingErrorEvent extends RecordingEvent {
  const RecordingErrorEvent(this.message);

  final String message;
}

/// 錄音迴圈結束。[interrupted] 為 true 代表不是使用者按停止，
/// 而是被系統打斷（權限被撤回、音訊裝置被搶走）。
class StoppedEvent extends RecordingEvent {
  const StoppedEvent({required this.interrupted, this.message});

  final bool interrupted;
  final String? message;
}
