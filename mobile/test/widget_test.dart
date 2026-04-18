import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_curation_repository.dart';
import 'test_support.dart';

void main() {
  testWidgets('홈 화면은 새 대시보드 레이아웃을 렌더링한다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: true,
          embedderReady: true,
          runtime: 'native-ready',
          message: '네이티브 LLM과 임베더가 모두 준비되었습니다.',
          platform: 'android',
          llmModelConfigured: true,
          embedderModelConfigured: true,
          llmModelAvailable: true,
          embedderModelAvailable: true,
          fallbackActive: false,
          lastPrepareDurationMs: 480,
        ),
      ),
    );

    expect(find.text('큐레이터'), findsOneWidget);
    expect(find.textContaining('안녕하세요, 지원 님.'), findsOneWidget);
    expect(find.text('오늘의 질문'), findsOneWidget);
    expect(find.text('추천 질문'), findsOneWidget);
    expect(find.text('최근 대화'), findsOneWidget);
    expect(find.text('연결된 기록'), findsOneWidget);
    expect(find.byKey(const Key('openSettingsButton')), findsOneWidget);
    expect(find.byKey(const Key('todayAskCard')), findsOneWidget);

    expect(find.text('타임라인'), findsOneWidget);
  });

  testWidgets('오늘의 질문 카드를 누르면 질문 화면으로 이동한다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();

    expect(find.text('질문하기'), findsOneWidget);
    expect(find.byKey(const Key('questionTextField')), findsOneWidget);
  });

  testWidgets('질문 제출 후 답변 화면으로 이동한다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '나 요즘 왜 이렇게 무기력하지?',
    );
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 2800));

    expect(find.text('참고한 기록'), findsOneWidget);
    expect(find.text('답변이 도움이 되었나요?'), findsOneWidget);
  });

  testWidgets('답변의 참고 기록을 누르면 메모리 시트가 열린다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '나 요즘 왜 이렇게 무기력하지?',
    );
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 2800));

    await tester.tap(find.text('테스트 기록').first);
    await tester.pumpAndSettle();

    expect(find.text('원문 열기'), findsOneWidget);
    expect(find.text('서울 · 합정동'), findsOneWidget);
  });

  testWidgets('홈 화면에서 설정 화면으로 이동할 수 있다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();

    expect(find.text('사용 방식'), findsOneWidget);
    expect(find.text('사용 방식'), findsOneWidget);
  });

  testWidgets('하단 탭에서 타임라인으로 이동하고 기록을 열 수 있다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.text('타임라인'));
    await tester.pumpAndSettle();

    expect(find.text('타임라인'), findsWidgets);
    expect(find.text('더 오래 전'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('혼자 카페에 앉아 초안을 정리한 오후'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('혼자 카페에 앉아 초안을 정리한 오후'));
    await tester.pumpAndSettle();

    expect(find.text('원문 열기'), findsOneWidget);
  });

  testWidgets('작은 화면에서도 홈 화면이 overflow 없이 렌더링된다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
      physicalSize: const Size(640, 1136),
    );

    expect(find.byKey(const Key('todayAskCard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('질문이 너무 길면 제출 전에 오류를 보여 준다', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: false,
          embedderReady: false,
          runtime: 'template-fallback',
          message: '모델 경로가 없어 템플릿 폴백을 사용합니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('todayAskCard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('questionTextField')),
      '길다' * 200,
    );
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pumpAndSettle();

    expect(find.text('입력은 최대 280자까지 가능합니다.'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required OnDeviceLlmBridge bridge,
  Size physicalSize = const Size(1400, 2800),
}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{
    'app.onboarding_completed': true,
  });
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        curationRepositoryProvider.overrideWithValue(FakeCurationRepository()),
        onDeviceLlmBridgeProvider.overrideWithValue(bridge),
        databaseEncryptionProvider.overrideWithValue(
          createTestDatabaseEncryption(),
        ),
        localDataInitializationProvider.overrideWith((ref) async {}),
        localDataStatsProvider.overrideWith(
          (ref) => const LocalDataStats(
            recordCount: 14,
            databaseSizeBytes: 4096,
            sourceCounts: <String, int>{'diary': 6, 'calendar': 4, 'file': 4},
          ),
        ),
        localLifeRecordsProvider.overrideWith((ref) async => seededLifeRecords),
      ],
      child: const CuratorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class FakeOnDeviceLlmBridge implements OnDeviceLlmBridge {
  const FakeOnDeviceLlmBridge({required this.runtimeStatus});

  final OnDeviceRuntimeStatus runtimeStatus;

  @override
  Future<List<double>> embed(String text) async {
    return <double>[0.1, 0.2, 0.3];
  }

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    return '테스트 네이티브 응답';
  }

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    return runtimeStatus;
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async {
    return runtimeStatus;
  }
}
