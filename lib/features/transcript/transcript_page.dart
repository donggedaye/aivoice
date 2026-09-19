import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/entities/transcript.dart';
import 'transcript_controller.dart';

class TranscriptPage extends ConsumerStatefulWidget {
  const TranscriptPage({super.key});

  @override
  ConsumerState<TranscriptPage> createState() => _TranscriptPageState();
}

class _TranscriptPageState extends ConsumerState<TranscriptPage> {
  @override
  void initState() {
    super.initState();
    // 開頁就轉寫。已經有結果的話 ensureTranscribed 會直接返回。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(modelReadyProvider).value ?? false) {
        ref.read(transcriptControllerProvider.notifier).ensureTranscribed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transcriptControllerProvider);
    final controller = ref.read(transcriptControllerProvider.notifier);
    final ready = ref.watch(modelReadyProvider).value ?? false;
    final segments = state.transcript?.segments ?? const <TranscriptSegment>[];

    // 先攔下返回，把聲音停掉再真的離開。
    // 不能等到 dispose：那時 element 已經 defunct，改 state 會撞斷言。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        try {
          await controller.stop();
        } finally {
          if (context.mounted && context.canPop()) context.pop();
        }
      },
      child: _buildScaffold(context, state, controller, ready, segments),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    TranscriptState state,
    TranscriptController controller,
    bool ready,
    List<TranscriptSegment> segments,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('轉寫'),
        actions: [
          if (ready && !state.transcribing)
            IconButton(
              onPressed: () => controller.transcribe(force: true),
              icon: const Icon(Icons.refresh),
              tooltip: '重新轉寫',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.transcribing) const LinearProgressIndicator(),
            Expanded(
              child: _Body(
                ready: ready,
                state: state,
                segments: segments,
                onTapSegment: controller.toggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.ready,
    required this.state,
    required this.segments,
    required this.onTapSegment,
  });

  final bool ready;
  final TranscriptState state;
  final List<TranscriptSegment> segments;
  final void Function(TranscriptSegment) onTapSegment;

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const _Hint('語音模型尚未下載完成，無法轉寫。');
    }
    if (state.error != null) {
      return _Hint(state.error!, isError: true);
    }
    if (state.transcribing) {
      return const _Hint('辨識中，第一次要先載入模型，會慢一些。');
    }
    if (state.transcript == null) {
      return const _Hint('尚未轉寫。');
    }
    if (segments.isEmpty) {
      return const _Hint('（沒有辨識到語音）');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: segments.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              '${segments.length} 段 · 點一下播放該段',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final segment = segments[index - 1];
        return _SegmentTile(
          segment: segment,
          playing: state.playingSegmentId == segment.id,
          onTap: () => onTapSegment(segment),
        );
      },
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.segment,
    required this.playing,
    required this.onTap,
  });

  final TranscriptSegment segment;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 播放中的那一列用底色加藍色圖示標示。
    // primary 在 surfaceContainer 上是 4.77:1，符合 AA。
    return ListTile(
      onTap: onTap,
      tileColor: playing ? AppPalette.surfaceContainer : null,
      leading: Icon(
        playing ? Icons.stop_circle : Icons.play_circle_outline,
        color: playing ? scheme.primary : null,
      ),
      title: Text(
        '${_formatTime(segment.startMs)} – ${_formatTime(segment.endMs)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: playing ? scheme.primary : null,
            ),
      ),
      subtitle: Text(
        segment.text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message, {this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? scheme.error : null,
              ),
        ),
      ),
    );
  }
}

String _formatTime(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
