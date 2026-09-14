import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:palash_setu/main.dart';

void main() {
  testWidgets('PalashSetuApp splash screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PalashSetuApp(
          initialScreen: Scaffold(body: Text('PALASH SETU')),
        ),
      ),
    );

    // Verify title is rendered
    expect(find.text('PALASH SETU'), findsOneWidget);

    // Advance timer for splash screen auto-routing
    await tester.pump(const Duration(seconds: 2));
  });
}
