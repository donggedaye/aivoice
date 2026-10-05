import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 一次錄音的轉寫結果。
///
/// 沒辨識到語音的錄音會產生 0 段，所以這張表必須存在 ——
/// 只看 [TranscriptSegments] 分不出「轉過但沒有語音」與「還沒轉過」，
/// 每次點開都會重轉。
///
/// 錄音本身仍以檔案系統為準（目錄名就是 id），這裡不另外存一份。
@DataClassName('TranscriptRow')
class Transcripts extends Table {
  TextColumn get recordingId => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// 什麼產生了這份轉寫，例如 `asr:sensevoice-small@int8`。
  /// 換模型之後要知道舊的結果是誰轉的。
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {recordingId};
}

/// 轉寫段落。欄位名 `content` 而不是 `text` —— `text()` 是 drift 的欄位建構子，
/// 同名會蓋掉它。
@DataClassName('TranscriptSegmentRow')
@TableIndex(name: 'segments_by_recording', columns: {#recordingId})
class TranscriptSegments extends Table {
  TextColumn get id => text()();
  TextColumn get recordingId => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  TextColumn get content => text()();
  RealColumn get confidence => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 一次分析的表頭。
///
/// 跟 [Transcripts] 同樣的理由：全部的 claim 都被擋掉會留下 0 條，
/// 只看 [Claims] 分不出「分析過但沒留下東西」與「還沒分析過」。
/// 分析要花錢又有每日上限，每次點開都重送比重轉更不能接受。
@DataClassName('AnalysisRow')
class Analyses extends Table {
  TextColumn get recordingId => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// 誰做出來的，例如
  /// `asr:sensevoice-small@int8 + llm:<model>@analyzer_v1+verifier_v1`。
  TextColumn get source => text()();

  /// 被客戶端擋掉的條數。用來知道提示詞多常生出沒有依據的結論。
  IntColumn get droppedCount => integer()();

  @override
  Set<Column> get primaryKey => {recordingId};
}

/// 模型分析出來的一條結論。欄位對應 `schema/claim.json`。
///
/// 欄位名 `content` 而不是 `text`，跟 [TranscriptSegments] 同樣的原因 ——
/// `text()` 是 drift 的欄位建構子。
///
/// `missingInfo` 與 `entityIds` 存 JSON 字串：都是純字串清單，不會被查，
/// 多開兩張子表只是多兩個真相來源。`evidence` 相反，要按段落回溯，
/// 所以是真的子表。
@DataClassName('ClaimRow')
@TableIndex(name: 'claims_by_recording', columns: {#recordingId})
class Claims extends Table {
  TextColumn get id => text()();
  TextColumn get recordingId => text()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  TextColumn get content => text()();
  TextColumn get reasoning => text().nullable()();
  TextColumn get confidence => text()();
  TextColumn get missingInfo => text()();
  TextColumn get owner => text().nullable()();

  /// `YYYY-MM-DD`。存字串而不是 `DateTime`：契約是純日期。
  TextColumn get dueDate => text().nullable()();
  TextColumn get entityIds => text()();
  TextColumn get userAction => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 一條 claim 的依據。
///
/// 主鍵用 (claimId, ordinal) 而不是自增 id：順序要保住（卡片上照序顯示），
/// 而且重新分析是先刪後插，沒有必要留一個會一直長大的代理鍵。
@DataClassName('ClaimEvidenceRow')
@TableIndex(name: 'evidence_by_claim', columns: {#claimId})
class ClaimEvidence extends Table {
  TextColumn get claimId => text()();
  IntColumn get ordinal => integer()();
  TextColumn get segmentId => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  TextColumn get quote => text()();

  @override
  Set<Column> get primaryKey => {claimId, ordinal};
}

@DriftDatabase(
  tables: [Transcripts, TranscriptSegments, Analyses, Claims, ClaimEvidence],
)
class AppDatabase extends _$AppDatabase {
  /// 測試傳入 `NativeDatabase.memory()`；正式啟動不傳，開手機上的檔案。
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'aivoice'));

  @override
  int get schemaVersion => 2;

  /// 1 → 2：加上分析結果的三張表。9/21 上線時只建了轉寫兩張表，
  /// 當時 `schema/claim.json` 還沒定案，建了幾乎一定要再遷移一次。
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(analyses);
            await m.createTable(claims);
            await m.createTable(claimEvidence);
            await m.create(claimsByRecording);
            await m.create(evidenceByClaim);
          }
        },
      );
}
