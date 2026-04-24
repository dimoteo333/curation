import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:curator_mobile/src/state/recent_conversations_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recordConversation stores runtime path metadata', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(recentConversationsProvider.notifier)
        .recordConversation(
          question: '요즘 왜 이렇게 지칠까?',
          response: const CuratedResponse(
            insightTitle: '테스트 응답',
            summary: '최근 기록이 피로 흐름을 가리킵니다.',
            answer: '테스트 답변',
            supportingRecords: <SupportingRecord>[],
            suggestedFollowUp: '테스트 후속 질문',
            runtimeInfo: CurationRuntimeInfo(
              path: CurationRuntimePath.onDeviceFallback,
              label: '템플릿 폴백 사용 중',
              message: '테스트용 폴백 경로입니다.',
            ),
          ),
          nowProvider: () => DateTime(2026, 4, 24, 10, 0),
        );

    final conversations = container.read(recentConversationsProvider);
    expect(conversations, hasLength(1));
    expect(
      conversations.single.runtimePath,
      CurationRuntimePath.onDeviceFallback,
    );
    expect(conversations.single.resolvedRuntimeBadgeLabel, '폴백');
    expect(
      preferences.getString('app.recent_conversations'),
      contains('"runtime_path":"onDeviceFallback"'),
    );
    expect(
      preferences.getString('app.recent_conversations'),
      contains('"runtime_badge_label":"폴백"'),
    );
  });

  test('build returns empty list for malformed stored JSON', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
      'app.recent_conversations': 'not-json',
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(container.read(recentConversationsProvider), isEmpty);
  });
}
