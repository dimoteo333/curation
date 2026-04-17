import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('온디바이스 큐레이션 결과를 렌더링한다', (WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app.onboarding_completed', true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const CuratorApp(),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('submitQuestionButton')));
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await _pumpUntilFound(tester, find.byKey(const Key('responseSection')));

    expect(find.textContaining('최근 인사이트'), findsWidgets);
    expect(find.byKey(const Key('askAnotherQuestionButton')), findsOneWidget);
    expect(find.textContaining('무기력'), findsWidgets);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for integration result.');
}
