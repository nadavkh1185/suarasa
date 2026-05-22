import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suarasa/main.dart';

void main() {
  testWidgets('App initialization and splash screen check', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SuarasaApp(),
      ),
    );

    // Verify that Splash screen shows our app name and subtitle
    expect(find.text('Suarasa'), findsOneWidget);
    expect(find.text('Komunikasi Inklusif Tanpa Batas'), findsOneWidget);
  });
}
