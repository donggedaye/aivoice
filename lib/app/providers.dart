import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform/recording_channel.dart';
import '../data/repositories_impl/recording_repository_impl.dart';
import '../domain/repositories/recording_repository.dart';
import '../domain/usecases/record_audio.dart';

final recordingChannelProvider = Provider<RecordingChannel>(
  (ref) => const RecordingChannel(),
);

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(ref.watch(recordingChannelProvider)),
);

final recordAudioProvider = Provider<RecordAudio>(
  (ref) => RecordAudio(ref.watch(recordingRepositoryProvider)),
);
