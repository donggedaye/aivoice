import 'dart:io';

import '../../core/platform/recording_channel.dart';
import '../../core/storage/recording_store.dart';
import '../../core/utils/adts.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  const RecordingRepositoryImpl(this._channel, this._store);

  final RecordingChannel _channel;
  final RecordingStore _store;

  static const String _chunkPrefix = 'chunk_';
  static const String _mergedName = 'full.aac';

  @override
  Future<PermissionStatus> permissionStatus() => _channel.permissionStatus();

  @override
  Future<PermissionStatus> requestPermissions() => _channel.requestPermissions();

  @override
  Future<void> openAppSettings() => _channel.openAppSettings();

  @override
  Future<Recording> start() => _channel.start();

  @override
  Future<void> stop() => _channel.stop();

  @override
  Future<bool> isRecording() => _channel.isRecording();

  @override
  Stream<RecordingEvent> events() => _channel.events();

  @override
  Future<RecordingSummary> summarize(Recording recording) async {
    final files = _chunkFiles(recording.dirPath);
    final chunks = <ChunkInfo>[];
    var totalFrames = 0;
    var totalBytes = 0;
    var corrupt = false;

    for (var i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final scan = scanAdts(bytes);
      corrupt = corrupt || !scan.clean;
      totalFrames += scan.frames;
      totalBytes += bytes.length;
      chunks.add(
        ChunkInfo(
          path: files[i].path,
          index: i,
          bytes: bytes.length,
          frames: scan.frames,
          duration: adtsFramesToDuration(scan.frames),
        ),
      );
    }

    return RecordingSummary(
      id: recording.id,
      dirPath: recording.dirPath,
      startedAt: recording.startedAt,
      chunks: chunks,
      duration: adtsFramesToDuration(totalFrames),
      totalBytes: totalBytes,
      hasCorruptChunk: corrupt,
    );
  }

  @override
  Future<String> mergeChunks(
    Recording recording, {
    String outputName = _mergedName,
  }) async {
    final files = _chunkFiles(recording.dirPath);
    if (files.isEmpty) {
      throw StateError('no chunks in ${recording.dirPath}');
    }

    final output = File('${recording.dirPath}${Platform.pathSeparator}$outputName');
    final sink = output.openWrite();
    try {
      // ADTS 每幀自帶長度，直接串接位元組就是合法檔案。
      for (final file in files) {
        sink.add(await file.readAsBytes());
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return output.path;
  }

  @override
  Future<List<String>> chunkPaths(Recording recording) async =>
      [for (final file in _chunkFiles(recording.dirPath)) file.path];

  @override
  Future<List<RecordingSummary>> list() async {
    final base = await _channel.recordingsDir();
    final summaries = <RecordingSummary>[];
    for (final id in _store.listIds(base)) {
      // 目錄名就是開始錄音的 epoch 毫秒，時長還是照分片的幀數實測。
      summaries.add(
        await summarize(
          Recording(
            id: id,
            dirPath: _store.pathOf(base, id),
            startedAt: DateTime.fromMillisecondsSinceEpoch(int.parse(id)),
          ),
        ),
      );
    }
    return summaries;
  }

  @override
  Future<void> delete(String id) async {
    await _refuseWhileRecording();
    await _store.deleteOne(await _channel.recordingsDir(), id);
  }

  @override
  Future<int> deleteAll() async {
    await _refuseWhileRecording();
    return _store.deleteAll(await _channel.recordingsDir());
  }

  @override
  Future<int> usedBytes() async =>
      _store.totalBytes(await _channel.recordingsDir());

  /// 錄音進行中就整個擋下來。分片還在寫，這時候刪目錄只會留下半個檔案。
  Future<void> _refuseWhileRecording() async {
    if (await isRecording()) {
      throw StateError('錄音進行中，請先停止再刪除');
    }
  }

  List<File> _chunkFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _basename(f.path).startsWith(_chunkPrefix))
        .toList();
    files.sort((a, b) => _basename(a.path).compareTo(_basename(b.path)));
    return files;
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
