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

    final id = _nextJobId++;
    final completer = Completer<List<RawSegment>>();
    _pending[id] = completer;
    _commands!.send({'type': 'transcribe', 'id': id, 'pcm': pcmPath});
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
    responses.listen((message) => _onMessage(message, ready));

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
      _starting = null;
      responses.close();
      _responses = null;
      rethrow;
    }
  }

  void _onMessage(Object? message, Completer<SendPort> ready) {
    if (message is SendPort) {
      if (!ready.isCompleted) ready.complete(message);
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

    // isolate 掛掉（onError 送 List，onExit 送 null），把等待中的請求全部收掉。
    _failAll(message is List ? '${message.first}' : '辨識 isolate 結束了');
  }

  void _failAll(String reason) {
    _commands = null;
    _starting = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(StateError(reason));
    }
    _pending.clear();
  }

  void dispose() {
    _commands?.send({'type': 'stop'});
    _responses?.close();
    _responses = null;
    _commands = null;
    _starting = null;
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _pending.clear();
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
List<Map<String, Object>> _splitAndRecognize(
  sherpa.OfflineRecognizer recognizer,
  sherpa.VoiceActivityDetector vad,
  String pcmPath,
) {
  final samples = _readSamples(File(pcmPath));
  final segments = <Map<String, Object>>[];

  vad.reset();
  var offset = 0;
  while (offset + _vadWindow <= samples.length) {
    vad.acceptWaveform(
      Float32List.sublistView(samples, offset, offset + _vadWindow),
    );
    offset += _vadWindow;
    _drain(recognizer, vad, segments);
  }
  vad.flush();
  _drain(recognizer, vad, segments);

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

Float32List _readSamples(File file) {
  final bytes = file.readAsBytesSync();
  final view = ByteData.sublistView(bytes);
  final count = bytes.length ~/ 2;
  final samples = Float32List(count);
  for (var i = 0; i < count; i++) {
    samples[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return samples;
}
