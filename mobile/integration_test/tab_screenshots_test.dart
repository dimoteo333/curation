import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
            localDataInitializationProvider.overrideWith((ref) async {}),
            localDataStatsProvider.overrideWith(
              (ref) => const LocalDataStats(
                recordCount: 4,
                databaseSizeBytes: 1024,
                sourceCounts: <String, int>{'file': 4},
              ),
            ),
            localLifeRecordsProvider.overrideWith((ref) async => const []),
          ],
          child: const CuratorApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('capture all tabs', (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.text('큐레이터'), findsWidgets);
    });
  });
}
