import '../entities/curated_response.dart';

abstract class CurationRepository {
  Future<CuratedResponse> curateQuestion(String question);
}
