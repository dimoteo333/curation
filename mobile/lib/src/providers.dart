import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'data/repositories/curation_repository_impl.dart';
import 'data/sources/curation_remote_data_source.dart';
import 'domain/repositories/curation_repository.dart';
import 'domain/use_cases/request_curation_use_case.dart';

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final client = ref.watch(httpClientProvider);
  return ApiClient(baseUrl: config.apiBaseUrl, client: client);
});

final curationRemoteDataSourceProvider = Provider<CurationRemoteDataSource>((
  ref,
) {
  return CurationRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

final curationRepositoryProvider = Provider<CurationRepository>((ref) {
  return CurationRepositoryImpl(
    remoteDataSource: ref.watch(curationRemoteDataSourceProvider),
  );
});

final requestCurationUseCaseProvider = Provider<RequestCurationUseCase>((ref) {
  return RequestCurationUseCase(ref.watch(curationRepositoryProvider));
});
