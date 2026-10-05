import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/storage/app_database.dart';
import 'package:aivoice/data/repositories_impl/claim_repository_impl.dart';
import 'package:aivoice/data/repositories_impl/transcript_repository_impl.dart';
import 'package:aivoice/domain/entities/claim.dart';
import 'package:aivoice/domain/entities/transcript.dart';

const _asrSource = 'asr:sensevoice-small@int8';
const _source =
    '$_asrSource + llm:fixture-model@analyzer_v1+verifier_v1';

Transcript transcriptFor(String recordingId, int segmentCount) => Transcript(
      recordingId: recordingId,
      segments: [
        for (var i = 0; i < segmentCount; i++)
          TranscriptSegment(
            id: '$recordingId-${i.toString().padLeft(4, '0')}',
            startMs: i * 5000,
            endMs: i * 5000 + 4000,
            text: '第 $i 段',
          ),
      ],
    );

ClaimBatch oneClaim(String recordingId) => ClaimBatch(
      kept: [
        Claim(
          id: '$recordingId-c0000',
          recordingId: recordingId,
          type: ClaimType.fact,
          category: ClaimCategory.summary,
          text: '客戶合約明年三月到期。',
          evidence: [
            Evidence(
              segmentId: '$recordingId-0000',
              startMs: 0,
              endMs: 4000,
              quote: '合約明年三月到期',
            ),
            Evidence(
              segmentId: '$recordingId-0001',
              startMs: 5000,
              endMs: 9000,
              quote: '大概是三月中',
            ),
          ],
          confidence: Confidence.high,
          createdAt: DateTime.utc(2026, 10, 5, 7, 30),
          source: _source,
        ),
      ],
      dropped: const [],
    );

/// 把檔案退回 9/21 上線時的樣子：只有轉寫兩張表，`user_version` 是 1。
///
/// drift 判斷要不要遷移只看 `user_version`，所以退回來的檔案跟真實裝置上
/// 那個還沒升級的資料庫沒有分別。DROP TABLE 會連索引一起帶走。
Future<void> downgradeToV1(AppDatabase db) async {
  await db.customStatement('DROP TABLE claim_evidence');
  await db.customStatement('DROP TABLE claims');
  await db.customStatement('DROP TABLE analyses');
  await db.customStatement('PRAGMA user_version = 1');
}

Future<List<String>> tableNames(AppDatabase db, List<String> wanted) async {
  final rows = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE name IN "
    "(${wanted.map((n) => "'$n'").join(', ')}) ORDER BY name",
  ).get();
  return [for (final row in rows) row.read<String>('name')];
}

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('aivoice_migration');
    file = File('${dir.path}/aivoice.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  test('a v1 database on the phone keeps its transcripts after upgrading',
      () async {
    final before = AppDatabase(NativeDatabase(file));
    await TranscriptRepositoryImpl(before)
        .save(transcriptFor('1788612012710', 3), source: _asrSource);
    await downgradeToV1(before);
    expect(await tableNames(before, ['claims', 'transcripts']), ['transcripts']);
    await before.close();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);

    final transcript =
        await TranscriptRepositoryImpl(after).load('1788612012710');

    expect(transcript, isNotNull);
    expect(transcript!.segments, hasLength(3));
    expect(transcript.segments[1].text, '第 1 段');
  });

  test('the upgrade brings up the three analysis tables and their indexes',
      () async {
    final before = AppDatabase(NativeDatabase(file));
    await downgradeToV1(before);
    await before.close();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);

    final store = ClaimRepositoryImpl(after);
    await store.save('1788612012710', oneClaim('1788612012710'),
        source: _source);

    final loaded = await store.load('1788612012710');
    expect(loaded, hasLength(1));
    expect(loaded!.single.evidence, hasLength(2));
    expect(loaded.single.evidence.last.quote, '大概是三月中');

    expect(
      await tableNames(after, ['analyses', 'claims', 'claim_evidence']),
      ['analyses', 'claim_evidence', 'claims'],
    );
    // 索引沒跟著建起來，列表就是全表掃描。
    expect(
      await tableNames(after, ['claims_by_recording', 'evidence_by_claim']),
      ['claims_by_recording', 'evidence_by_claim'],
    );
  });

  test('a fresh install lands on v2 without running the upgrade', () async {
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final store = ClaimRepositoryImpl(db);
    await store.save('1788612012710', oneClaim('1788612012710'),
        source: _source);

    expect(await store.load('1788612012710'), hasLength(1));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 2);
  });
}
