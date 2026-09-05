import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/storage/recording_store.dart';

void main() {
  late Directory root;
  late String base;
  const store = RecordingStore();

  setUp(() {
    root = Directory.systemTemp.createTempSync('aivoice_store_test');
    base = '${root.path}/recordings';
    Directory(base).createSync(recursive: true);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void makeRecording(String id, {int chunks = 1, int bytes = 10}) {
    final dir = Directory('$base/$id')..createSync(recursive: true);
    for (var i = 0; i < chunks; i++) {
      File('${dir.path}/chunk_${i.toString().padLeft(4, '0')}.aac')
          .writeAsBytesSync(List<int>.filled(bytes, 0));
    }
  }

  test('lists recordings newest first', () {
    makeRecording('1788612012710');
    makeRecording('1788612862011');
    makeRecording('1788234722806');

    expect(store.listIds(base), [
      '1788612862011',
      '1788612012710',
      '1788234722806',
    ]);
  });

  test('ignores anything that is not a recording directory', () {
    makeRecording('1788612012710');
    Directory('$base/models').createSync();
    File('$base/stray.txt').writeAsStringSync('x');

    expect(store.listIds(base), ['1788612012710']);
  });

  test('returns nothing when the directory has never been created', () {
    expect(store.listIds('$base/missing'), isEmpty);
  });

  test('deletes one recording and leaves the others alone', () async {
    makeRecording('1788612012710');
    makeRecording('1788612862011');

    await store.deleteOne(base, '1788612012710');

    expect(store.listIds(base), ['1788612862011']);
    expect(Directory('$base/1788612012710').existsSync(), isFalse);
  });

  test('deleting a recording twice is not an error', () async {
    makeRecording('1788612012710');

    await store.deleteOne(base, '1788612012710');
    await store.deleteOne(base, '1788612012710');

    expect(store.listIds(base), isEmpty);
  });

  test('refuses an id that is not a recording id', () {
    // 擋掉 `../models` 這種東西，刪除只能走 id。
    expect(
      () => store.deleteOne(base, '../models'),
      throwsArgumentError,
    );
    expect(() => store.deleteOne(base, 'models'), throwsArgumentError);
  });

  test('deletes everything and reports how many', () async {
    makeRecording('1788612012710');
    makeRecording('1788612862011');
    Directory('$base/models').createSync();

    expect(await store.deleteAll(base), 2);
    expect(store.listIds(base), isEmpty);
    // 不是錄音的東西留著。
    expect(Directory('$base/models').existsSync(), isTrue);
  });

  test('adds up the bytes of every chunk', () async {
    makeRecording('1788612012710', chunks: 2, bytes: 100);
    makeRecording('1788612862011', chunks: 3, bytes: 50);

    expect(await store.totalBytes(base), 2 * 100 + 3 * 50);
  });
}
