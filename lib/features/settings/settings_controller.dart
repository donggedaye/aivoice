import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/errors.dart';
import '../recordings/recordings_controller.dart';
import '../transcript/transcript_controller.dart';

class SettingsState {
  const SettingsState({
    this.loading = true,
    this.usedBytes = 0,
    this.busy = false,
    this.error,
    this.message,
  });

  final bool loading;
  final int usedBytes;
  final bool busy;
  final String? error;

  /// 剛做完的事，例如「已刪除 3 筆錄音」。
  final String? message;

  SettingsState copyWith({
    bool? loading,
    int? usedBytes,
    bool? busy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SettingsState(
      loading: loading ?? this.loading,
      usedBytes: usedBytes ?? this.usedBytes,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final bytes = await ref.read(manageRecordingsProvider).usedBytes();
      state = state.copyWith(loading: false, usedBytes: bytes);
    } catch (e) {
      state = state.copyWith(loading: false, error: describeError(e));
    }
  }

  /// 刪掉全部錄音。語音模型不動 —— 刪了要重新下載 229 MB。
  Future<void> deleteAllRecordings() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true, clearMessage: true);
    try {
      final removed = await ref.read(manageRecordingsProvider).deleteAll();
      _forgetEverything();
      state = state.copyWith(
        busy: false,
        usedBytes: await ref.read(manageRecordingsProvider).usedBytes(),
        message: '已刪除 $removed 筆錄音',
      );
    } catch (e) {
      state = state.copyWith(busy: false, error: describeError(e));
    }
  }

  /// 錄音沒了，指著它的轉寫與列表也要跟著清掉。
  void _forgetEverything() {
    ref.read(currentRecordingProvider.notifier).state = null;
    ref.invalidate(transcriptControllerProvider);
    ref.invalidate(recordingsControllerProvider);
  }
}
