import 'package:curator_mobile/src/domain/entities/curation_query_scope.dart';
import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/domain/repositories/curation_repository.dart';

class FakeCurationRepository implements CurationRepository {
  FakeCurationRepository({
    this.responseDelay = const Duration(milliseconds: 80),
    CuratedResponse Function(String question, CurationQueryScope scope)?
    responseBuilder,
  }) : _responseBuilder = responseBuilder;

  final Duration responseDelay;
  final CuratedResponse Function(String question, CurationQueryScope scope)?
  _responseBuilder;
  String? lastQuestion;
  CurationQueryScope? lastScope;

  @override
  Future<CuratedResponse> curateQuestion(
    String question, {
    CurationQueryScope scope = CurationQueryScope.all,
  }) async {
    lastQuestion = question;
    lastScope = scope;
    await Future<void>.delayed(responseDelay);
    if (_responseBuilder != null) {
      return _responseBuilder(question, scope);
    }
    return CuratedResponse(
      insightTitle: '최근 기록에서 반복된 흐름',
      summary: '테스트용 질문과 가장 가까운 기록 두 건을 묶어 보여줍니다.',
      answer:
          '기록을 다시 읽어 보며 드리는 짧은 편지입니다.\n\n'
          '최근의 질문은 한 번에 무너진 감정보다 오래 쌓인 피로에 더 가깝습니다. 테스트용 기록에서도 그런 결이 먼저 보입니다. {{CITE:test-record-1}}\n\n'
          '같은 흐름은 다른 테스트 기록에서도 반복되고 있습니다. 그래서 지금은 이유를 단정하기보다 언제 조금 덜 힘들었는지를 같이 보는 편이 더 정확합니다. {{CITE:test-record-2}}\n\n'
          '기록 안에서 이미 작은 회복 단서가 보였으니, 이번에도 아주 작은 행동부터 다시 시작해 보셔도 좋겠습니다.',
      supportingRecords: [
        SupportingRecord(
          id: 'test-record-1',
          source: '일기',
          title: '테스트 기록',
          createdAt: DateTime(2024, 2, 18),
          excerpt: '"테스트용 발췌문입니다."',
          relevanceReason: '테스트용 연결 이유입니다.',
          importSource: 'diary',
          content: '테스트용 첫 번째 기록 내용입니다. 무기력했던 장면과 회복 단서를 함께 담고 있습니다.',
          tags: ['무기력', '회복'],
          metadata: {'mood': 'drained', 'location': '서울 · 합정동'},
        ),
        SupportingRecord(
          id: 'test-record-2',
          source: '메모',
          title: '또 다른 테스트 기록',
          createdAt: DateTime(2024, 3, 2),
          excerpt: '"두 번째 테스트 발췌문입니다."',
          relevanceReason: '흐름을 보강하는 두 번째 테스트 기록입니다.',
          importSource: 'memo',
          content: '두 번째 테스트 기록 내용입니다. 작은 행동이 감각을 바꾼 순간을 담고 있습니다.',
          tags: ['루틴', '회복'],
          metadata: {'mood': 'lighter', 'location': '서울 · 연남동'},
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
