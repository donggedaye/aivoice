import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settingsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('儲存空間', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              state.loading
                  ? '計算中…'
                  : '錄音佔用 ${_formatBytes(state.usedBytes)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '錄音不會自動刪除，只有你自己刪才會消失。'
              '音訊只留在這支手機裡，不進雲端備份，也不會跟著換機轉移。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('清除資料', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '語音模型（229 MB）不會被刪掉，刪了要重新下載。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.busy ? null : _confirmDeleteAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('刪除全部錄音'),
            ),
            if (state.busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (state.message != null) ...[
              const SizedBox(height: 12),
              Text(state.message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除全部錄音？'),
        content: const Text(
          '這支手機上的錄音會全部消失，沒有備份也沒有雲端，救不回來。\n\n'
          '語音模型會留著。',
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
            child: const Text('全部刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(settingsControllerProvider.notifier).deleteAllRecordings();
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
