import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/core/utils/adts.dart';

/// 造一個 ADTS 幀。內容用 [fill] 填，方便驗證取出來的是哪一幀。
Uint8List frame(int fill, {int payload = 5}) {
  final length = 7 + payload;
  final bytes = Uint8List(length);
  bytes[0] = 0xFF;
  bytes[1] = 0xF1;
  bytes[2] = 0x50; // AAC-LC、16 kHz、單聲道，這裡不影響長度解析
  bytes[3] = 0x40 | ((length >> 11) & 0x03);
  bytes[4] = (length >> 3) & 0xFF;
  bytes[5] = ((length & 0x07) << 5) | 0x1F;
  bytes[6] = 0xFC;
  for (var i = 7; i < length; i++) {
    bytes[i] = fill;
  }
  return bytes;
}

Uint8List concat(Iterable<Uint8List> parts) {
  final builder = BytesBuilder();
  for (final part in parts) {
    builder.add(part);
  }
  return builder.takeBytes();
}

/// 取出每幀的填充位元組，用來確認拿到的是第幾幀。
List<int> fillsOf(Uint8List bytes) {
  final fills = <int>[];
  scanAdts(bytes, onFrame: (offset, _) => fills.add(bytes[offset + 7]));
  return fills;
}

void main() {
  test('scanAdts walks every frame of a clean stream', () {
    final bytes = concat([frame(1), frame(2), frame(3)]);
    final scan = scanAdts(bytes);

    expect(scan.frames, 3);
    expect(scan.clean, isTrue);
  });

  test('scanAdts reports a truncated tail', () {
    final full = concat([frame(1), frame(2)]);
    final scan = scanAdts(Uint8List.sublistView(full, 0, full.length - 3));

    expect(scan.frames, 1);
    expect(scan.clean, isFalse);
  });

  test('one frame is 64 ms at 16 kHz', () {
    expect(adtsFramesToDuration(1), const Duration(milliseconds: 64));
    expect(adtsFramesToDuration(1000).inMilliseconds, 64000);
  });

  test('collector takes the frames covering the range', () {
    // 幀 0 = 0–64 ms、幀 1 = 64–128 ms、幀 2 = 128–192 ms……
    final collector = AdtsRangeCollector(startMs: 128, endMs: 200);
    collector.add(concat([for (var i = 0; i < 5; i++) frame(i)]));

    // 200 ms 落在幀 3 之內，所以幀 3 也要收進來。
    expect(fillsOf(collector.build()), [2, 3]);
  });

  test('collector keeps frame numbering across chunks', () {
    final collector = AdtsRangeCollector(startMs: 128, endMs: 320);
    // 每片 2 幀：第一片是幀 0–1，第二片是幀 2–3，第三片是幀 4–5。
    collector.add(concat([frame(0), frame(1)]));
    expect(collector.isDone, isFalse);
    collector.add(concat([frame(2), frame(3)]));
    collector.add(concat([frame(4), frame(5)]));

    expect(fillsOf(collector.build()), [2, 3, 4]);
    expect(collector.isDone, isTrue);
  });

  test('collector stops asking for more chunks once the range is filled', () {
    final collector = AdtsRangeCollector(startMs: 0, endMs: 64);
    collector.add(concat([frame(0), frame(1)]));

    expect(collector.isDone, isTrue);
    // 已經滿了就不再收，後面的分片不必讀進記憶體。
    collector.add(concat([frame(9)]));
    expect(fillsOf(collector.build()), [0]);
  });

  test('collector returns nothing when the range is past the audio', () {
    final collector = AdtsRangeCollector(startMs: 10000, endMs: 11000);
    collector.add(concat([frame(0), frame(1)]));

    expect(collector.build(), isEmpty);
  });
}
