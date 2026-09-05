import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/errors.dart';
import '../../domain/entities/playback.dart';
import '../../domain/entities/transcript.dart';

class TranscriptState {
  const TranscriptState({
    this.recordingId,
    this.transcribing = false,
    this.transcript,
    this.error,
    this.playingSegmentId,
  });

  /// 目前這份轉寫屬於哪一次錄音。換了錄音就要重轉。
  final String? recordingId;

  final bool transcribing;
  final Transcript? transcript;
  final String? error;

  /// 正在播放的段落 id。沒有在播就是 null。
  final String? playingSegmentId;

  TranscriptState copyWith({
    String? recordingId,
    bool? transcribing,
    Transcript? transcript,
    String? error,
    String? playingSegmentId,
    bool clearError = false,
    bool clearTranscript = false,
    bool clearPlaying = false,
  }) {
    return TranscriptState(
      recordingId: recordingId ?? this.recordingId,
      transcribing: transcribing ?? this.transcribing,
      transcript: clearTranscript ? null : (transcript ?? this.transcript),
      error: clearError ? null : (error ?? this.error),
      playingSegmentId:
          clearPlaying ? null : (playingSegmentId ?? this.playingSegmentId),
    );
  }
}

final transcriptControllerProvider =
    NotifierProvider<TranscriptController, TranscriptState>(
  TranscriptController.new,
);

class TranscriptController extends Notifier<TranscriptState> {
  StreamSubscription<PlaybackEvent>? _playback;

  @override
  TranscriptState build() {
    ref.onDispose(() => _playback?.cancel());
    return const TranscriptState();
  }

  /// 進到轉寫頁時呼叫。同一次錄音已經有結果或轉過就不重跑，換了錄音才重轉。
  Future<void> ensureTranscribed() async {
    if (state.transcribing) return;
    final recording = ref.read(currentRecordingProvider);
    final sameRecording = recording != null && recording.id == state.recordingId;
    if (sameRecording && (state.transcript != null || state.error != null)) {
      return;
    }
    await transcribe();
  }

  Future<void> transcribe() async {
    final recording = ref.read(currentRecordingProvider);
    if (recording == null) {
      state = state.copyWith(error: '沒有可以轉寫的錄音');
      return;
    }
    if (state.transcribing) return;

    await stop();
    state = state.copyWith(
      recordingId: recording.id,
      transcribing: true,
      clearError: true,
      clearTranscript: true,
    );
    try {
      final transcript = await ref.read(transcribeLocallyProvider)(recording);
      state = state.copyWith(transcribing: false, transcript: transcript);
    } catch (e) {
      state = state.copyWith(transcribing: false, error: describeError(e));
    }
  }

  /// 點同一段就停，點別段就換過去播。
  Future<void> toggle(TranscriptSegment segment) async {
    if (state.playingSegmentId == segment.id) {
      await stop();
      return;
    }

    final recording = ref.read(currentRecordingProvider);
    if (recording == null) {
      state = state.copyWith(error: '找不到這次錄音的音訊');
      return;
    }

    final player = ref.read(playSegmentProvider);
    _playback ??= player.events().listen(_onPlaybackEvent);

    state = state.copyWith(playingSegmentId: segment.id, clearError: true);
    try {
      await player(recording, segment);
    } catch (e) {
      state = state.copyWith(error: describeError(e), clearPlaying: true);
    }
  }

  /// 停止播放，並清掉切出來的暫存檔。自然播完也走這裡。
  Future<void> stop() async {
    state = state.copyWith(clearPlaying: true);
    try {
      await ref.read(playSegmentProvider).stop();
    } catch (_) {
      // 停不下來就算了，下一次播放會先 release 舊的播放器。
    }
  }

  void _onPlaybackEvent(PlaybackEvent event) {
    switch (event) {
      case PlaybackCompleted():
        unawaited(stop());
      case PlaybackFailed(:final message):
        unawaited(stop());
        state = state.copyWith(error: message);
    }
  }
}
