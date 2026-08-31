import '../entities/recording.dart';
import '../entities/transcript.dart';

abstract class TranscriptionRepository {
  /// 端側轉寫一整段錄音。分片會先拼成單一檔案再解碼。
  Future<Transcript> transcribe(Recording recording);
}
