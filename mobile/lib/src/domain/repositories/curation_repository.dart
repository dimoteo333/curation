import '../entities/curation_query_scope.dart';
import '../entities/curated_response.dart';

abstract class CurationRepository {
  Future<CuratedResponse> curateQuestion(
    String question, {
    CurationQueryScope scope = CurationQueryScope.all,
  });
}
