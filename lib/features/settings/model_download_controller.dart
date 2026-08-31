import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/platform/asr_channel.dart';

class ModelDownloadState {
  const ModelDownloadState({
    this.downloading = false,
    this.received = 0,
    this.total = 0,
    this.fileName,
    this.error,
    this.askMobileConfirm = false,
    this.done = false,
  });

  final bool downloading;
  final int received;
  final int total;
  final String? fileName;
  final String? error;

  /// 目前在行動網路上，等使用者決定要不要繼續。
  final bool askMobileConfirm;
  final bool done;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);

  /// 位元組收完但流程還沒結束，代表正在算 SHA-256。
  bool get verifying => downloading && total > 0 && received >= total;

  ModelDownloadState copyWith({
    bool? downloading,
    int? received,
    int? total,
    String? fileName,
    String? error,
    bool? askMobileConfirm,
    bool? done,
    bool clearError = false,
  }) {
    return ModelDownloadState(
      downloading: downloading ?? this.downloading,
      received: received ?? this.received,
      total: total ?? this.total,
      fileName: fileName ?? this.fileName,
      error: clearError ? null : (error ?? this.error),
      askMobileConfirm: askMobileConfirm ?? this.askMobileConfirm,
      done: done ?? this.done,
    );
  }
}

final modelDownloadControllerProvider =
    NotifierProvider<ModelDownloadController, ModelDownloadState>(
      ModelDownloadController.new,
    );

class ModelDownloadController extends Notifier<ModelDownloadState> {
  @override
  ModelDownloadState build() => const ModelDownloadState();

  /// [allowMobile] 由使用者在提示裡明確按下才會是 true。
  Future<void> start({bool allowMobile = false}) async {
    if (state.downloading) return;
    state = state.copyWith(
      downloading: true,
      askMobileConfirm: false,
      done: false,
      clearError: true,
    );

    try {
      final network = await ref.read(asrChannelProvider).networkType();
      if (network == NetworkType.none) {
        state = state.copyWith(downloading: false, error: '沒有網路連線');
        return;
      }
      if (network == NetworkType.mobile && !allowMobile) {
        state = state.copyWith(downloading: false, askMobileConfirm: true);
        return;
      }

      await ref.read(modelDownloaderProvider).downloadAll((progress) {
        state = state.copyWith(
          received: progress.received,
          total: progress.total,
          fileName: progress.fileName,
        );
      });

      state = state.copyWith(downloading: false, done: true);
      ref.invalidate(modelReadyProvider);
    } catch (e) {
      // 已下載的位元組留在 .part，再按一次就從中斷處續傳。
      state = state.copyWith(downloading: false, error: e.toString());
    }
  }

  void dismissMobilePrompt() =>
      state = state.copyWith(askMobileConfirm: false);
}
