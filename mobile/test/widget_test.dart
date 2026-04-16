import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_curation_repository.dart';

void main() {
  testWidgets('홈 화면은 런타임 상태와 응답 경로를 함께 렌더링한다', (WidgetTester tester) async {
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

    expect(find.text('네이티브 LLM 사용 가능'), findsOneWidget);
    expect(find.text('온디바이스 네이티브'), findsOneWidget);
    expect(find.text('LLM: 네이티브'), findsOneWidget);
    expect(find.text('임베딩: 네이티브'), findsOneWidget);

    await tester.tap(find.byKey(const Key('runtimeDeveloperPanel')));
    await tester.pumpAndSettle();

    expect(find.text('LLM 모델'), findsOneWidget);
    expect(find.text('준비 완료'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('submitQuestionButton')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pumpAndSettle();

    expect(find.text('최근 기록에서 반복된 흐름'), findsOneWidget);
    expect(find.text('테스트 환경에서도 질문 흐름이 화면에 표시됩니다.'), findsOneWidget);
    expect(find.text('이번 응답: 템플릿 폴백 사용 중'), findsOneWidget);
    expect(find.byKey(const Key('responseSection')), findsOneWidget);
  });

  testWidgets('런타임이 준비되지 않으면 폴백 상태를 배지로 노출한다', (WidgetTester tester) async {
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

    expect(find.text('템플릿 폴백 사용 중'), findsOneWidget);
    expect(find.textContaining('의미 임베딩 폴백'), findsWidgets);
    expect(find.textContaining('검색은 한국어 의미 임베딩'), findsWidgets);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required OnDeviceLlmBridge bridge,
}) async {
  tester.view.physicalSize = const Size(1400, 2800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        curationRepositoryProvider.overrideWithValue(FakeCurationRepository()),
        onDeviceLlmBridgeProvider.overrideWithValue(bridge),
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
