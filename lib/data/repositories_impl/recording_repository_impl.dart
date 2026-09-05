import 'dart:io';

import '../../core/platform/recording_channel.dart';
import '../../core/utils/adts.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  const RecordingRepositoryImpl(this._channel);

  final RecordingChannel _channel;

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
