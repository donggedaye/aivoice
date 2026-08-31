import 'dart:io';
import 'dart:typed_data';

import '../../core/platform/recording_channel.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  const RecordingRepositoryImpl(this._channel);

  final RecordingChannel _channel;

  /// AAC-LC 每幀固定 1024 個取樣，取樣率 16 kHz，所以每幀 64 ms。
  static const int _samplesPerFrame = 1024;
  static const int _sampleRate = 16000;
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
      final scan = _scanAdts(bytes);
      corrupt = corrupt || !scan.clean;
      totalFrames += scan.frames;
      totalBytes += bytes.length;
      chunks.add(
        ChunkInfo(
          path: files[i].path,
          index: i,
          bytes: bytes.length,
          frames: scan.frames,
          duration: _framesToDuration(scan.frames),
        ),
      );
    }

    return RecordingSummary(
      id: recording.id,
      dirPath: recording.dirPath,
      chunks: chunks,
      duration: _framesToDuration(totalFrames),
      totalBytes: totalBytes,
      hasCorruptChunk: corrupt,
    );
  }

  @override
  Future<String> mergeChunks(Recording recording) async {
    final files = _chunkFiles(recording.dirPath);
    if (files.isEmpty) {
      throw StateError('no chunks in ${recording.dirPath}');
    }

    final output = File('${recording.dirPath}${Platform.pathSeparator}$_mergedName');
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

  Duration _framesToDuration(int frames) => Duration(
        microseconds: frames * _samplesPerFrame * 1000000 ~/ _sampleRate,
      );

  /// 走訪 ADTS 幀。任何一幀同步字對不上就停止，並回報檔案不乾淨。
  _AdtsScan _scanAdts(Uint8List bytes) {
    var offset = 0;
    var frames = 0;
    while (offset + 7 <= bytes.length) {
      if (bytes[offset] != 0xFF || (bytes[offset + 1] & 0xF0) != 0xF0) {
        return _AdtsScan(frames: frames, clean: false);
      }
      final length = ((bytes[offset + 3] & 0x03) << 11) |
          (bytes[offset + 4] << 3) |
          ((bytes[offset + 5] & 0xE0) >> 5);
      if (length < 7 || offset + length > bytes.length) {
        return _AdtsScan(frames: frames, clean: false);
      }
      offset += length;
      frames++;
    }
    return _AdtsScan(frames: frames, clean: offset == bytes.length);
  }
}

class _AdtsScan {
  const _AdtsScan({required this.frames, required this.clean});

  final int frames;
  final bool clean;
}
