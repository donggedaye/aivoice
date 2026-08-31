import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/model_downloader.dart';
import '../core/platform/asr_channel.dart';
import '../core/platform/recording_channel.dart';
import '../core/storage/model_manager.dart';
import '../data/repositories_impl/recording_repository_impl.dart';
import '../data/repositories_impl/transcription_repository_impl.dart';
import '../domain/repositories/recording_repository.dart';
import '../domain/repositories/transcription_repository.dart';
import '../domain/usecases/record_audio.dart';
import '../domain/usecases/transcribe_locally.dart';

final recordingChannelProvider = Provider<RecordingChannel>(
  (ref) => const RecordingChannel(),
);

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

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(ref.watch(recordingChannelProvider)),
);

final transcriptionRepositoryProvider = Provider<TranscriptionRepository>(
  (ref) => TranscriptionRepositoryImpl(
    ref.watch(asrChannelProvider),
    ref.watch(modelManagerProvider),
    ref.watch(recordingRepositoryProvider),
  ),
);

final recordAudioProvider = Provider<RecordAudio>(
  (ref) => RecordAudio(ref.watch(recordingRepositoryProvider)),
);

final transcribeLocallyProvider = Provider<TranscribeLocally>(
  (ref) => TranscribeLocally(ref.watch(transcriptionRepositoryProvider)),
);
