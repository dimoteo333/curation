import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('원격 하네스 응답과 런타임 배지를 렌더링한다', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setBool('app.onboarding_completed', true);
    await preferences.setString('app.runtime_mode', 'remote');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          localDataInitializationProvider.overrideWith((ref) async {}),
        ],
        child: const CuratorApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '요즘 계속 무기력하고 지쳐요',
    );
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await _pumpUntilFound(tester, find.byKey(const Key('responseSection')));

    expect(find.byKey(const Key('responseSection')), findsOneWidget);
    expect(find.text('서버 응답'), findsOneWidget);
    expect(find.text('최근 기록에서 반복된 흐름'), findsOneWidget);
    expect(find.textContaining('관련 기록'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for remote harness response.');
}
