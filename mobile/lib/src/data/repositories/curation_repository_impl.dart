import '../../domain/entities/curated_response.dart';
import '../../domain/repositories/curation_repository.dart';
import '../sources/curation_remote_data_source.dart';

class CurationRepositoryImpl implements CurationRepository {
  const CurationRepositoryImpl({required this.remoteDataSource});

  final CurationRemoteDataSource remoteDataSource;

  @override
  Future<CuratedResponse> curateQuestion(String question) async {
    final response = await remoteDataSource.fetchCuration(question: question);
    return response.toDomain();
  }
}
