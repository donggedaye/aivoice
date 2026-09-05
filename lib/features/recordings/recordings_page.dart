import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/recording.dart';
import 'recordings_controller.dart';

class RecordingsPage extends ConsumerStatefulWidget {
  const RecordingsPage({super.key});

  @override
  ConsumerState<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends ConsumerState<RecordingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recordingsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingsControllerProvider);
    final controller = ref.read(recordingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('錄音列表'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(child: _Body(state: state, onDelete: _confirmDelete)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(RecordingSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這筆錄音？'),
        content: Text(
          '${_formatDateTime(summary.startedAt)}，'
          '${_formatDuration(summary.duration)}。\n\n'
          '刪掉就沒了。錄音只存在這支手機裡，沒有備份也沒有雲端。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(recordingsControllerProvider.notifier).delete(summary);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.onDelete});

  final RecordingsState state;
  final Future<void> Function(RecordingSummary) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('還沒有錄音。', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final summary = state.items[index];
        final busy = state.busyId == summary.id;
        return ListTile(
          onTap: busy
              ? null
              : () {
                  // 轉寫頁讀的是這個 provider。
                  ref.read(currentRecordingProvider.notifier).state =
                      summary.recording;
                  context.push('/transcript');
                },
          title: Text(_formatDateTime(summary.startedAt)),
          subtitle: Text(
            '${_formatDuration(summary.duration)} · '
            '${_formatBytes(summary.totalBytes)} · '
            '${summary.chunkCount} 片'
            '${summary.hasCorruptChunk ? ' · 有分片被截斷' : ''}',
          ),
          trailing: IconButton(
            onPressed: busy ? null : () => onDelete(summary),
            icon: const Icon(Icons.delete_outline),
            tooltip: '刪除',
          ),
        );
      },
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

String _formatDateTime(DateTime time) =>
    '${time.year}/${_two(time.month)}/${_two(time.day)} '
    '${_two(time.hour)}:${_two(time.minute)}';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = _two(duration.inMinutes.remainder(60));
  final seconds = _two(duration.inSeconds.remainder(60));
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
