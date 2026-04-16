import '../entities/curated_response.dart';
import '../repositories/curation_repository.dart';

class RequestCurationUseCase {
  const RequestCurationUseCase(this._repository);

  final CurationRepository _repository;

  Future<CuratedResponse> call(String question) {
    return _repository.curateQuestion(question.trim());
  }
}
