import '../entities/claim.dart';

/// 分析出來的 claim 存在哪裡。呼叫 LLM 代理不歸這裡管。
///
/// 跟轉寫那一側一樣的分工：這裡只負責存取，產生 claim 的那一側（網路）
/// 是另一個 repository，排在 10/C。
abstract class ClaimRepository {
  /// 沒分析過回傳 null。分析過但一條都沒留下（全被擋掉）回傳空陣列。
  ///
  /// 兩者不一樣，不要混在一起：空陣列代表不必再打一次網路請求。
  /// 分析要花錢又有每日上限，重複送比重轉更不能接受。
  Future<List<Claim>?> load(String recordingId);

  /// 同一筆錄音重新分析會覆寫舊結果。
  ///
  /// [source] 另外傳而不是從 claim 身上讀：一條都沒留下的時候也要記得
  /// 是誰分析的。
  Future<void> save(
    String recordingId,
    ClaimBatch batch, {
    required String source,
  });

  /// 被擋掉的條數。用來知道提示詞多常生出沒有依據的結論。
  /// 沒分析過回傳 null。
  Future<int?> droppedCount(String recordingId);

  /// 使用者逐條確認或拒絕。
  Future<void> updateAction(String claimId, UserAction action);

  Future<void> delete(String recordingId);

  Future<void> deleteAll();
}
