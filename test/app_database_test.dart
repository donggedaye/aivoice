import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/storage/app_database.dart';
import 'package:aivoice/data/repositories_impl/transcript_repository_impl.dart';
import 'package:aivoice/domain/entities/transcript.dart';

const _source = 'asr:sensevoice-small@int8';

Transcript transcriptFor(String recordingId, int segmentCount) {
  return Transcript(
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
}

void main() {
  late AppDatabase db;
  late TranscriptRepositoryImpl store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = TranscriptRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('a recording that was never transcribed reads back as null', () async {
    expect(await store.load('1788612012710'), isNull);
  });

  test('segments survive a round trip in order', () async {
    await store.save(transcriptFor('1788612012710', 3), source: _source);

    final loaded = await store.load('1788612012710');

    expect(loaded, isNotNull);
    expect(loaded!.recordingId, '1788612012710');
    expect(loaded.segments.map((s) => s.id), [
      '1788612012710-0000',
      '1788612012710-0001',
      '1788612012710-0002',
    ]);
    expect(loaded.segments.first.startMs, 0);
    expect(loaded.segments.last.endMs, 14000);
    expect(loaded.segments[1].text, '第 1 段');
  });

  test('a transcript with no speech is not the same as never transcribed',
      () async {
    await store.save(transcriptFor('1788612012710', 0), source: _source);

    final loaded = await store.load('1788612012710');

    expect(loaded, isNotNull);
    expect(loaded!.segments, isEmpty);
  });

  test('saving again replaces the previous segments', () async {
    await store.save(transcriptFor('1788612012710', 5), source: _source);
    await store.save(transcriptFor('1788612012710', 2), source: _source);

    final loaded = await store.load('1788612012710');

    expect(loaded!.segments, hasLength(2));
  });

  test('deleting one recording leaves the others alone', () async {
    await store.save(transcriptFor('1788612012710', 2), source: _source);
    await store.save(transcriptFor('1788612862011', 3), source: _source);

    await store.delete('1788612012710');

    expect(await store.load('1788612012710'), isNull);
    expect((await store.load('1788612862011'))!.segments, hasLength(3));
  });

  test('deleting everything leaves no segments behind', () async {
    await store.save(transcriptFor('1788612012710', 2), source: _source);
    await store.save(transcriptFor('1788612862011', 3), source: _source);

    await store.deleteAll();

    expect(await store.load('1788612012710'), isNull);
    expect(await store.load('1788612862011'), isNull);
    expect(await db.select(db.transcriptSegments).get(), isEmpty);
  });
}
