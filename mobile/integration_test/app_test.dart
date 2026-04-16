import 'package:curator_mobile/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 백엔드에 질문을 보내고 결과를 렌더링한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CuratorApp()));

    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await _pumpUntilFound(tester, find.byKey(const Key('responseSection')));

    expect(find.text('최근 기록에서 반복된 흐름'), findsOneWidget);
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
