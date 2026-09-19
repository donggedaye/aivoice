import '../entities/transcript.dart';

/// 已經轉好的結果存在哪裡。錄音檔本身不歸這裡管。
abstract class TranscriptRepository {
  /// 沒轉過回傳 null。轉過但沒辨識到語音會回傳段落為空的 [Transcript]，
  /// 兩者不一樣，不要混在一起。
  Future<Transcript?> load(String recordingId);

  /// 同一筆錄音重轉會覆寫舊結果。
  Future<void> save(Transcript transcript, {required String source});

  Future<void> delete(String recordingId);

  Future<void> deleteAll();
}
