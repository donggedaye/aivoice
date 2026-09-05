import 'package:go_router/go_router.dart';

import '../features/transcript/transcript_page.dart';
import 'app_gate.dart';

/// 路由表。`/` 由 AppGate 決定要顯示錄音頁還是模型下載頁。
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppGate(),
      routes: [
        GoRoute(
          path: 'transcript',
          builder: (context, state) => const TranscriptPage(),
        ),
      ],
    ),
  ],
);
