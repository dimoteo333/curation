import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('폴백 응답은 시간 맥락과 태그를 풍부하게 반영한다', () async {
    final engine = LlmEngine(
      bridge: const _FallbackBridge(),
      nowProvider: () => DateTime(2026, 4, 17),
    );

    final result = await engine.generate(
      question: '왜 이렇게 무기력하고 번아웃처럼 느껴질까?',
      matches: <VectorSearchMatch>[
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (record) => record.id == 'diary-burnout-feb-2024',
          ),
          score: 0.81,
        ),
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (record) => record.id == 'diary-project-pressure-2022',
          ),
          score: 0.63,
        ),
      ],
    );

    expect(result.usedNativeRuntime, isFalse);
    expect(result.insightTitle, '압박이 쌓일 때 나타나는 소진 패턴');
    expect(result.summary, contains('2년 전 "야근이 길어지던 주간 회고"'));
    expect(result.answer, anyOf(contains('무기력'), contains('산책, 회복')));
    expect(result.answer, contains('2년 전'));
    expect(result.answer, contains('회복'));
    expect(result.suggestedFollowUp, contains('업무 이벤트'));
  });

  test('수면 맥락에서는 수면 패턴 중심 후속 질문을 만든다', () async {
    final engine = LlmEngine(
      bridge: const _FallbackBridge(),
      nowProvider: () => DateTime(2026, 4, 17),
    );

    final result = await engine.generate(
      question: '요즘 잠이 뒤집혀서 하루 종일 멍해',
      matches: <VectorSearchMatch>[
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (record) => record.id == 'diary-routine-reset-2023',
          ),
          score: 0.74,
        ),
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (record) => record.id == 'diary-burnout-feb-2024',
          ),
          score: 0.42,
        ),
      ],
    );

    expect(result.insightTitle, '수면 리듬이 흔들릴 때의 반응');
    expect(result.answer, contains('수면'));
    expect(result.suggestedFollowUp, contains('잠든 시간'));
  });
}

class _FallbackBridge implements OnDeviceLlmBridge {
  const _FallbackBridge();

  @override
  Future<List<double>> embed(String text) async => <double>[0.0];

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    throw UnimplementedError();
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
      message: '모델이 없어 폴백 경로를 사용합니다.',
      platform: 'flutter-test',
      llmModelConfigured: false,
      embedderModelConfigured: false,
      llmModelAvailable: false,
      embedderModelAvailable: false,
      fallbackActive: true,
    );
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async {
    throw UnimplementedError();
  }
}
