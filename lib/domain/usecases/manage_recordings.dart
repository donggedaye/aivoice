import '../entities/recording.dart';
import '../repositories/claim_repository.dart';
import '../repositories/recording_repository.dart';
import '../repositories/transcript_repository.dart';

/// 瀏覽與刪除已經錄好的音檔。
///
/// 錄音本身走 [RecordAudio]，這裡只管錄完之後的那些檔案，
/// 以及跟著那筆錄音走的轉寫與分析結果。
class ManageRecordings {
  const ManageRecordings(this._recordings, this._transcripts, this._claims);

  final RecordingRepository _recordings;
  final TranscriptRepository _transcripts;
  final ClaimRepository _claims;

  Future<List<RecordingSummary>> list() => _recordings.list();

  /// 先刪檔案再刪轉寫與分析：錄音進行中檔案那步會擋下來，
  /// 這時候轉寫與分析也不該被清掉。
  Future<void> delete(String id) async {
    await _recordings.delete(id);
    await _transcripts.delete(id);
    await _claims.delete(id);
  }

  Future<int> deleteAll() async {
    final removed = await _recordings.deleteAll();
    await _transcripts.deleteAll();
    await _claims.deleteAll();
    return removed;
  }

  Future<int> usedBytes() => _recordings.usedBytes();
}
