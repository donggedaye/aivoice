import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/errors.dart';
import '../../domain/entities/recording.dart';
import '../transcript/transcript_controller.dart';

class RecordingsState {
  const RecordingsState({
    this.loading = true,
    this.items = const [],
    this.error,
    this.busyId,
  });

  final bool loading;
  final List<RecordingSummary> items;
  final String? error;

  /// 正在刪除的那一筆。刪除期間整列不給再按。
  final String? busyId;

  RecordingsState copyWith({
    bool? loading,
    List<RecordingSummary>? items,
    String? error,
    String? busyId,
    bool clearError = false,
    bool clearBusy = false,
  }) {
    return RecordingsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      busyId: clearBusy ? null : (busyId ?? this.busyId),
    );
  }
}

final recordingsControllerProvider =
    NotifierProvider<RecordingsController, RecordingsState>(
  RecordingsController.new,
);

class RecordingsController extends Notifier<RecordingsState> {
  @override
  RecordingsState build() => const RecordingsState();

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await ref.read(manageRecordingsProvider).list();
      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(loading: false, error: describeError(e));
    }
  }

  Future<void> delete(RecordingSummary summary) async {
    if (state.busyId != null) return;
    state = state.copyWith(busyId: summary.id, clearError: true);
    try {
      await ref.read(manageRecordingsProvider).delete(summary.id);
      _forgetIfCurrent(summary.id);
      state = state.copyWith(
        items: [for (final item in state.items) if (item.id != summary.id) item],
        clearBusy: true,
      );
    } catch (e) {
      state = state.copyWith(error: describeError(e), clearBusy: true);
    }
  }

  /// 刪掉的如果正好是轉寫頁指著的那一筆，一併清掉，
  /// 免得使用者點進去對著不存在的檔案轉寫。
  void _forgetIfCurrent(String id) {
    if (ref.read(currentRecordingProvider)?.id != id) return;
    ref.read(currentRecordingProvider.notifier).state = null;
    ref.invalidate(transcriptControllerProvider);
  }
}
