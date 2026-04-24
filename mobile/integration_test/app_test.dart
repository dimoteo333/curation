import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('빈 상태에서도 홈 화면을 정상 렌더링한다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
    });

    await pumpIntegrationTestApp(tester, preferences: preferences);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeBrandLogo')), findsOneWidget);
    expect(find.byKey(const Key('homeEmptyStateCard')), findsOneWidget);
    expect(find.text('아직 가져온 기록이 없습니다'), findsOneWidget);
  });

  testWidgets('데모 레코드로 질문 응답을 렌더링한다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
      'local_records.demo_data_loaded': true,
    });

    await pumpIntegrationTestApp(
      tester,
      preferences: preferences,
      localRecords: testSeedRecords,
      curationRepository: FakeCurationRepository(testCuratedResponse),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeBrandLogo')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('todayAskCard')));
    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '오늘 무기력한 이유',
    );
    expect(find.byKey(const Key('submitQuestionButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await pumpUntilFound(
      tester,
      find.byKey(const Key('supportingRecordsSection')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supportingRecordsSection')), findsOneWidget);
    expect(find.text('답변이 도움이 되었나요?'), findsOneWidget);
    expect(find.text(testPrimarySupportingRecord.title), findsOneWidget);
  });
}
