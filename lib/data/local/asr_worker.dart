import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

const int _sampleRate = 16000;

/// silero-vad 一次吃 512 個取樣（32 ms）。
const int _vadWindow = 512;

/// 一段語音最長 15 秒。太長會超出 SenseVoice 的訓練長度，
/// 也會讓 9/5 的「點段落回放」定位變粗。
const double _maxSpeechSeconds = 15.0;

/// 每次從 PCM 檔讀 1 秒。整檔載入會在長錄音上炸掉記憶體：
/// PCM 加上轉出來的 float 是 6 bytes/取樣，一小時就要 345 MB。
const int _readSamples = _sampleRate;

class RawSegment {
  const RawSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final int startMs;
  final int endMs;
  final String text;
}

/// 常駐辨識 isolate。
///
/// 模型有 228 MB，每次轉寫都重載根本達不到「10 分鐘音訊 60 秒內轉完」。
/// 這裡把 recognizer 與 VAD 都留在一個長命 isolate 裡，只在第一次轉寫時載入；
/// 主 isolate 只負責送檔案路徑、收分段結果，畫面不會被 FFI 呼叫凍住。
class AsrWorker {
  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _responses;
  Future<void>? _starting;
  Completer<SendPort>? _ready;

  final Map<int, Completer<List<RawSegment>>> _pending = {};
  int _nextJobId = 0;

  Future<List<RawSegment>> transcribe({
    required String modelPath,
    required String tokensPath,
    required String vadPath,
    required String pcmPath,
  }) async {
    await _ensureStarted(
      modelPath: modelPath,
      tokensPath: tokensPath,
      vadPath: vadPath,
    );

    // isolate 可能在我們 await 期間就死了，不能直接 `_commands!`。
    final commands = _commands;
    if (commands == null) {
      throw StateError('辨識 isolate 尚未就緒');
    }

    final id = _nextJobId++;
    final completer = Completer<List<RawSegment>>();
    _pending[id] = completer;
    commands.send({'type': 'transcribe', 'id': id, 'pcm': pcmPath});
    return completer.future;
  }

  Future<void> _ensureStarted({
    required String modelPath,
    required String tokensPath,
    required String vadPath,
  }) {
    if (_commands != null) return Future.value();
    return _starting ??= _start(
      modelPath: modelPath,
      tokensPath: tokensPath,
      vadPath: vadPath,
    );
  }

  Future<void> _start({
    required String modelPath,
    required String tokensPath,
    required String vadPath,
  }) async {
    final responses = ReceivePort();
    _responses = responses;

    final ready = Completer<SendPort>();
    _ready = ready;
    responses.listen(_onMessage);

    try {
      _isolate = await Isolate.spawn(
        _asrWorkerMain,
        [responses.sendPort, modelPath, tokensPath, vadPath],
        onError: responses.sendPort,
        onExit: responses.sendPort,
        errorsAreFatal: true,
      );
      _commands = await ready.future;
    } catch (e) {
      _teardown();
      rethrow;
    }
  }

  void _onMessage(Object? message) {
    if (message is SendPort) {
      final ready = _ready;
      if (ready != null && !ready.isCompleted) ready.complete(message);
      return;
    }

    if (message is Map) {
      final id = message['id'] as int?;
      final completer = id == null ? null : _pending.remove(id);
      if (completer == null) return;

      final error = message['error'] as String?;
      if (error != null) {
        completer.completeError(StateError(error));
        return;
      }
      final raw = (message['segments'] as List).cast<Map>();
      completer.complete([
        for (final segment in raw)
          RawSegment(
            startMs: segment['startMs'] as int,
            endMs: segment['endMs'] as int,
            text: segment['text'] as String,
          ),
      ]);
      return;
    }

    // isolate 掛了：onError 送 List（錯誤訊息 + 堆疊），onExit 送 null。
    _failAll(message is List && message.isNotEmpty
        ? '${message.first}'
        : '辨識 isolate 結束了');
  }

