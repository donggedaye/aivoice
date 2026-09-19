import 'package:drift/drift.dart';

import '../../core/storage/app_database.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/repositories/transcript_repository.dart';

class TranscriptRepositoryImpl implements TranscriptRepository {
  const TranscriptRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Transcript?> load(String recordingId) async {
    final header = await (_db.select(_db.transcripts)
          ..where((row) => row.recordingId.equals(recordingId)))
        .getSingleOrNull();
    if (header == null) return null;

    final rows = await (_db.select(_db.transcriptSegments)
          ..where((row) => row.recordingId.equals(recordingId))
          ..orderBy([(row) => OrderingTerm(expression: row.startMs)]))
        .get();

    return Transcript(
      recordingId: recordingId,
      segments: [
        for (final row in rows)
          TranscriptSegment(
            id: row.id,
            startMs: row.startMs,
            endMs: row.endMs,
            text: row.content,
            confidence: row.confidence,
          ),
      ],
    );
  }

  @override
  Future<void> save(Transcript transcript, {required String source}) {
    // 重轉要整份換掉，不能留下上一次的段落。
    return _db.transaction(() async {
      await delete(transcript.recordingId);
      await _db.into(_db.transcripts).insert(
            TranscriptsCompanion.insert(
              recordingId: transcript.recordingId,
              createdAt: DateTime.now(),
              source: source,
            ),
          );
      await _db.batch((batch) {
        batch.insertAll(_db.transcriptSegments, [
          for (final segment in transcript.segments)
            TranscriptSegmentsCompanion.insert(
              id: segment.id,
              recordingId: transcript.recordingId,
              startMs: segment.startMs,
              endMs: segment.endMs,
              content: segment.text,
              confidence: Value(segment.confidence),
            ),
        ]);
      });
    });
  }

  @override
  Future<void> delete(String recordingId) async {
    await (_db.delete(_db.transcriptSegments)
          ..where((row) => row.recordingId.equals(recordingId)))
        .go();
    await (_db.delete(_db.transcripts)
          ..where((row) => row.recordingId.equals(recordingId)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.transcriptSegments).go();
    await _db.delete(_db.transcripts).go();
  }
}
