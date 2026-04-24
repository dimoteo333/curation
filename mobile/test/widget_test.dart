import 'dart:convert';

import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_pending_import.dart';
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
    expect(find.text('모든 처리가 기기 안에서 이루어집니다'), findsOneWidget);
    expect(find.text('서버를 통해 처리됩니다'), findsNothing);
  });

  testWidgets('홈 화면 privacy 배너는 remote 모드에서 서버 처리 문구를 표시한다', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      bridge: const FakeOnDeviceLlmBridge(
        runtimeStatus: OnDeviceRuntimeStatus(
          llmReady: true,
          embedderReady: true,
          runtime: 'remote-harness',
          message: '원격 하네스를 사용 중입니다.',
          platform: 'flutter-test',
          llmModelConfigured: false,
          embedderModelConfigured: false,
          llmModelAvailable: false,
          embedderModelAvailable: false,
          fallbackActive: false,
        ),
      ),
      mockPreferences: const <String, Object>{
        'app.onboarding_completed': true,
        'app.runtime_mode': 'remote',
      },
    );

    expect(find.text('서버를 통해 처리됩니다'), findsOneWidget);
    expect(find.text('모든 처리가 기기 안에서 이루어집니다'), findsNothing);
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

  testWidgets('홈 화면 최근 대화 카드에 런타임 경로 배지를 표시한다', (WidgetTester tester) async {
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
        ),
      ),
      mockPreferences: <String, Object>{
        'app.onboarding_completed': true,
        'app.recent_conversations': jsonEncode(<Map<String, String>>[
          <String, String>{
            'question': '어제도 같은 질문을 했나요?',
            'preview': '비슷한 피로 흐름이 반복됐습니다.',
            'asked_at': '2026-04-24T09:30:00.000',
            'runtime_path': 'onDeviceNative',
            'runtime_badge_label': '네이티브',
          },
        ]),
      },
    );

    expect(find.text('어제도 같은 질문을 했나요?'), findsOneWidget);
    expect(find.text('네이티브'), findsOneWidget);
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
  Map<String, Object> mockPreferences = const <String, Object>{
    'app.onboarding_completed': true,
  },
}) async {
  SharedPreferences.setMockInitialValues(mockPreferences);
  final preferences = await SharedPreferences.getInstance();
  final pendingImportService = FakePendingSharedImportService();
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
        pendingSharedImportBridgeProvider.overrideWithValue(
          pendingImportService.bridge,
        ),
        pendingSharedImportServiceProvider.overrideWithValue(
          pendingImportService,
        ),
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
