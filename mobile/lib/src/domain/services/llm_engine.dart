import '../entities/life_record.dart';
import '../../data/local/vector_db.dart';
import '../../data/ondevice/litert_method_channel_bridge.dart';

class GeneratedCuration {
  const GeneratedCuration({
    required this.insightTitle,
    required this.summary,
    required this.answer,
    required this.suggestedFollowUp,
    required this.usedNativeRuntime,
    required this.runtimeMessage,
  });

  final String insightTitle;
  final String summary;
  final String answer;
  final String suggestedFollowUp;
  final bool usedNativeRuntime;
  final String runtimeMessage;
}

class LlmEngine {
  const LlmEngine({required this.bridge, this.llmModelPath});

  final OnDeviceLlmBridge bridge;
  final String? llmModelPath;

  Future<GeneratedCuration> generate({
    required String question,
    required List<VectorSearchMatch> matches,
  }) async {
    final prepared = await bridge.prepare(llmModelPath: llmModelPath);
    final contextRecords = matches
        .map((VectorSearchMatch match) => match.record)
        .toList();
    final summary = _buildSummary(matches);
    final followUp = _buildFollowUp(contextRecords);

    if (prepared.llmReady) {
      final prompt = _buildPrompt(question: question, records: contextRecords);
      try {
        final answer = await bridge.generate(prompt: prompt);
        return GeneratedCuration(
          insightTitle: '기록 속에서 드러난 연결',
          summary: summary,
          answer: answer,
          suggestedFollowUp: followUp,
          usedNativeRuntime: true,
          runtimeMessage: prepared.message,
        );
      } on OnDeviceRuntimeException catch (error) {
        return _buildFallback(question, matches, error.message);
      }
    }

    return _buildFallback(question, matches, prepared.message);
  }

  GeneratedCuration _buildFallback(
    String question,
    List<VectorSearchMatch> matches,
    String runtimeMessage,
  ) {
    final records = matches
        .map((VectorSearchMatch match) => match.record)
        .toList();
    final topRecord = records.first;
    final themeText = _collectThemes(records).take(2).join(', ');

    return GeneratedCuration(
      insightTitle: '로컬 기록에서 감지된 흐름',
      summary: _buildSummary(matches),
      answer:
          '질문하신 "$question" 흐름은 ${topRecord.createdAt.year}년 ${topRecord.createdAt.month}월의 "${topRecord.title}" 기록과 가장 가깝습니다. '
          '연결된 기록들을 보면 $themeText 패턴이 반복되고 있고, 특히 ${topRecord.content} 같은 장면에서 회복 단서가 함께 나타납니다. '
          '현재 단계에서는 온디바이스 템플릿 엔진으로 응답을 구성했지만, 검색과 조합은 모두 기기 안에서 처리했습니다.',
      suggestedFollowUp: _buildFollowUp(records),
      usedNativeRuntime: false,
      runtimeMessage: runtimeMessage,
    );
  }

  String _buildPrompt({
    required String question,
    required List<LifeRecord> records,
  }) {
    final buffer = StringBuffer()
      ..writeln('당신은 사용자의 삶의 기록을 함께 돌아보며 통찰을 제공하는 라이프 큐레이터입니다.')
      ..writeln('외부 지식을 사용하지 말고, 주어진 개인 기록과 질문만 근거로 답변하세요.')
      ..writeln('규칙:')
      ..writeln('- 존댓말을 사용합니다.')
      ..writeln('- 과거 기록에 없는 내용은 추측하지 않습니다.')
      ..writeln('- 의학적 진단이나 치료 조언은 하지 않습니다.')
      ..writeln()
      ..writeln('[질문]')
      ..writeln(question)
      ..writeln()
      ..writeln('[관련 개인 기록들]');

    for (final record in records) {
      buffer
        ..writeln(
          '- ${record.id} | ${record.createdAt.toIso8601String()} | ${record.source} | ${record.title}',
        )
        ..writeln(record.content)
        ..writeln();
    }

    buffer
      ..writeln('위 기록만을 근거로 현재 상태를 과거 패턴과 연결해 설명하세요.')
      ..writeln('가능하면 과거에 도움이 되었던 행동을 정리하고, 다시 참고할 기록 ID를 알려주세요.');

    return buffer.toString();
  }

  String _buildSummary(List<VectorSearchMatch> matches) {
    final records = matches
        .map((VectorSearchMatch match) => match.record)
        .toList();
    final themes = _collectThemes(records).take(2).join(', ');
    final titles = records
        .take(2)
        .map((LifeRecord record) => record.title)
        .join(', ');
    return '로컬 검색에서 ${matches.length}건의 기록이 연결되었고, $themes 흐름이 두드러집니다. 특히 $titles 기록이 현재 질문과 가깝습니다.';
  }

  String _buildFollowUp(List<LifeRecord> records) {
    final referenceIds = records
        .take(2)
        .map((LifeRecord record) => record.id)
        .join(', ');
    return '지금과 가장 비슷한 기록으로 $referenceIds 를 다시 열어 보고, 그날 도움이 됐던 행동을 한 줄씩 적어 보시겠어요?';
  }

  List<String> _collectThemes(List<LifeRecord> records) {
    final counter = <String, int>{};
    for (final record in records) {
      for (final tag in record.tags) {
        counter.update(tag, (int value) => value + 1, ifAbsent: () => 1);
      }
    }

    final entries = counter.entries.toList()
      ..sort((MapEntry<String, int> left, MapEntry<String, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }
        return left.key.compareTo(right.key);
      });

    return entries.map((MapEntry<String, int> entry) => entry.key).toList();
  }
}
