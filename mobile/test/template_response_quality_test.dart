import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('템플릿 폴백은 기록 제목, 시간 맥락, 인용문, 후속 질문을 모두 포함한다', () async {
    final engine = LlmEngine(
      bridge: const _FallbackBridge(),
      nowProvider: () => DateTime(2026, 4, 17),
    );

    final result = await engine.generate(
      question: '요즘 왜 이렇게 지치고 일 생각이 머리에서 안 떠날까?',
      matches: <VectorSearchMatch>[
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (LifeRecord record) => record.id == 'diary-burnout-nov-2024',
          ),
          score: 0.88,
        ),
        VectorSearchMatch(
          record: seededLifeRecords.firstWhere(
            (LifeRecord record) => record.id == 'diary-burnout-feb-2024',
          ),
          score: 0.79,
        ),
      ],
    );

    expect(result.usedNativeRuntime, isFalse);
    expect(result.insightTitle, isNotEmpty);
    expect(result.summary, contains('쉬어도 피곤한 주말'));
    expect(_paragraphs(result.answer), hasLength(greaterThanOrEqualTo(3)));
    expect(result.answer, contains('{{CITE:diary-burnout-nov-2024}}'));
    expect(result.answer, contains('{{CITE:diary-burnout-feb-2024}}'));
    expect(result.supportingQuote, startsWith('"'));
    expect(
      result.supportingQuote,
      contains('토요일 내내 누워 있었는데도 피로가 풀리지 않았다'),
    );
    expect(result.suggestedFollowUp, isNotEmpty);
  });
}

List<String> _paragraphs(String answer) {
  return answer
      .split(RegExp(r'\n\s*\n'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
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
