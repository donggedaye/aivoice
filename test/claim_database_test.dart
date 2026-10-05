import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/storage/app_database.dart';
import 'package:aivoice/data/repositories_impl/claim_repository_impl.dart';
import 'package:aivoice/domain/entities/claim.dart';

const _source =
    'asr:sensevoice-small@int8 + llm:fixture-model@analyzer_v1+verifier_v1';
final _createdAt = DateTime.utc(2026, 10, 5, 7, 30);

Claim claimFor(
  String recordingId,
  int index, {
  ClaimType type = ClaimType.fact,
  int evidenceCount = 1,
  List<String> missingInfo = const [],
  String? dueDate,
  String? owner,
}) {
  return Claim(
    id: '$recordingId-c${index.toString().padLeft(4, '0')}',
    recordingId: recordingId,
    type: type,
    category: ClaimCategory.summary,
    text: '第 $index 條',
    evidence: [
      for (var i = 0; i < evidenceCount; i++)
        Evidence(
          segmentId: '$recordingId-${i.toString().padLeft(4, '0')}',
          startMs: i * 1000,
          endMs: i * 1000 + 900,
          quote: '第 $i 句原話',
        ),
    ],
    reasoning: type == ClaimType.inference || type == ClaimType.suggestion
        ? '第 $index 條的理由'
        : null,
    confidence: missingInfo.isEmpty ? Confidence.high : Confidence.uncertain,
    missingInfo: missingInfo,
    owner: owner,
    dueDate: dueDate,
    createdAt: _createdAt,
    source: _source,
  );
}

ClaimBatch batchOf(List<Claim> kept, {int dropped = 0}) => ClaimBatch(
      kept: kept,
      dropped: [
        for (var i = 0; i < dropped; i++)
          DroppedClaim(index: i, reason: 'FACT 沒有依據'),
      ],
    );

void main() {
  late AppDatabase db;
  late ClaimRepositoryImpl store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = ClaimRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('a recording that was never analysed reads back as null', () async {
    expect(await store.load('1788612012710'), isNull);
    expect(await store.droppedCount('1788612012710'), isNull);
  });

  test('an analysis that kept nothing is not the same as never analysed',
      () async {
    // 全部被擋掉也要留下紀錄，否則每次點開都會再送一次網路請求。
    await store.save(
      '1788612012710',
      batchOf(const [], dropped: 3),
      source: _source,
    );

    expect(await store.load('1788612012710'), isEmpty);
    expect(await store.droppedCount('1788612012710'), 3);
  });

  test('a claim and its evidence survive a round trip in order', () async {
    await store.save(
      '1788612012710',
      batchOf([
        claimFor('1788612012710', 0, evidenceCount: 3),
        claimFor('1788612012710', 1, type: ClaimType.inference),
        claimFor(
          '1788612012710',
          2,
          missingInfo: ['缺日期', '缺人'],
          owner: '我',
          dueDate: '2026-11-30',
        ),
      ]),
      source: _source,
    );

    final loaded = await store.load('1788612012710');

    expect(loaded, hasLength(3));
    expect(loaded!.map((c) => c.id), [
      '1788612012710-c0000',
      '1788612012710-c0001',
      '1788612012710-c0002',
    ]);

    final first = loaded.first;
    expect(first.type, ClaimType.fact);
    expect(first.text, '第 0 條');
    expect(first.evidence, hasLength(3));
    expect(
      first.evidence.map((e) => e.quote),
      ['第 0 句原話', '第 1 句原話', '第 2 句原話'],
    );
    expect(first.evidence[1].startMs, 1000);
    expect(first.evidence[1].endMs, 1900);
    expect(first.evidence.last.segmentId, '1788612012710-0002');
    expect(first.reasoning, isNull);
    expect(first.userAction, UserAction.pending);
    // 讀回來一律是 UTC：契約的 created_at 要帶時區。
    expect(first.createdAt, _createdAt);
    expect(first.createdAt.isUtc, isTrue);
    expect(first.source, _source);

    expect(loaded[1].type, ClaimType.inference);
    expect(loaded[1].reasoning, '第 1 條的理由');

    expect(loaded[2].confidence, Confidence.uncertain);
    expect(loaded[2].missingInfo, ['缺日期', '缺人']);
    expect(loaded[2].owner, '我');
    expect(loaded[2].dueDate, '2026-11-30');
    expect(loaded[2].entityIds, isEmpty);
  });

  test('analysing again replaces the previous claims and their evidence',
      () async {
    await store.save(
      '1788612012710',
      batchOf([
        claimFor('1788612012710', 0, evidenceCount: 3),
        claimFor('1788612012710', 1),
        claimFor('1788612012710', 2),
      ], dropped: 2),
      source: _source,
    );
    await store.save(
      '1788612012710',
      batchOf([claimFor('1788612012710', 0, evidenceCount: 1)]),
      source: _source,
    );

    expect(await store.load('1788612012710'), hasLength(1));
    expect(await store.droppedCount('1788612012710'), 0);
    // 舊的依據不能留在表裡 —— 主鍵是 (claimId, ordinal)，留著會變成孤兒。
    expect(await db.select(db.claimEvidence).get(), hasLength(1));
  });

  test('confirming one claim leaves the others pending', () async {
    await store.save(
      '1788612012710',
      batchOf([claimFor('1788612012710', 0), claimFor('1788612012710', 1)]),
      source: _source,
    );

    await store.updateAction('1788612012710-c0001', UserAction.confirmed);

    final loaded = (await store.load('1788612012710'))!;
    expect(loaded[0].userAction, UserAction.pending);
    expect(loaded[1].userAction, UserAction.confirmed);
  });

  test('rejecting a claim keeps it, it is not deleted', () async {
    // 拒絕是使用者的判斷，要留著才算得出 INFERENCE 被拒率。
    await store.save(
      '1788612012710',
      batchOf([claimFor('1788612012710', 0)]),
      source: _source,
    );

    await store.updateAction('1788612012710-c0000', UserAction.rejected);

    final loaded = (await store.load('1788612012710'))!;
    expect(loaded, hasLength(1));
    expect(loaded.single.userAction, UserAction.rejected);
  });

  test('deleting one recording leaves the others alone', () async {
    await store.save(
      '1788612012710',
      batchOf([claimFor('1788612012710', 0)]),
      source: _source,
    );
    await store.save(
      '1788612862011',
      batchOf([claimFor('1788612862011', 0, evidenceCount: 2)]),
      source: _source,
    );

    await store.delete('1788612012710');

    expect(await store.load('1788612012710'), isNull);
    expect(await store.load('1788612862011'), hasLength(1));
    expect(await db.select(db.claimEvidence).get(), hasLength(2));
  });

  test('deleting everything leaves no evidence behind', () async {
    await store.save(
      '1788612012710',
      batchOf([claimFor('1788612012710', 0)]),
      source: _source,
    );
    await store.save(
      '1788612862011',
      batchOf([claimFor('1788612862011', 0)]),
      source: _source,
    );

    await store.deleteAll();

    expect(await store.load('1788612012710'), isNull);
    expect(await store.load('1788612862011'), isNull);
    expect(await db.select(db.claims).get(), isEmpty);
    expect(await db.select(db.claimEvidence).get(), isEmpty);
    expect(await db.select(db.analyses).get(), isEmpty);
  });
}
