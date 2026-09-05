import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

/// 瀏覽與刪除已經錄好的音檔。
///
/// 錄音本身走 [RecordAudio]，這裡只管錄完之後的那些檔案。
class ManageRecordings {
  const ManageRecordings(this._repository);

  final RecordingRepository _repository;

  Future<List<RecordingSummary>> list() => _repository.list();

  Future<void> delete(String id) => _repository.delete(id);

  Future<int> deleteAll() => _repository.deleteAll();

  Future<int> usedBytes() => _repository.usedBytes();
}
