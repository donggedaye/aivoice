import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/transcript.dart';

/// 波形保留的取樣點數量。服務每 100 ms 送一次，約等於最近 12 秒。
const int kWaveformLength = 120;

class RecordState {
  const RecordState({
    this.isRecording = false,
    this.busy = false,
    this.elapsed = Duration.zero,
    this.levels = const [],
    this.chunkCount = 0,
    this.current,
    this.summary,
    this.mergedPath,
    this.mergedBytes,
    this.error,
    this.permissionBlocked = false,
    this.transcribing = false,
    this.transcript,
  });

  final bool isRecording;
  final bool busy;
  final Duration elapsed;
  final List<double> levels;
  final int chunkCount;
  final Recording? current;
  final RecordingSummary? summary;
  final String? mergedPath;
  final int? mergedBytes;
  final String? error;

  /// 使用者選了「不再詢問」，只能引導去系統設定。
  final bool permissionBlocked;

  final bool transcribing;

  /// 9/3 暫時顯示在錄音頁，9/5 搬到轉寫頁。
  final Transcript? transcript;

  RecordState copyWith({
    bool? isRecording,
    bool? busy,
    Duration? elapsed,
    List<double>? levels,
    int? chunkCount,
    Recording? current,
    RecordingSummary? summary,
    String? mergedPath,
    int? mergedBytes,
    String? error,
    bool? permissionBlocked,
    bool? transcribing,
    Transcript? transcript,
    bool clearError = false,
    bool clearSummary = false,
    bool clearMerged = false,
    bool clearTranscript = false,
  }) {
    return RecordState(
      isRecording: isRecording ?? this.isRecording,
      busy: busy ?? this.busy,
      elapsed: elapsed ?? this.elapsed,
      levels: levels ?? this.levels,
      chunkCount: chunkCount ?? this.chunkCount,
      current: current ?? this.current,
      summary: clearSummary ? null : (summary ?? this.summary),
      mergedPath: clearMerged ? null : (mergedPath ?? this.mergedPath),
      mergedBytes: clearMerged ? null : (mergedBytes ?? this.mergedBytes),
      error: clearError ? null : (error ?? this.error),
      permissionBlocked: permissionBlocked ?? this.permissionBlocked,
      transcribing: transcribing ?? this.transcribing,
      transcript: clearTranscript ? null : (transcript ?? this.transcript),
    );
  }
}

final recordControllerProvider =
    NotifierProvider<RecordController, RecordState>(RecordController.new);

class RecordController extends Notifier<RecordState> {
  StreamSubscription<RecordingEvent>? _subscription;

  @override
  RecordState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const RecordState();
  }

  Future<void> toggle() async {
    if (state.busy) return;
    if (state.isRecording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    final recorder = ref.read(recordAudioProvider);
    state = state.copyWith(busy: true, clearError: true, permissionBlocked: false);

    try {
      // 每次都重新檢查。Android 11 的「僅本次允許」會在背景後被撤回。
      var status = await recorder.permissionStatus();
      if (!status.canRecord) {
        status = await recorder.requestPermissions();
      }
      if (!status.canRecord) {
        state = state.copyWith(
          busy: false,
          error: '需要麥克風權限才能錄音',
          permissionBlocked:
              status.microphone == PermissionState.permanentlyDenied,
        );
        return;
      }

      final recording = await recorder.start();
      _subscription?.cancel();
      _subscription = recorder.events().listen(_onEvent);

      state = state.copyWith(
        isRecording: true,
        busy: false,
        elapsed: Duration.zero,
        levels: const [],
        chunkCount: 0,
        current: recording,
        clearSummary: true,
        clearMerged: true,
        clearTranscript: true,
      );
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  Future<void> _stop() async {
    final recorder = ref.read(recordAudioProvider);
    state = state.copyWith(busy: true);

    try {
      await recorder.stop();
      await _waitUntilStopped(recorder.isRecording);
    } catch (e) {
      state = state.copyWith(isRecording: false, busy: false, error: e.toString());
      return;
    }
    await _finalize();
  }

  /// 服務要把最後一片寫完才會停。最多等 5 秒。
  Future<void> _waitUntilStopped(Future<bool> Function() isRecording) async {
    for (var i = 0; i < 50; i++) {
      if (!await isRecording()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 收尾：關掉事件訂閱、量測分片、離開錄音狀態。
  /// 使用者按停止與被系統打斷都走這裡，UI 才不會卡在「錄音中」。
  Future<void> _finalize({String? interruption}) async {
    state = state.copyWith(busy: true);
    await _subscription?.cancel();
    _subscription = null;

    final recording = state.current;
    try {
      final summary =
          recording == null ? null : await ref.read(recordAudioProvider).summarize(recording);
      state = state.copyWith(
        isRecording: false,
        busy: false,
        summary: summary,
        chunkCount: summary?.chunkCount ?? state.chunkCount,
        error: interruption,
        clearError: interruption == null,
      );
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        busy: false,
        error: interruption ?? e.toString(),
      );
    }
  }

  Future<void> merge() async {
    final recording = state.current;
    if (recording == null || state.busy) return;

    state = state.copyWith(busy: true, clearError: true, clearMerged: true);
    try {
      final path = await ref.read(recordAudioProvider).merge(recording);
      state = state.copyWith(
        busy: false,
        mergedPath: path,
        mergedBytes: await File(path).length(),
      );
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  Future<void> transcribe() async {
    final recording = state.current;
    if (recording == null || state.transcribing || state.busy) return;

    state = state.copyWith(
      transcribing: true,
      clearError: true,
      clearTranscript: true,
    );
    try {
      final transcript = await ref.read(transcribeLocallyProvider)(recording);
      state = state.copyWith(transcribing: false, transcript: transcript);
    } catch (e) {
      state = state.copyWith(transcribing: false, error: e.toString());
    }
  }

  Future<void> openAppSettings() =>
      ref.read(recordAudioProvider).openAppSettings();

  void _onEvent(RecordingEvent event) {
    switch (event) {
      case AmplitudeEvent(:final rms, :final elapsed):
        final levels = [...state.levels, rms];
        state = state.copyWith(
          elapsed: elapsed,
          levels: levels.length > kWaveformLength
              ? levels.sublist(levels.length - kWaveformLength)
              : levels,
        );
      case ChunkEvent(:final index):
        state = state.copyWith(chunkCount: index + 1);
      case RecordingErrorEvent(:final message):
        state = state.copyWith(error: message);
      case StoppedEvent(:final interrupted, :final message):
        // 使用者按的停止由 _stop() 收尾，這裡只處理沒人要求的結束。
        if (!state.isRecording || state.busy) return;
        unawaited(
          _finalize(
            interruption:
                interrupted ? '錄音被系統中斷${message == null ? '' : '：$message'}' : null,
          ),
        );
    }
  }
}
