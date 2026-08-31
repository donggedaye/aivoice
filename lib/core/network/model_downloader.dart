import 'dart:io';

import 'package:dio/dio.dart';

import '../storage/model_manager.dart';

class DownloadProgress {
  const DownloadProgress({
    required this.fileName,
    required this.received,
    required this.total,
  });

  final String fileName;
  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);
}

/// 模型下載：斷點續傳、逐檔 SHA-256 校驗、校驗失敗就刪掉重來。
///
/// 下載中的資料寫進 `<檔名>.part`，只有大小與雜湊都對才改名成正式檔案。
/// 中途失敗或使用者離開，`.part` 會留著，下次從那個位元組續傳。
class ModelDownloader {
  ModelDownloader(this._dio, this._manager);

  final Dio _dio;
  final ModelManager _manager;

  CancelToken? _cancelToken;

  void cancel() => _cancelToken?.cancel('cancelled');

  Future<void> downloadAll(void Function(DownloadProgress) onProgress) async {
    final total = kSenseVoiceTotalBytes;
    var completed = 0;

    for (final model in kSenseVoiceFiles) {
      await _downloadOne(
        model,
        (received) => onProgress(
          DownloadProgress(
            fileName: model.name,
            received: completed + received,
            total: total,
          ),
        ),
      );
      completed += model.bytes;
    }
  }

  Future<void> _downloadOne(
    ModelFile model,
    void Function(int received) onReceived,
  ) async {
    final target = File(await _manager.pathOf(model));
    if (target.existsSync() && await target.length() == model.bytes) {
      onReceived(model.bytes);
      return;
    }

    final part = File('${target.path}.part');
    var offset = part.existsSync() ? await part.length() : 0;
    if (offset > model.bytes) {
      // 暫存檔比目標還大，只可能是壞的。
      await part.delete();
      offset = 0;
    }

    if (offset < model.bytes) {
      await _fetch(model, part, offset, onReceived);
    }

    if (!part.existsSync() || await part.length() != model.bytes) {
      if (part.existsSync()) await part.delete();
      throw StateError('${model.name} 下載大小不符，已清除，請重試');
    }

    await part.rename(target.path);

    if (!await _manager.verify(model)) {
      await _manager.remove(model);
      throw StateError('${model.name} SHA-256 校驗未通過，已刪除，請重新下載');
    }
  }

  Future<void> _fetch(
    ModelFile model,
    File part,
    int offset,
    void Function(int received) onReceived,
  ) async {
    _cancelToken = CancelToken();

    final response = await _dio.get<ResponseBody>(
      model.url,
      cancelToken: _cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        headers: offset > 0 ? {'range': 'bytes=$offset-'} : null,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // 206 才代表伺服器接受了續傳；回 200 就是從頭給，暫存檔必須重寫。
    final resumed = response.statusCode == 206 && offset > 0;
    final sink = part.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    var received = resumed ? offset : 0;

    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onReceived(received);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }
}
