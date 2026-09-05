import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/recording.dart';
import 'record_controller.dart';
import 'widgets/waveform_view.dart';

class RecordPage extends ConsumerWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordControllerProvider);
    final controller = ref.read(recordControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('錄音')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null)
                _ErrorBanner(
                  message: state.error!,
                  showSettings: state.permissionBlocked,
                  onOpenSettings: controller.openAppSettings,
                ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(state.elapsed),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              Text(
                state.isRecording ? '錄音中 · 已寫入 ${state.chunkCount} 片' : '尚未開始',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              WaveformView(levels: state.levels, capacity: kWaveformLength),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: state.busy ? null : controller.toggle,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor:
                      state.isRecording ? Theme.of(context).colorScheme.error : null,
                ),
                icon: Icon(state.isRecording ? Icons.stop : Icons.mic),
                label: Text(state.isRecording ? '停止' : '開始錄音'),
              ),
              if (state.summary != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => context.push('/transcript'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.text_fields),
                  label: const Text('轉寫這段錄音'),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  summary: state.summary!,
                  busy: state.busy,
                  mergedPath: state.mergedPath,
                  mergedBytes: state.mergedBytes,
                  onMerge: controller.merge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.showSettings,
    required this.onOpenSettings,
  });

  final String message;
  final bool showSettings;
  final VoidCallback onOpenSettings;

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
          if (showSettings) ...[
            const SizedBox(height: 8),
            Text(
              '你選擇了不再詢問，請到系統設定手動開啟麥克風權限。',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onOpenSettings,
              child: const Text('前往設定'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.busy,
    required this.mergedPath,
    required this.mergedBytes,
    required this.onMerge,
  });

  final RecordingSummary summary;
  final bool busy;
  final String? mergedPath;
  final int? mergedBytes;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本次錄音', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _Row(label: '分片數量', value: '${summary.chunkCount} 片'),
            _Row(label: '總時長', value: _formatDuration(summary.duration)),
            _Row(label: '總大小', value: _formatBytes(summary.totalBytes)),
            _Row(
              label: '分片完整性',
              value: summary.hasCorruptChunk ? '有分片被截斷' : '全部正常',
            ),
            const SizedBox(height: 8),
            Text(
              '時長由分片內的 ADTS 幀數量算出，不是服務回報的計時器。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('逐片明細'),
              children: [
                for (final chunk in summary.chunks)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(chunk.path.split('/').last),
                    subtitle: Text(
                      '${_formatDuration(chunk.duration)} · '
                      '${chunk.frames} 幀 · ${_formatBytes(chunk.bytes)}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onMerge,
              icon: const Icon(Icons.merge),
              label: const Text('把分片拼成完整檔案'),
            ),
            if (mergedPath != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                '已輸出：$mergedPath',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '大小 ${_formatBytes(mergedBytes ?? 0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
