// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:entrenos/app.dart';

void main() {
  testWidgets('Core app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EntreNosApp()));

    // Verify that the title is present (or any initial screen widget)
    // Since it starts with splash screen, strictly checking for '0' won't work.
    // We just want to ensure it builds without crashing.
    expect(find.byType(EntreNosApp), findsOneWidget);
  });
}
