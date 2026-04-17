import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_curation_repository.dart';

void main() {
  testWidgets('홈 화면은 에디토리얼 레이아웃에서 응답을 렌더링한다', (WidgetTester tester) async {
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

    expect(find.text('당신의 하루를 읽습니다'), findsOneWidget);
    expect(find.text('최근 인사이트'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('submitQuestionButton')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pumpAndSettle();

    expect(find.text('최근 인사이트'), findsWidgets);
    expect(find.text('질문  나 요즘 왜 이렇게 무기력하지?'), findsOneWidget);
    expect(find.textContaining('테스트 환경에서도 질문 흐름이 화면에 표시됩니다.'), findsOneWidget);
    expect(find.text('테스트용 요약입니다.'), findsOneWidget);
    expect(find.byKey(const Key('responseSection')), findsOneWidget);
  });

  testWidgets('응답이 없을 때도 에디토리얼 플레이스홀더를 보여준다', (WidgetTester tester) async {
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

    expect(find.text('"야근이 많았던 3월,\n당신의 무기력함은\n당연한 것이었습니다"'), findsOneWidget);
    expect(find.text('── 3개월 전 야근 회고'), findsOneWidget);
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

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('사용 방식'), findsOneWidget);
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

    expect(find.byKey(const Key('questionTextField')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
