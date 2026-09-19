import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/model_downloader.dart';
import '../core/platform/asr_channel.dart';
import '../core/platform/playback_channel.dart';
import '../core/platform/recording_channel.dart';
import '../core/storage/app_database.dart';
import '../core/storage/model_manager.dart';
import '../core/storage/recording_store.dart';
import '../data/local/asr_worker.dart';
import '../data/repositories_impl/playback_repository_impl.dart';
import '../data/repositories_impl/recording_repository_impl.dart';
import '../data/repositories_impl/transcript_repository_impl.dart';
import '../data/repositories_impl/transcription_repository_impl.dart';
import '../domain/entities/recording.dart';
import '../domain/repositories/playback_repository.dart';
import '../domain/repositories/recording_repository.dart';
import '../domain/repositories/transcript_repository.dart';
import '../domain/repositories/transcription_repository.dart';
import '../domain/usecases/manage_recordings.dart';
import '../domain/usecases/play_segment.dart';
import '../domain/usecases/record_audio.dart';
import '../domain/usecases/transcribe_locally.dart';

final recordingChannelProvider = Provider<RecordingChannel>(
  (ref) => const RecordingChannel(),
);

final playbackChannelProvider = Provider<PlaybackChannel>(
  (ref) => const PlaybackChannel(),
);

/// 剛錄完、正要處理的那一次錄音。錄音頁寫入，轉寫頁讀取。
/// 9/6 有錄音列表之後，這裡會改成從列表選出來的那一筆。
final currentRecordingProvider = StateProvider<Recording?>((ref) => null);

final asrChannelProvider = Provider<AsrChannel>((ref) => const AsrChannel());

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      // 模型有 228 MB，串流讀取不能套整體逾時，只限制單次接收間隔。
      receiveTimeout: const Duration(minutes: 5),
    ),
  ),
);

final modelManagerProvider = Provider<ModelManager>(
  (ref) => ModelManager(ref.watch(asrChannelProvider)),
);

final modelDownloaderProvider = Provider<ModelDownloader>(
  (ref) => ModelDownloader(
    ref.watch(dioProvider),
    ref.watch(modelManagerProvider),
  ),
);

/// 模型檔是否齊備。下載完成後 invalidate 這個 provider 就會重新檢查。
final modelReadyProvider = FutureProvider<bool>(
  (ref) => ref.watch(modelManagerProvider).isReady(),
);

final recordingStoreProvider = Provider<RecordingStore>(
  (ref) => const RecordingStore(),
);

/// 本機資料庫。目前只存轉寫；9/23 之後 Claim 也進這裡。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transcriptRepositoryProvider = Provider<TranscriptRepository>(
  (ref) => TranscriptRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(
    ref.watch(recordingChannelProvider),
    ref.watch(recordingStoreProvider),
  ),
);

/// 常駐辨識 isolate。模型只載入一次，App 關閉時才釋放。
final asrWorkerProvider = Provider<AsrWorker>((ref) {
  final worker = AsrWorker();
  ref.onDispose(worker.dispose);
  return worker;
});

final transcriptionRepositoryProvider = Provider<TranscriptionRepository>(
  (ref) => TranscriptionRepositoryImpl(
    ref.watch(asrChannelProvider),
    ref.watch(modelManagerProvider),
    ref.watch(recordingRepositoryProvider),
    ref.watch(asrWorkerProvider),
  ),
);

final playbackRepositoryProvider = Provider<PlaybackRepository>(
  (ref) => PlaybackRepositoryImpl(
    ref.watch(playbackChannelProvider),
    ref.watch(recordingRepositoryProvider),
  ),
);

final recordAudioProvider = Provider<RecordAudio>(
  (ref) => RecordAudio(ref.watch(recordingRepositoryProvider)),
);

final playSegmentProvider = Provider<PlaySegment>(
  (ref) => PlaySegment(ref.watch(playbackRepositoryProvider)),
);

final manageRecordingsProvider = Provider<ManageRecordings>(
  (ref) => ManageRecordings(
    ref.watch(recordingRepositoryProvider),
    ref.watch(transcriptRepositoryProvider),
  ),
);

final transcribeLocallyProvider = Provider<TranscribeLocally>(
  (ref) => TranscribeLocally(
    ref.watch(transcriptionRepositoryProvider),
    ref.watch(transcriptRepositoryProvider),
  ),
);
