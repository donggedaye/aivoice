import '../entities/recording.dart';
import '../entities/transcript.dart';

abstract class TranscriptionRepository {
  /// 端側轉寫一整段錄音。分片會先拼成單一檔案再解碼。
  Future<Transcript> transcribe(Recording recording);

  /// 是什麼轉出來的，例如 `asr:sensevoice-small@int8`。
  /// 存進資料庫，換模型之後才知道舊結果是誰轉的。
  String get source;
}
