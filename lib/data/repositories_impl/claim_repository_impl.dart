import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/storage/app_database.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';

class ClaimRepositoryImpl implements ClaimRepository {
  const ClaimRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Claim>?> load(String recordingId) async {
    final header = await _header(recordingId);
    if (header == null) return null;

    final rows = await (_db.select(_db.claims)
          ..where((row) => row.recordingId.equals(recordingId))
          ..orderBy([(row) => OrderingTerm(expression: row.id)]))
        .get();
    if (rows.isEmpty) return const [];

    // 一次把這批 claim 的依據全撈出來再分組，不要一條一條查。
    final ids = rows.map((row) => row.id).toList();
    final evidenceRows = await (_db.select(_db.claimEvidence)
          ..where((row) => row.claimId.isIn(ids))
          ..orderBy([(row) => OrderingTerm(expression: row.ordinal)]))
        .get();

    final byClaim = <String, List<Evidence>>{};
    for (final row in evidenceRows) {
      byClaim.putIfAbsent(row.claimId, () => []).add(
            Evidence(
              segmentId: row.segmentId,
              startMs: row.startMs,
              endMs: row.endMs,
              quote: row.quote,
            ),
          );
    }

    return [
      for (final row in rows) _toClaim(row, byClaim[row.id] ?? const []),
    ];
  }

  @override
  Future<void> save(
    String recordingId,
    ClaimBatch batch, {
    required String source,
  }) {
    // 重新分析要整批換掉，不能留下上一次的結論。
    return _db.transaction(() async {
      await delete(recordingId);
      await _db.into(_db.analyses).insert(
            AnalysesCompanion.insert(
              recordingId: recordingId,
              createdAt: DateTime.now(),
              source: source,
              droppedCount: batch.dropped.length,
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.claims, [
          for (final claim in batch.kept) _toRow(claim, recordingId),
        ]);
        b.insertAll(_db.claimEvidence, [
          for (final claim in batch.kept)
            for (var i = 0; i < claim.evidence.length; i++)
              ClaimEvidenceCompanion.insert(
                claimId: claim.id,
                ordinal: i,
                segmentId: claim.evidence[i].segmentId,
                startMs: claim.evidence[i].startMs,
                endMs: claim.evidence[i].endMs,
                quote: claim.evidence[i].quote,
              ),
        ]);
      });
    });
  }

  @override
  Future<int?> droppedCount(String recordingId) async =>
      (await _header(recordingId))?.droppedCount;

  @override
  Future<void> updateAction(String claimId, UserAction action) async {
    await (_db.update(_db.claims)..where((row) => row.id.equals(claimId)))
        .write(ClaimsCompanion(userAction: Value(wireName(action))));
  }

  @override
  Future<void> delete(String recordingId) async {
    // 依據掛在 claim 上而不是錄音上，所以要先問出 id 再刪。
    final ids = (await (_db.selectOnly(_db.claims)
              ..addColumns([_db.claims.id])
              ..where(_db.claims.recordingId.equals(recordingId)))
            .get())
        .map((row) => row.read(_db.claims.id)!)
        .toList();

    if (ids.isNotEmpty) {
      await (_db.delete(_db.claimEvidence)
            ..where((row) => row.claimId.isIn(ids)))
          .go();
    }
    await (_db.delete(_db.claims)
          ..where((row) => row.recordingId.equals(recordingId)))
        .go();
    await (_db.delete(_db.analyses)
          ..where((row) => row.recordingId.equals(recordingId)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.claimEvidence).go();
    await _db.delete(_db.claims).go();
    await _db.delete(_db.analyses).go();
  }

  Future<AnalysisRow?> _header(String recordingId) =>
      (_db.select(_db.analyses)
            ..where((row) => row.recordingId.equals(recordingId)))
          .getSingleOrNull();

  ClaimsCompanion _toRow(Claim claim, String recordingId) =>
      ClaimsCompanion.insert(
        id: claim.id,
        recordingId: recordingId,
        type: wireName(claim.type),
        category: wireName(claim.category),
        content: claim.text,
        reasoning: Value(claim.reasoning),
        confidence: wireName(claim.confidence),
        missingInfo: jsonEncode(claim.missingInfo),
        owner: Value(claim.owner),
        dueDate: Value(claim.dueDate),
        entityIds: jsonEncode(claim.entityIds),
        userAction: wireName(claim.userAction),
        createdAt: claim.createdAt,
        source: claim.source,
      );

  Claim _toClaim(ClaimRow row, List<Evidence> evidence) => Claim(
        id: row.id,
        recordingId: row.recordingId,
        // 寫進去的就是 enum，讀不回來代表資料庫被外力改過，那是 bug 不是輸入問題。
        type: wireLookup(ClaimType.values, row.type)!,
        category: wireLookup(ClaimCategory.values, row.category)!,
        text: row.content,
        evidence: evidence,
        reasoning: row.reasoning,
        confidence: wireLookup(Confidence.values, row.confidence)!,
        missingInfo: _decodeStrings(row.missingInfo),
        owner: row.owner,
        dueDate: row.dueDate,
        entityIds: _decodeStrings(row.entityIds),
        userAction: wireLookup(UserAction.values, row.userAction)!,
        // drift 的 dateTime 存的是 unix 秒，讀回來是本地時間 ——
        // 同一個瞬間，但契約的 created_at 要帶時區，所以一律收成 UTC。
        // 代價是毫秒會被截掉，一條結論的時戳不需要那個精度。
        createdAt: row.createdAt.toUtc(),
        source: row.source,
      );

  List<String> _decodeStrings(String raw) =>
      (jsonDecode(raw) as List).cast<String>();
}
