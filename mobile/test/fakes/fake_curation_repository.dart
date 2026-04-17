import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/domain/repositories/curation_repository.dart';

class FakeCurationRepository implements CurationRepository {
  FakeCurationRepository({
    this.responseDelay = const Duration(milliseconds: 80),
  });

  final Duration responseDelay;

  @override
  Future<CuratedResponse> curateQuestion(String question) async {
    await Future<void>.delayed(responseDelay);
    return CuratedResponse(
      insightTitle: '최근 기록에서 반복된 흐름',
      summary: '테스트용 질문과 가장 가까운 기록 두 건을 묶어 보여줍니다.',
      answer: '테스트 환경에서도 질문과 맞닿은 기록을 조용히 엮어 보여드립니다.',
      supportingRecords: [
        SupportingRecord(
          id: 'test-record',
          source: 'diary',
          title: '테스트 기록',
          createdAt: DateTime(2024, 2, 18),
          excerpt: '"테스트용 발췌문입니다."',
          relevanceReason: '테스트용 연결 이유입니다.',
        ),
      ],
      suggestedFollowUp: '다음으로 떠오르는 장면 하나를 더 적어 보시겠어요?',
      runtimeInfo: const CurationRuntimeInfo(
        path: CurationRuntimePath.onDeviceFallback,
        label: '템플릿 폴백 사용 중',
        message: '테스트 환경에서는 안전한 폴백 경로를 사용합니다.',
      ),
    );
  }
}
