import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify the app renders without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
