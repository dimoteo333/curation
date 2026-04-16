import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/domain/repositories/curation_repository.dart';

class FakeCurationRepository implements CurationRepository {
  @override
  Future<CuratedResponse> curateQuestion(String question) async {
    return CuratedResponse(
      insightTitle: '최근 기록에서 반복된 흐름',
      summary: '테스트용 요약입니다.',
      answer: '테스트 환경에서도 질문 흐름이 화면에 표시됩니다.',
      supportingRecords: [
        SupportingRecord(
          id: 'test-record',
          source: 'diary',
          title: '테스트 기록',
          createdAt: DateTime(2024, 2, 18),
          excerpt: '테스트용 발췌문입니다.',
          relevanceReason: '테스트용 연결 이유입니다.',
        ),
      ],
      suggestedFollowUp: '다음 질문을 이어서 적어 보세요.',
      runtimeInfo: const CurationRuntimeInfo(
        path: CurationRuntimePath.onDeviceFallback,
        label: '템플릿 폴백 사용 중',
        message: '테스트 환경에서는 안전한 폴백 경로를 사용합니다.',
      ),
    );
  }
}
