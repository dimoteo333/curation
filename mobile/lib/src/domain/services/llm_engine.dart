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
  LlmEngine({
    required this.bridge,
    this.llmModelPath,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final OnDeviceLlmBridge bridge;
  final String? llmModelPath;
  final DateTime Function() _nowProvider;

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
    final secondaryRecord = records.length > 1 ? records[1] : null;
    final themes = _collectThemes(records);
    final themeText = themes.take(3).join(', ');
    final fallbackPattern = _selectFallbackPattern(
      question: question,
      records: records,
    );
    final timeContext = _describeRelativeTime(topRecord.createdAt);
    final tagSummary = _joinTags(topRecord.tags, maxItems: 3);
    final recoveryCue = _extractRecoveryCue(records);
    final secondaryContext = secondaryRecord == null
        ? ''
        : ' ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"에서도 ${_joinTags(secondaryRecord.tags, maxItems: 2)} 흐름이 반복됩니다.';
    final answer = switch (fallbackPattern) {
      _FallbackPattern.timeAnchored =>
        '지금의 "$question" 감각은 $timeContext에 남긴 "${topRecord.title}" 기록과 가장 가깝습니다. '
            '이 장면에는 $tagSummary 축이 함께 묶여 있었고, ${_summarizeContent(topRecord.content)}.$secondaryContext '
            '당시 기록을 다시 보면 $recoveryCue 같은 회복 단서가 이미 남아 있습니다. '
            '현재는 온디바이스 폴백 생성기를 사용하지만, 검색과 시간축 정리는 모두 기기 안에서 처리했습니다.',
      _FallbackPattern.patternFocused =>
        '"${topRecord.title}"를 중심으로 보면 최근 질문은 $themeText 패턴 쪽으로 강하게 연결됩니다. '
            '$timeContext의 기록에서는 ${_summarizeContent(topRecord.content)} 같은 반응이 먼저 나타났고,$secondaryContext '
            '특히 ${_joinTags(records.expand((LifeRecord record) => record.tags).toList(), maxItems: 4)} 태그가 같은 묶음으로 반복됩니다. '
            '지금은 네이티브 LLM 대신 폴백 응답이지만, 근거가 된 기록 선택은 로컬 검색 결과를 그대로 반영했습니다.',
      _FallbackPattern.recoveryFocused =>
        '지금의 흐름을 보면 소진 자체보다 회복이 붙었던 순간을 같이 보는 편이 좋습니다. '
            '$timeContext의 "${topRecord.title}"에서 ${_summarizeContent(topRecord.content)} 장면이 있었고,$secondaryContext '
            '$recoveryCue 같은 행동이 질문과 연결된 기록들에 반복해서 남아 있습니다. '
            '현재는 폴백 생성 경로지만, 태그와 내용 조합은 온디바이스 검색 결과를 기준으로 정리했습니다.',
    };

    return GeneratedCuration(
      insightTitle: _buildInsightTitle(themes),
      summary: _buildSummary(matches),
      answer: answer,
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
    final themes = _collectThemes(records).take(3).join(', ');
    final timeline = records
        .take(2)
        .map(
          (LifeRecord record) =>
              '${_describeRelativeTime(record.createdAt)} "${record.title}"',
        )
        .join('와 ');
    return '로컬 검색에서 ${matches.length}건의 기록이 연결되었고, $themes 흐름이 두드러집니다. 특히 $timeline 기록이 현재 질문과 같은 결로 묶였습니다.';
  }

  String _buildFollowUp(List<LifeRecord> records) {
    final themes = _collectThemes(records);
    final recordIds = records
        .take(2)
        .map((LifeRecord record) => record.id)
        .join(', ');

    if (themes.contains('수면')) {
      return '$recordIds 기록을 다시 보면서, 잠든 시간과 다음 날 집중도가 어떻게 달랐는지 이번 주 기준으로 적어 보시겠어요?';
    }
    if (themes.contains('야근') ||
        themes.contains('번아웃') ||
        themes.contains('마감')) {
      return '$recordIds 기록을 참고해, 이번 주에 에너지가 급격히 떨어진 순간과 바로 전에 있었던 업무 이벤트를 짝지어 적어 보시겠어요?';
    }
    if (themes.contains('산책') ||
        themes.contains('회복') ||
        themes.contains('휴식')) {
      return '$recordIds 기록에서 실제로 회복감을 만든 행동을 골라, 지금 다시 시도할 수 있는 것 한 가지를 정해 보시겠어요?';
    }
    return '$recordIds 기록을 다시 열어 보고, 그날 감정의 시작점과 조금 나아진 순간을 각각 한 줄씩 적어 보시겠어요?';
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

  _FallbackPattern _selectFallbackPattern({
    required String question,
    required List<LifeRecord> records,
  }) {
    final dominantTags = _collectThemes(records);
    if (dominantTags.contains('수면') || dominantTags.contains('회복')) {
      return _FallbackPattern.recoveryFocused;
    }

    final hash = question.runes.fold<int>(
      records.length,
      (int value, int rune) => value + rune,
    );
    return _FallbackPattern.values[hash % _FallbackPattern.values.length];
  }

  String _buildInsightTitle(List<String> themes) {
    if (themes.contains('수면')) {
      return '수면 리듬이 흔들릴 때의 반응';
    }
    if (themes.contains('번아웃') || themes.contains('야근')) {
      return '압박이 쌓일 때 나타나는 소진 패턴';
    }
    if (themes.contains('산책') || themes.contains('회복')) {
      return '회복 단서가 남아 있는 기록';
    }
    return '로컬 기록에서 감지된 흐름';
  }

  String _describeRelativeTime(DateTime value) {
    final now = _nowProvider();
    final difference = now.difference(value);
    if (difference.inDays < 30) {
      if (difference.inDays <= 1) {
        return '최근';
      }
      return '${difference.inDays}일 전';
    }

    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '$months개월 전';
    }

    final years = (difference.inDays / 365).floor();
    if (years == 1) {
      return '작년';
    }
    return '$years년 전';
  }

  String _joinTags(List<String> tags, {required int maxItems}) {
    if (tags.isEmpty) {
      return '기록';
    }
    return tags.take(maxItems).join(', ');
  }

  String _extractRecoveryCue(List<LifeRecord> records) {
    const recoveryTags = <String>{'회복', '산책', '휴식', '수면', '스트레칭', '우선순위'};
    for (final record in records) {
      final matched = record.tags.where(recoveryTags.contains).toList();
      if (matched.isNotEmpty) {
        return matched.join(', ');
      }
    }
    return '숨통이 트였던 행동';
  }

  String _summarizeContent(String content) {
    final sentence = content.split('.').first.trim();
    if (sentence.length <= 70) {
      return sentence;
    }
    return '${sentence.substring(0, 67).trimRight()}...';
  }
}

enum _FallbackPattern { timeAnchored, patternFocused, recoveryFocused }
