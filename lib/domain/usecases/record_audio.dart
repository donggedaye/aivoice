import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

/// 錄音的進入點。UI 只透過這個類別操作錄音，不直接碰平台通道。
class RecordAudio {
  const RecordAudio(this._repository);

  final RecordingRepository _repository;

  Future<PermissionStatus> permissionStatus() => _repository.permissionStatus();

  Future<PermissionStatus> requestPermissions() =>
      _repository.requestPermissions();

  Future<void> openAppSettings() => _repository.openAppSettings();

  Future<Recording> start() => _repository.start();

  Future<void> stop() => _repository.stop();

  Future<bool> isRecording() => _repository.isRecording();

  Stream<RecordingEvent> events() => _repository.events();

  Future<RecordingSummary> summarize(Recording recording) =>
      _repository.summarize(recording);

  Future<String> merge(Recording recording) => _repository.mergeChunks(recording);
}
