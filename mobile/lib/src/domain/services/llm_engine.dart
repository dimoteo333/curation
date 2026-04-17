import '../entities/life_record.dart';
import '../../data/local/vector_db.dart';
import '../../data/ondevice/litert_method_channel_bridge.dart';

class GeneratedCuration {
  const GeneratedCuration({
    required this.insightTitle,
    required this.summary,
    required this.answer,
    required this.supportingQuote,
    required this.suggestedFollowUp,
    required this.usedNativeRuntime,
    required this.runtimeMessage,
  });

  final String insightTitle;
  final String summary;
  final String answer;
  final String supportingQuote;
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
        .toList(growable: false);
    final summary = _buildSummary(matches);
    final followUp = _buildFollowUp(
      question: question,
      records: contextRecords,
    );
    final supportingQuote = _buildSupportingQuote(contextRecords.first);

    if (prepared.llmReady) {
      final prompt = _buildPrompt(question: question, records: contextRecords);
      try {
        final answer = await bridge.generate(prompt: prompt);
        return GeneratedCuration(
          insightTitle: _buildInsightTitle(_collectThemes(contextRecords)),
          summary: summary,
          answer: answer,
          supportingQuote: supportingQuote,
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
        .toList(growable: false);
    final topRecord = records.first;
    final secondaryRecord = records.length > 1 ? records[1] : null;
    final themes = _collectThemes(records);
    final recordTime = _describeRelativeTime(topRecord.createdAt);
    final template = _selectFallbackTemplate(
      question: question,
      records: records,
    );
    final answer = switch (template) {
      _FallbackTemplate.reflective =>
        '$recordTime 쓰신 "${topRecord.title}"을 다시 보면, 지금의 질문은 갑자기 생긴 감정보다 오래 버틴 뒤에 몸과 마음이 함께 무거워지는 흐름에 더 가깝습니다. ${_buildSecondaryBridge(secondaryRecord)}그때의 기록에는 이미 ${_summarizeRecoveryCue(records)} 같은 회복 단서도 같이 남아 있습니다.',
      _FallbackTemplate.temporal =>
        '$recordTime의 "${topRecord.title}"에서는 지금 느끼는 감정의 결이 먼저 보입니다. ${_summarizeContent(topRecord.content)}라고 적어 두신 걸 보면, 현재의 어려움도 한 번의 사건보다 누적된 리듬과 더 닿아 있습니다. ${_buildSecondaryBridge(secondaryRecord)}',
      _FallbackTemplate.recovery =>
        '이번 질문은 힘든 이유를 찾는 것만큼, 언제 조금 덜 무너졌는지를 같이 보는 편이 도움이 됩니다. $recordTime 쓰신 "${topRecord.title}"에서도 힘이 빠진 장면 옆에 ${_summarizeRecoveryCue(records)} 같은 회복 행동이 함께 붙어 있었습니다. ${_buildSecondaryBridge(secondaryRecord)}',
      _FallbackTemplate.relationship =>
        '$recordTime 기록인 "${topRecord.title}"을 보면, 지금의 마음은 혼자 견디는 시간이 길어질수록 더 무거워지는 패턴에 가깝습니다. ${_summarizeContent(topRecord.content)}라는 문장처럼, 감정이 풀린 순간에는 대개 누군가와의 대화나 정리가 함께 있었습니다. ${_buildSecondaryBridge(secondaryRecord)}',
      _FallbackTemplate.growth =>
        '이번 질문은 단순히 지쳤다는 이야기보다, 어떤 리듬이 당신을 다시 앞으로 움직이게 했는지 묻는 질문으로도 읽힙니다. $recordTime의 "${topRecord.title}"을 보면 작은 기록, 짧은 실행, 혹은 회복 행동이 다음 날의 감각을 바꾸는 장면이 반복됩니다. ${_buildSecondaryBridge(secondaryRecord)}',
    }.trim();

    return GeneratedCuration(
      insightTitle: _buildInsightTitle(themes),
      summary: _buildSummary(matches),
      answer: answer,
      supportingQuote: _buildSupportingQuote(topRecord),
      suggestedFollowUp: _buildFollowUp(question: question, records: records),
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
      ..writeln('- 응답은 따뜻하지만 과장되지 않게 작성합니다.')
      ..writeln('- 답변에는 시간 맥락, 구체적인 기록 제목, 인용문 1개, 부드러운 후속 질문을 포함합니다.')
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
      ..writeln('위 기록만을 근거로 다음 구조를 지켜 답하세요.')
      ..writeln('1. 현재 질문에 대한 핵심 통찰 2~3문장')
      ..writeln('2. 기록에서 가져온 짧은 인용문 1개')
      ..writeln('3. 사용자가 이어서 적어 볼 부드러운 질문 1개');

    return buffer.toString();
  }

  String _buildSummary(List<VectorSearchMatch> matches) {
    final records = matches
        .map((VectorSearchMatch match) => match.record)
        .toList(growable: false);
    final topRecord = records.first;
    final secondRecord = records.length > 1 ? records[1] : null;
    final lead =
        '${_describeRelativeTime(topRecord.createdAt)} 쓰신 "${topRecord.title}"';
    if (secondRecord == null) {
      return '이번 질문과 가장 가까운 기록은 $lead입니다.';
    }

    return '이번 질문은 $lead와 ${_describeRelativeTime(secondRecord.createdAt)}의 "${secondRecord.title}"에서 반복된 흐름과 가장 가깝습니다.';
  }

  String _buildFollowUp({
    required String question,
    required List<LifeRecord> records,
  }) {
    final themes = _collectThemes(records);
    final topRecord = records.first;
    final timeContext = _describeRelativeTime(topRecord.createdAt);

    if (themes.contains('수면')) {
      return '$timeContext "${topRecord.title}"을 떠올리면서, 최근 일주일 동안 잠이 흐트러진 날과 다음 날의 감정을 같이 적어 보시겠어요?';
    }
    if (themes.contains('번아웃') ||
        themes.contains('야근') ||
        themes.contains('마감')) {
      return '이번 주에 에너지가 급격히 떨어진 순간을 하나만 고르고, 그 직전에 어떤 업무나 약속이 있었는지 함께 적어 보시겠어요?';
    }
    if (themes.contains('운동') || themes.contains('건강')) {
      return '몸이 조금이라도 가벼워졌던 행동이 있었다면, 이번 주에 다시 해볼 수 있는 가장 작은 버전은 무엇인지 적어 보시겠어요?';
    }
    if (themes.contains('관계') || themes.contains('대화')) {
      return '마음이 조금 풀렸던 대화가 있었다면, 그 대화에서 무엇이 안심을 줬는지 한 줄로 적어 보시겠어요?';
    }
    if (themes.contains('창작') || themes.contains('성장')) {
      return '부담 없이 다시 시작할 수 있는 가장 작은 단위를 정해 본다면, 오늘은 어디까지가 적당할지 적어 보시겠어요?';
    }
    if (question.contains('왜')) {
      return '비슷한 감정이 처음 시작된 장면과 조금 나아졌던 장면을 각각 한 줄씩 적어 보시겠어요?';
    }
    return '지금 떠오르는 장면 하나를 더 적는다면, 어떤 순간이 가장 먼저 떠오르는지 적어 보시겠어요?';
  }

  List<String> _collectThemes(List<LifeRecord> records) {
    final counter = <String, int>{};
    for (final record in records) {
      for (final tag in record.tags) {
        counter.update(tag, (int value) => value + 1, ifAbsent: () => 1);
      }
    }

    final entries = counter.entries.toList(growable: false)
      ..sort((MapEntry<String, int> left, MapEntry<String, int> right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }
        return left.key.compareTo(right.key);
      });

    return entries
        .map((MapEntry<String, int> entry) => entry.key)
        .toList(growable: false);
  }

  _FallbackTemplate _selectFallbackTemplate({
    required String question,
    required List<LifeRecord> records,
  }) {
    final dominantTags = _collectThemes(records);
    if (dominantTags.contains('관계') || dominantTags.contains('대화')) {
      return _FallbackTemplate.relationship;
    }
    if (dominantTags.contains('회복') || dominantTags.contains('수면')) {
      return _FallbackTemplate.recovery;
    }
    if (dominantTags.contains('성장') || dominantTags.contains('창작')) {
      return _FallbackTemplate.growth;
    }

    final hash = question.runes.fold<int>(
      records.length * 17,
      (int value, int rune) => value + rune,
    );
    final fallbackPool = <_FallbackTemplate>[
      _FallbackTemplate.reflective,
      _FallbackTemplate.temporal,
      _FallbackTemplate.recovery,
      _FallbackTemplate.growth,
    ];
    return fallbackPool[hash % fallbackPool.length];
  }

  String _buildInsightTitle(List<String> themes) {
    if (themes.contains('수면')) {
      return '수면 리듬이 흔들릴 때의 반응';
    }
    if (themes.contains('번아웃') ||
        themes.contains('야근') ||
        themes.contains('마감')) {
      return '압박이 쌓일 때 먼저 나타나는 신호';
    }
    if (themes.contains('관계') || themes.contains('대화')) {
      return '마음의 무게가 관계 속에서 달라지는 순간';
    }
    if (themes.contains('운동') || themes.contains('건강')) {
      return '몸의 리듬이 회복을 끌어올린 기록';
    }
    if (themes.contains('창작') || themes.contains('성장')) {
      return '작은 실행이 다시 움직이게 한 흐름';
    }
    return '기록에서 반복된 감정의 흐름';
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
      return '1년 전';
    }
    return '$years년 전';
  }

  String _summarizeRecoveryCue(List<LifeRecord> records) {
    const recoveryTags = <String>{
      '회복',
      '산책',
      '휴식',
      '수면',
      '운동',
      '우선순위',
      '대화',
      '기록',
    };
    for (final record in records) {
      final matched = record.tags
          .where(recoveryTags.contains)
          .toList(growable: false);
      if (matched.isNotEmpty) {
        if (matched.length == 1) {
          return '"${matched.first}"처럼 스스로를 추슬렀던 방식';
        }
        return '"${matched.take(2).join(', ')}" 같은 회복 단서';
      }
    }
    return '몸과 마음을 조금 가볍게 만든 행동';
  }

  String _buildSecondaryBridge(LifeRecord? record) {
    if (record == null) {
      return '';
    }
    return '${_describeRelativeTime(record.createdAt)}의 "${record.title}"에서도 비슷한 결이 한 번 더 확인됩니다.';
  }

  String _buildSupportingQuote(LifeRecord record) {
    final sentences = record.content
        .split(RegExp(r'[.!?\n]+'))
        .map((String sentence) => sentence.trim())
        .where((String sentence) => sentence.isNotEmpty)
        .toList(growable: false);

    final selected = sentences.firstWhere(
      (String sentence) => sentence.length >= 12,
      orElse: () => sentences.isEmpty ? record.content.trim() : sentences.first,
    );
    return '"$selected"';
  }

  String _summarizeContent(String content) {
    final sentence = content
        .split(RegExp(r'[.!?\n]+'))
        .map((String value) => value.trim())
        .firstWhere(
          (String value) => value.isNotEmpty,
          orElse: () => content.trim(),
        );
    if (sentence.length <= 72) {
      return sentence;
    }
    return '${sentence.substring(0, 69).trimRight()}...';
  }
}

enum _FallbackTemplate { reflective, temporal, recovery, relationship, growth }
