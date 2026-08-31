import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/main.dart';

void main() {
  testWidgets('App boots and shows the title', (WidgetTester tester) async {
    await tester.pumpWidget(const AivoiceApp());

    expect(find.text('AI 工作副駕駛'), findsOneWidget);
  });
}
