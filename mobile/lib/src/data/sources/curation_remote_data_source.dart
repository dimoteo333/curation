import '../../core/network/api_client.dart';
import '../dto/curated_response_dto.dart';

class CurationRemoteDataSource {
  const CurationRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CuratedResponseDto> fetchCuration({required String question}) async {
    final json = await apiClient.postJson(
      '/api/v1/curation/query',
      body: <String, dynamic>{'question': question, 'top_k': 3},
    );

    return CuratedResponseDto.fromJson(json);
  }
}
