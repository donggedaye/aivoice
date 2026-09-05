import 'dart:typed_data';

/// AAC-LC 每幀固定 1024 個取樣。16 kHz 之下正好是 64 ms 一幀。
const int kAdtsSamplesPerFrame = 1024;

/// 錄音的取樣率。分片、解碼、切段都用這個數字。
const int kRecordingSampleRate = 16000;

/// 走訪一段 ADTS 位元組的結果。
class AdtsScan {
  const AdtsScan({required this.frames, required this.clean});

  final int frames;

  /// 任一幀的同步字對不上、或長度超出檔尾，代表這個檔案尾端被截斷。
  final bool clean;
}

/// 走訪 ADTS 幀。每走到一幀就呼叫 [onFrame]，帶著該幀在 [bytes] 裡的位置與長度。
/// 任何一幀不合法就停下來，並回報檔案不乾淨。
AdtsScan scanAdts(
  Uint8List bytes, {
  void Function(int offset, int length)? onFrame,
}) {
  var offset = 0;
  var frames = 0;
  while (offset + 7 <= bytes.length) {
    if (bytes[offset] != 0xFF || (bytes[offset + 1] & 0xF0) != 0xF0) {
      return AdtsScan(frames: frames, clean: false);
    }
    final length = ((bytes[offset + 3] & 0x03) << 11) |
        (bytes[offset + 4] << 3) |
        ((bytes[offset + 5] & 0xE0) >> 5);
    if (length < 7 || offset + length > bytes.length) {
      return AdtsScan(frames: frames, clean: false);
    }
    onFrame?.call(offset, length);
    offset += length;
    frames++;
  }
  return AdtsScan(frames: frames, clean: offset == bytes.length);
}

Duration adtsFramesToDuration(
  int frames, {
  int sampleRate = kRecordingSampleRate,
}) =>
    Duration(
      microseconds: frames * kAdtsSamplesPerFrame * 1000000 ~/ sampleRate,
    );

/// 從依序餵入的分片裡，取出涵蓋 `[startMs, endMs)` 的 ADTS 幀。
///
/// 幀在所有分片之間連續編號，所以段落跨分片邊界不用特別處理。
/// 取出來的位元組本身就是合法的 ADTS 檔，可以直接交給播放器。
class AdtsRangeCollector {
  AdtsRangeCollector({
    required int startMs,
    required int endMs,
    int sampleRate = kRecordingSampleRate,
  })  : assert(startMs >= 0),
        assert(endMs > startMs),
        _startFrame = _floorFrame(startMs, sampleRate),
        _endFrame = _ceilFrame(endMs, sampleRate);

  final int _startFrame;
  final int _endFrame;
  final BytesBuilder _output = BytesBuilder(copy: false);

  /// 已經走過的幀數，跨分片累加。
  int _seen = 0;

  /// 想要的幀都拿到了。呼叫端可以不用再讀後面的分片。
  bool get isDone => _seen >= _endFrame;

  void add(Uint8List part) {
    if (isDone) return;
    scanAdts(
      part,
      onFrame: (offset, length) {
        final index = _seen++;
        if (index >= _startFrame && index < _endFrame) {
          _output.add(Uint8List.sublistView(part, offset, offset + length));
        }
      },
    );
  }

  /// 拿不到任何幀時回傳空的位元組，由呼叫端決定怎麼回報。
  Uint8List build() => _output.takeBytes();

  static int _floorFrame(int ms, int sampleRate) =>
      ms * sampleRate ~/ (1000 * kAdtsSamplesPerFrame);

  static int _ceilFrame(int ms, int sampleRate) {
    final divisor = 1000 * kAdtsSamplesPerFrame;
    return (ms * sampleRate + divisor - 1) ~/ divisor;
  }
}
