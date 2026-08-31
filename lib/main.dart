import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: AivoiceApp()));
}

class AivoiceApp extends StatelessWidget {
  const AivoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 工作副駕駛',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Scaffold(
        body: Center(child: Text('AI 工作副駕駛')),
      ),
    );
  }
}
