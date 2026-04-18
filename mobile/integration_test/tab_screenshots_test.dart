import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:curator_mobile/app.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tab Screenshots', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'app.onboarding_completed': true,
        'app.demo_data_loaded': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.CuratorApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('capture all tabs', (WidgetTester tester) async {
      await pumpApp(tester);

      // Tab 0: Home - already visible
      // Find bottom nav items
      final navItems = find.byType(GestureDetector);
      
      // Just pump and settle for each state
      // This test mainly exists to verify the app renders without crashing
      expect(find.text('큐레이터'), findsWidgets);
    });
  });
}
