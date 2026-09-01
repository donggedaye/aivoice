import 'dart:io';

import '../platform/asr_channel.dart';

class ModelFile {
  const ModelFile({
    required this.name,
    required this.url,
    required this.sha256,
    required this.bytes,
  });

  final String name;
  final String url;
  final String sha256;
  final int bytes;
}

const String _senseVoiceBase =
    'https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main';

/// SenseVoice-small int8。
///
/// 只取需要的兩個檔案，不下載官方那包 1.05 GB 的 tar.bz2（裡面還有 fp32 模型）。
///
/// 兩個雜湊都是把檔案抓下來自己算的。不要拿 Hugging Face 的 ETag 當 SHA-256 ——
/// 那個 repo 走 Xet 儲存，ETag 是 Xet 雜湊，跟檔案內容的 SHA-256 不一樣。
const List<ModelFile> kSenseVoiceFiles = [
  ModelFile(
    name: 'model.int8.onnx',
    url: '$_senseVoiceBase/model.int8.onnx',
    sha256: 'c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51',
    bytes: 239233841,
  ),
  ModelFile(
    name: 'tokens.txt',
    url: '$_senseVoiceBase/tokens.txt',
    sha256: 'f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc',
    bytes: 315894,
  ),
  // silero-vad，切段用。相對 228 MB 幾乎不佔額外時間。
  ModelFile(
    name: 'silero_vad.onnx',
    url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/'
        'asr-models/silero_vad.onnx',
    sha256: '9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6',
    bytes: 643854,
  ),
];

/// 三個模型檔在 [kSenseVoiceFiles] 裡的位置。
const int kModelIndex = 0;
const int kTokensIndex = 1;
const int kVadIndex = 2;

int get kSenseVoiceTotalBytes =>
    kSenseVoiceFiles.fold<int>(0, (sum, file) => sum + file.bytes);

class ModelManager {
  const ModelManager(this._channel);

  final AsrChannel _channel;

  static const String _subdirectory = 'sense-voice';

  Future<Directory> directory() async {
    final base = await _channel.modelsDir();
    final dir = Directory('$base${Platform.pathSeparator}$_subdirectory');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<String> pathOf(ModelFile file) async =>
      '${(await directory()).path}${Platform.pathSeparator}${file.name}';

  /// 啟動時的快速檢查：只看存在與大小。
  /// 完整雜湊要掃 228 MB，不適合每次開 App 都跑一遍。
  Future<bool> isReady() async {
    for (final model in kSenseVoiceFiles) {
      final file = File(await pathOf(model));
      if (!file.existsSync()) return false;
      if (await file.length() != model.bytes) return false;
    }
    return true;
  }

  /// 完整 SHA-256 比對。下載完成後跑一次，或使用者要求時。
  Future<bool> verify(ModelFile model) async {
    final path = await pathOf(model);
    if (!File(path).existsSync()) return false;
    final actual = await _channel.sha256(path);
    return actual.toLowerCase() == model.sha256.toLowerCase();
  }

  /// 把某個模型檔與它的續傳暫存一起刪掉，讓下一次從頭下載。
  Future<void> remove(ModelFile model) async {
    final path = await pathOf(model);
    final file = File(path);
    if (file.existsSync()) await file.delete();
    final part = File('$path.part');
    if (part.existsSync()) await part.delete();
  }
}
