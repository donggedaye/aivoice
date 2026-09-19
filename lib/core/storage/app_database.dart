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

@DriftDatabase(tables: [Transcripts, TranscriptSegments])
class AppDatabase extends _$AppDatabase {
  /// 測試傳入 `NativeDatabase.memory()`；正式啟動不傳，開手機上的檔案。
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'aivoice'));

  @override
  int get schemaVersion => 1;
}
