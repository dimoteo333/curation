import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('첫 실행 시 온보딩을 보여주고 완료 후 홈으로 진입한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
        ],
        child: const CuratorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('당신의 일상,\nAI가 큐레이션합니다'), findsOneWidget);
    expect(find.byKey(const Key('onboardingSkipButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingSkipButton')));
    await tester.pumpAndSettle();

    expect(find.text('시작하기 전에\n기록을 불러오세요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('completeOnboardingButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openSettingsButton')), findsOneWidget);
    expect(preferences.getBool('app.onboarding_completed'), isTrue);
  });
}

class _FakeOnDeviceLlmBridge implements OnDeviceLlmBridge {
  const _FakeOnDeviceLlmBridge();

  @override
  Future<List<double>> embed(String text) async => <double>[0.1, 0.2, 0.3];

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    return '테스트 응답';
  }

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    return const OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'template-fallback',
      message: '테스트 폴백',
      platform: 'flutter-test',
      llmModelConfigured: false,
      embedderModelConfigured: false,
      llmModelAvailable: false,
      embedderModelAvailable: false,
      fallbackActive: true,
    );
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async => prepare();
}
