import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('온보딩 화면이 정상 렌더링된다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(
      const <String, Object>{},
    );

    await pumpIntegrationTestApp(tester, preferences: preferences);
    await tester.pumpAndSettle();

    expect(find.text('큐레이터 시작하기'), findsOneWidget);
    // 건너뛰기 버튼으로 마지막 페이지(3/3)로 이동해야 체크박스가 렌더됨
    await tester.tap(find.byKey(const Key('onboardingSkipButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('onboardingLoadDemoDataCheckbox')),
      findsOneWidget,
    );
  });

  testWidgets('홈 화면이 정상 렌더링된다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
      'local_records.demo_data_loaded': true,
    });

    await pumpIntegrationTestApp(
      tester,
      preferences: preferences,
      localRecords: testSeedRecords,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeBrandLogo')), findsOneWidget);
    expect(find.byKey(const Key('todayAskCard')), findsOneWidget);
  });

  testWidgets('질문 화면이 정상 렌더링된다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
      'local_records.demo_data_loaded': true,
    });

    await pumpIntegrationTestApp(
      tester,
      preferences: preferences,
      localRecords: testSeedRecords,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();
    await dismissActiveInput(tester);

    expect(find.byKey(const Key('questionTextField')), findsOneWidget);
    expect(find.byKey(const Key('submitQuestionButton')), findsOneWidget);
  });

  testWidgets('응답 화면이 정상 렌더링된다', (WidgetTester tester) async {
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

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '오늘 무기력한 이유',
    );
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await pumpUntilFound(
      tester,
      find.byKey(const Key('supportingRecordsSection')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supportingRecordsSection')), findsOneWidget);
    expect(find.text('답변이 도움이 되었나요?'), findsOneWidget);
  });

  testWidgets('타임라인 화면이 정상 렌더링된다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
      'local_records.demo_data_loaded': true,
    });

    await pumpIntegrationTestApp(
      tester,
      preferences: preferences,
      localRecords: testSeedRecords,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('navDock-timeline')));
    await tester.pumpAndSettle();

    expect(find.text('타임라인'), findsWidgets);
    expect(find.text(testSeedRecords.first.title), findsOneWidget);
  });

  testWidgets('설정 화면이 정상 렌더링된다', (WidgetTester tester) async {
    final preferences = await integrationTestPreferences(<String, Object>{
      'app.onboarding_completed': true,
      'local_records.demo_data_loaded': true,
    });

    await pumpIntegrationTestApp(
      tester,
      preferences: preferences,
      localRecords: testSeedRecords,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsWidgets);
    expect(find.text('사용 방식'), findsOneWidget);
  });
}
