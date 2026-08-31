import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'features/record/record_page.dart';

void main() {
  runApp(const ProviderScope(child: AivoiceApp()));
}

class AivoiceApp extends StatelessWidget {
  const AivoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 工作副駕駛',
      theme: buildAppTheme(),
      home: const RecordPage(),
    );
  }
}