  /// 讓所有等待中的呼叫拿到錯誤，並且把死掉的 isolate 徹底收乾淨。
  ///
  /// 包含還沒完成的 [_ready] —— 模型檔壞掉時 recognizer 或 VAD 會在 worker 啟動
  /// 階段就拋例外，那時 SendPort 根本還沒送出來，漏掉它會讓 `transcribe()` 永遠
  /// 卡在 await，UI 停在「辨識中」而且沒有任何錯誤訊息。
  void _failAll(String reason) {
    final error = StateError(reason);

    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.completeError(error);

    final pending = List.of(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    _teardown();
  }

  void _teardown() {
    _responses?.close();
    _responses = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commands = null;
    _starting = null;
    _ready = null;
  }

  void dispose() {
    final commands = _commands;
    final isolate = _isolate;

    // worker 收到 stop 才會呼叫 free()。sherpa-onnx 的原生記憶體是掛在整個
    // 行程上的，isolate 被殺掉並不會還回去，所以不能直接 kill。
    commands?.send({'type': 'stop'});

    _responses?.close();
    _responses = null;
    _commands = null;
    _starting = null;
    _ready = null;
    _isolate = null;
    _pending.clear();

    if (isolate != null) {
      if (commands == null) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        // 正常情況 worker 自己關掉 port 就結束了；卡住才強制收掉。
        Timer(const Duration(seconds: 5), () {
          isolate.kill(priority: Isolate.immediate);
        });
      }
    }
  }
}

// --------------------------------------------------------------- worker side

void _asrWorkerMain(List<Object> init) {
  final setup = init[0] as SendPort;
  final modelPath = init[1] as String;
  final tokensPath = init[2] as String;
  final vadPath = init[3] as String;

  sherpa.initBindings();

  final recognizer = sherpa.OfflineRecognizer(
    sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        senseVoice: sherpa.OfflineSenseVoiceModelConfig(
          model: modelPath,
          useInverseTextNormalization: true,
        ),
        tokens: tokensPath,
        modelType: 'sense_voice',
        numThreads: 2,
        debug: false,
      ),
    ),
  );

  final vad = sherpa.VoiceActivityDetector(
    config: sherpa.VadModelConfig(
      sileroVad: sherpa.SileroVadModelConfig(
        model: vadPath,
        windowSize: _vadWindow,
        maxSpeechDuration: _maxSpeechSeconds,
      ),
      sampleRate: _sampleRate,
      numThreads: 1,
      debug: false,
    ),
    bufferSizeInSeconds: 30,
  );

  final commands = ReceivePort();
  setup.send(commands.sendPort);

  commands.listen((message) {
    final job = message as Map;
    if (job['type'] == 'stop') {
      vad.free();
      recognizer.free();
      commands.close();
      return;
    }

    final id = job['id'] as int;
    try {
      setup.send({
        'id': id,
        'segments': _splitAndRecognize(recognizer, vad, job['pcm'] as String),
      });
    } catch (e) {
      setup.send({'id': id, 'error': e.toString()});
    }
  });
}

/// VAD 切段，逐段送進辨識器。靜音不會進辨識，這是能達到 10 倍速的主因。
///
/// PCM 邊讀邊餵，不整檔載入 —— 20 分鐘的錄音光是 float 陣列就 76 MB，
/// 再疊上常駐的模型，中階機會直接 OOM。
List<Map<String, Object>> _splitAndRecognize(
  sherpa.OfflineRecognizer recognizer,
  sherpa.VoiceActivityDetector vad,
  String pcmPath,
) {
  final segments = <Map<String, Object>>[];
  final file = File(pcmPath).openSync();

  vad.reset();
  try {
    final buffer = Uint8List(_readSamples * 2);
    final window = Float32List(_vadWindow);
    var filled = 0;

    while (true) {
      final read = file.readIntoSync(buffer);
      if (read <= 0) break;

      final view = ByteData.sublistView(buffer, 0, read);
      final count = read ~/ 2;
      for (var i = 0; i < count; i++) {
        window[filled++] = view.getInt16(i * 2, Endian.little) / 32768.0;
        if (filled == _vadWindow) {
          // acceptWaveform 會把取樣複製到原生記憶體，緩衝區可以重複使用。
          vad.acceptWaveform(window);
          filled = 0;
          _drain(recognizer, vad, segments);
        }
      }
    }

    vad.flush();
    _drain(recognizer, vad, segments);
  } finally {
    file.closeSync();
  }

  return segments;
}

void _drain(
  sherpa.OfflineRecognizer recognizer,
  sherpa.VoiceActivityDetector vad,
  List<Map<String, Object>> out,
) {
  while (!vad.isEmpty()) {
    final segment = vad.front();
    final stream = recognizer.createStream();
    String text;
    try {
      stream.acceptWaveform(
        samples: segment.samples,
        sampleRate: _sampleRate,
      );
      recognizer.decode(stream);
      text = recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }

    if (text.isNotEmpty) {
      out.add({
        'startMs': segment.start * 1000 ~/ _sampleRate,
        'endMs': (segment.start + segment.samples.length) * 1000 ~/ _sampleRate,
        'text': text,
      });
    }
    vad.pop();
  }
}
