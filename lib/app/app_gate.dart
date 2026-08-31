import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/record/record_page.dart';
import '../features/settings/model_download_page.dart';
import 'providers.dart';

/// 使用者選了「稍後再下載」。錄音不需要模型，所以不擋他進 App。
final modelGateSkippedProvider = StateProvider<bool>((ref) => false);

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(modelGateSkippedProvider)) return const RecordPage();

    return ref
        .watch(modelReadyProvider)
        .when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const RecordPage(),
          data: (ready) => ready
              ? const RecordPage()
              : ModelDownloadPage(
                  onSkip: () =>
                      ref.read(modelGateSkippedProvider.notifier).state = true,
                ),
        );
  }
}
