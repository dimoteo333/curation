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
    this.embedderModelPath,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final OnDeviceLlmBridge bridge;
  final String? llmModelPath;
  final String? embedderModelPath;
  final DateTime Function() _nowProvider;

  Future<GeneratedCuration> generate({
    required String question,
    required List<VectorSearchMatch> matches,
  }) async {
    final prepared = await bridge.prepare(
      llmModelPath: llmModelPath,
      embedderModelPath: embedderModelPath,
    );
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
          answer: _normalizeEssayAnswer(answer, records: contextRecords),
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
    final themes = _collectThemes(records);
    final answer = _buildFallbackEssay(question: question, records: records);

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
      ..writeln('- 답변은 4~5개의 짧은 문단으로 구성된 편지/에세이 형식으로 작성합니다.')
      ..writeln('- 문단은 빈 줄 하나로 구분합니다.')
      ..writeln('- 기록을 직접 언급하는 문장 끝에는 반드시 {{CITE:record_id}} 토큰을 붙입니다.')
      ..writeln('- 질문에 답하는 통찰, 패턴 해석, 회복 단서가 모두 포함되어야 합니다.')
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
      ..writeln('위 기록만을 근거로 답하세요.')
      ..writeln('출력 형식:')
      ..writeln('1. 첫 문단은 편지를 시작하는 짧은 문장')
      ..writeln('2. 둘째 문단부터는 기록을 근거로 한 해석')
      ..writeln('3. 최소 두 개 이상의 {{CITE:record_id}} 토큰 포함')
      ..writeln('4. 마지막 문단은 부드러운 가능성 제안으로 마무리');

    return buffer.toString();
  }

  String _normalizeEssayAnswer(
    String answer, {
    required List<LifeRecord> records,
  }) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      return _buildFallbackEssay(question: '', records: records);
    }
    if (trimmed.contains('{{CITE:')) {
      return trimmed;
    }
    final fallback = _buildFallbackEssay(question: '', records: records);
    final paragraphs = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.isEmpty) {
      return fallback;
    }
    final withCitations = <String>[
      paragraphs.first,
      if (paragraphs.length > 1)
        '${paragraphs[1]} {{CITE:${records.first.id}}}'
      else
        '{{CITE:${records.first.id}}}',
      ...paragraphs.skip(2),
    ];
    if (records.length > 1) {
      withCitations.add(
        '비슷한 흐름은 "${records[1].title}"에서도 한 번 더 보입니다. {{CITE:${records[1].id}}}',
      );
    }
    return withCitations.join('\n\n');
  }

  String _buildFallbackEssay({
    required String question,
    required List<LifeRecord> records,
  }) {
    final topRecord = records.first;
    final secondaryRecord = records.length > 1 ? records[1] : null;
    final thirdRecord = records.length > 2 ? records[2] : null;
    final tone = _selectFallbackTemplate(question: question, records: records);
    final opening = switch (tone) {
      _FallbackTemplate.relationship =>
        '기록을 다시 천천히 훑어보며 드리는 작은 편지입니다.',
      _FallbackTemplate.growth =>
        '기록 안에서 다시 움직이게 한 장면들을 모아 보았습니다.',
      _FallbackTemplate.recovery =>
        '기록 속에서 조금 덜 무너졌던 순간을 먼저 살펴보았습니다.',
      _FallbackTemplate.temporal =>
        '지금의 질문이 언제부터 시작된 흐름인지 기록으로 짚어 보았습니다.',
      _FallbackTemplate.reflective =>
        '질문과 가장 가까이 닿아 있는 기록들을 다시 읽어 보았습니다.',
    };
    final first = '${_describeRelativeTime(topRecord.createdAt)}의 "${topRecord.title}"을 보면, 지금 느끼는 무게는 갑자기 생긴 것보다 조금씩 누적된 흐름에 더 가깝습니다. ${_summarizeContent(topRecord.content)}라는 문장이 특히 먼저 보입니다. {{CITE:${topRecord.id}}}';

    final second = switch (tone) {
      _FallbackTemplate.relationship =>
        secondaryRecord == null
            ? '기록을 보면 혼자 견디는 시간이 길어질수록 마음의 무게가 더 커지는 패턴이 있습니다.'
            : '비슷한 결은 ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"에서도 한 번 더 나타납니다. 감정이 풀리는 쪽에는 대개 대화나 관계의 회복이 함께 붙어 있었습니다. {{CITE:${secondaryRecord.id}}}',
      _FallbackTemplate.growth =>
        secondaryRecord == null
            ? '완전히 회복된 날보다, 작게라도 다시 시작한 장면이 전환점으로 남아 있습니다.'
            : '또 ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"에서는 작은 실행이 감각을 바꾸는 장면이 보입니다. 완성보다 시작 속도가 먼저 회복을 열어 준 셈입니다. {{CITE:${secondaryRecord.id}}}',
      _FallbackTemplate.recovery =>
        secondaryRecord == null
            ? '흥미로운 점은 힘이 빠진 날 옆에 회복 단서도 함께 적혀 있다는 점입니다.'
            : '흥미로운 점은 비슷하게 지친 기록 옆에 회복 행동이 같이 남아 있다는 것입니다. ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"도 그런 단서로 이어집니다. {{CITE:${secondaryRecord.id}}}',
      _FallbackTemplate.temporal =>
        secondaryRecord == null
            ? '그래서 이번 어려움도 한 번의 사건보다 리듬이 무너진 시간을 함께 볼 필요가 있습니다.'
            : '시간을 조금 넓혀 보면 ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"에서도 비슷한 결이 반복됩니다. 한 번의 사건보다 리듬이 흔들릴 때 같은 감정이 다시 찾아오는 편입니다. {{CITE:${secondaryRecord.id}}}',
      _FallbackTemplate.reflective =>
        secondaryRecord == null
            ? '그래서 지금의 질문은 원인을 단정하기보다, 오래 버틴 뒤 어떤 신호가 먼저 나타나는지를 보는 편이 더 정확해 보입니다.'
            : '그래서 지금의 질문은 원인을 단정하기보다, 오래 버틴 뒤 어떤 신호가 먼저 나타나는지를 보는 편이 더 정확해 보입니다. ${_describeRelativeTime(secondaryRecord.createdAt)}의 "${secondaryRecord.title}"도 같은 흐름을 보강합니다. {{CITE:${secondaryRecord.id}}}',
    };

    final third = thirdRecord == null
        ? '기록 전체를 보면 거창한 결심보다 ${_summarizeRecoveryCue(records)} 같은 작고 구체적인 행동이 다시 버틸 힘을 만든 적이 많았습니다.'
        : '한편 ${_describeRelativeTime(thirdRecord.createdAt)}의 "${thirdRecord.title}"에서는 조금 다른 결이 보입니다. 완전히 나아진 날이라기보다, 몸을 움직이거나 리듬을 바꾸며 다시 숨을 돌린 장면에 가깝습니다. {{CITE:${thirdRecord.id}}}';

    final closing = question.contains('왜')
        ? '지금의 답은 "왜 이런가"를 단정하기보다, 언제 같은 흐름이 시작되고 무엇이 조금이라도 숨통을 틔웠는지를 기억해 두는 데 더 가까워 보입니다.'
        : '지금 바로 큰 답을 찾지 않아도 괜찮습니다. 기록 속에서 이미 여러 번 통했던 작은 전환을 다시 꺼내 보는 편이 더 현실적인 시작일 수 있습니다.';

    return <String>[opening, first, second, third, closing].join('\n\n');
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
