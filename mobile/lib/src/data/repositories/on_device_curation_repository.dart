import '../../domain/entities/curated_response.dart';
import '../../domain/entities/life_record.dart';
import '../../domain/repositories/curation_repository.dart';
import '../../domain/services/llm_engine.dart';
import '../../domain/services/text_embedding_service.dart';
import '../local/vector_db.dart';

class OnDeviceCurationRepository implements CurationRepository {
  OnDeviceCurationRepository({
    required this.vectorDb,
    required this.embeddingService,
    required this.llmEngine,
    required this.seedRecords,
  });

  final VectorDb vectorDb;
  final TextEmbeddingService embeddingService;
  final LlmEngine llmEngine;
  final List<LifeRecord> seedRecords;

  bool _hasSeeded = false;

  @override
  Future<CuratedResponse> curateQuestion(String question) async {
    await _ensureSeeded();

    final queryVector = await embeddingService.embed(question);
    final matches = await vectorDb.search(queryVector, topK: 3);
    if (matches.isEmpty) {
      return const CuratedResponse(
        insightTitle: '연결할 기록이 부족합니다',
        summary: '기기 안의 기록에서 현재 질문과 직접 맞닿는 흐름을 찾지 못했습니다.',
        answer:
            '로컬 기록만 기준으로 다시 찾았지만 아직 연결할 만한 기록이 부족합니다. 감정이나 상황을 조금 더 구체적으로 적어 주시면 다음 검색이 더 정확해집니다.',
        supportingRecords: <SupportingRecord>[],
        suggestedFollowUp: '최근 일주일 동안 반복된 감정이나 일정 변화를 한 줄씩 적어 보시겠어요?',
        runtimeInfo: CurationRuntimeInfo(
          path: CurationRuntimePath.onDeviceFallback,
          label: '템플릿 폴백 사용 중',
          message: '연결된 기록이 부족해 안전한 온디바이스 폴백 흐름으로 안내했습니다.',
        ),
      );
    }

    final generation = await llmEngine.generate(
      question: question,
      matches: matches,
    );
    return CuratedResponse(
      insightTitle: generation.insightTitle,
      summary: generation.summary,
      answer: generation.answer,
      supportingRecords: matches
          .map(
            (VectorSearchMatch match) => SupportingRecord(
              id: match.record.id,
              source: match.record.source,
              title: match.record.title,
              createdAt: match.record.createdAt,
              excerpt: _buildExcerpt(match.record.content),
              relevanceReason: _buildRelevanceReason(match),
            ),
          )
          .toList(growable: false),
      suggestedFollowUp: generation.suggestedFollowUp,
      runtimeInfo: CurationRuntimeInfo(
        path: generation.usedNativeRuntime
            ? CurationRuntimePath.onDeviceNative
            : CurationRuntimePath.onDeviceFallback,
        label: generation.usedNativeRuntime ? '네이티브 LLM 사용 중' : '템플릿 폴백 사용 중',
        message: generation.runtimeMessage,
      ),
    );
  }

  Future<void> _ensureSeeded() async {
    if (_hasSeeded) {
      return;
    }

    await vectorDb.initialize();
    if (await vectorDb.documentCount() == 0) {
      await vectorDb.replaceAllRecords(seedRecords, embeddingService);
    }
    _hasSeeded = true;
  }

  String _buildExcerpt(String content) {
    if (content.length <= 92) {
      return content;
    }
    return '${content.substring(0, 89).trimRight()}...';
  }

  String _buildRelevanceReason(VectorSearchMatch match) {
    final tagSummary = match.record.tags.isEmpty
        ? '기록 맥락'
        : match.record.tags.take(2).join(', ');
    return '로컬 벡터 검색 점수 ${match.score.toStringAsFixed(2)}로 상위에 연결된 기록이며, "$tagSummary" 흐름이 현재 질문과 가깝습니다.';
  }
}
