import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/model_manager.dart';
import 'model_download_controller.dart';

class ModelDownloadPage extends ConsumerWidget {
  const ModelDownloadPage({super.key, required this.onSkip});

  /// 使用者選擇稍後再下載。錄音本來就不需要模型，不擋他進 App。
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelDownloadControllerProvider);
    final controller = ref.read(modelDownloadControllerProvider.notifier);
    final sizeText = _formatBytes(kSenseVoiceTotalBytes);

    return Scaffold(
      appBar: AppBar(title: const Text('下載語音模型')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('轉寫在手機上完成', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '語音模型需要下載 $sizeText，只下載這一次。'
                '之後轉寫全程離線，錄音與音訊不會離開手機。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              if (state.askMobileConfirm)
                _MobilePrompt(
                  sizeText: sizeText,
                  onProceed: () => controller.start(allowMobile: true),
                  onLater: () {
                    controller.dismissMobilePrompt();
                    onSkip();
                  },
                ),

              if (state.error != null) ...[
                _ErrorBox(message: state.error!),
                const SizedBox(height: 16),
              ],

              if (state.downloading) ...[
                LinearProgressIndicator(
                  value: state.verifying ? null : state.fraction,
                ),
                const SizedBox(height: 8),
                Text(
                  state.verifying
                      ? '校驗中…'
                      : '${(state.fraction * 100).toStringAsFixed(1)}%  '
                            '${_formatBytes(state.received)} / ${_formatBytes(state.total)}'
                            '${state.fileName == null ? '' : '  ·  ${state.fileName}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
              ],

              if (!state.downloading && !state.askMobileConfirm) ...[
                FilledButton(
                  onPressed: controller.start,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(state.error == null ? '開始下載' : '重試'),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onSkip, child: const Text('稍後再下載')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobilePrompt extends StatelessWidget {
  const _MobilePrompt({
    required this.sizeText,
    required this.onProceed,
    required this.onLater,
  });

  final String sizeText;
  final VoidCallback onProceed;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('目前是行動網路', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('這次要下載 $sizeText，會用掉行動數據。建議連上 Wi-Fi 再下載。'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onProceed, child: const Text('仍要下載')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onLater, child: const Text('稍後')),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          const SizedBox(height: 4),
          Text(
            '已下載的部分會保留，重試會從中斷處續傳。',
            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(0)} MB';
}
