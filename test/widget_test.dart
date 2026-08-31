import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/main.dart';

void main() {
  testWidgets('Record page boots with a zeroed timer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AivoiceApp()));

    expect(find.text('錄音'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('開始錄音'), findsOneWidget);
  });
}
