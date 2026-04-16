import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'data/local/seed_records.dart';
import 'data/local/vector_db.dart';
import 'data/ondevice/litert_method_channel_bridge.dart';
import 'data/ondevice/litert_text_embedding_service.dart';
import 'data/ondevice/semantic_embedding_service.dart';
import 'data/repositories/curation_repository_impl.dart';
import 'data/repositories/on_device_curation_repository.dart';
import 'data/sources/curation_remote_data_source.dart';
import 'domain/entities/life_record.dart';
import 'domain/repositories/curation_repository.dart';
import 'domain/services/llm_engine.dart';
import 'domain/services/text_embedding_service.dart';
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

final onDeviceLlmBridgeProvider = Provider<OnDeviceLlmBridge>((ref) {
  return const MethodChannelOnDeviceLlmBridge();
});

final onDeviceRuntimeStatusProvider = FutureProvider<OnDeviceRuntimeStatus>((
  ref,
) async {
  final config = ref.watch(appConfigProvider);
  if (config.curationMode == CurationRuntimeMode.remote) {
    return OnDeviceRuntimeStatus.remoteHarness();
  }

  return ref
      .watch(onDeviceLlmBridgeProvider)
      .prepare(
        llmModelPath: config.llmModelPath,
        embedderModelPath: config.embedderModelPath,
      );
});

final fallbackTextEmbeddingServiceProvider = Provider<TextEmbeddingService>((
  ref,
) {
  return const SemanticEmbeddingService();
});

final textEmbeddingServiceProvider = Provider<TextEmbeddingService>((ref) {
  final config = ref.watch(appConfigProvider);
  return LiteRtTextEmbeddingService(
    bridge: ref.watch(onDeviceLlmBridgeProvider),
    fallback: ref.watch(fallbackTextEmbeddingServiceProvider),
    embedderModelPath: config.embedderModelPath,
  );
});

final seedRecordsProvider = Provider<List<LifeRecord>>((ref) {
  return seededLifeRecords;
});

final vectorDbProvider = Provider<VectorDb>((ref) {
  final config = ref.watch(appConfigProvider);
  return VectorDb(
    databaseFactory: databaseFactory,
    databasePathResolver: () async {
      final databaseDirectory = await getDatabasesPath();
      return path.join(databaseDirectory, config.vectorDbName);
    },
  );
});

final llmEngineProvider = Provider<LlmEngine>((ref) {
  final config = ref.watch(appConfigProvider);
  return LlmEngine(
    bridge: ref.watch(onDeviceLlmBridgeProvider),
    llmModelPath: config.llmModelPath,
  );
});

final remoteCurationRepositoryProvider = Provider<CurationRepository>((ref) {
  return CurationRepositoryImpl(
    remoteDataSource: ref.watch(curationRemoteDataSourceProvider),
  );
});

final onDeviceCurationRepositoryProvider = Provider<CurationRepository>((ref) {
  return OnDeviceCurationRepository(
    vectorDb: ref.watch(vectorDbProvider),
    embeddingService: ref.watch(textEmbeddingServiceProvider),
    llmEngine: ref.watch(llmEngineProvider),
    seedRecords: ref.watch(seedRecordsProvider),
  );
});

final curationRepositoryProvider = Provider<CurationRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.curationMode == CurationRuntimeMode.remote) {
    return ref.watch(remoteCurationRepositoryProvider);
  }

  return ref.watch(onDeviceCurationRepositoryProvider);
});

final requestCurationUseCaseProvider = Provider<RequestCurationUseCase>((ref) {
  return RequestCurationUseCase(ref.watch(curationRepositoryProvider));
});
