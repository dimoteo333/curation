import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'core/config/app_build_info.dart';
import 'core/config/app_config.dart';
import 'core/config/app_settings.dart';
import 'core/security/database_encryption.dart';
import 'core/network/api_client.dart';
import 'data/import/calendar_import_service.dart';
import 'data/import/file_picker_gateway.dart';
import 'data/import/file_record_import_service.dart';
import 'data/import/import_history_service.dart';
import 'data/import/pending_shared_import_service.dart';
import 'data/local/life_record_store.dart';
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
import 'state/app_settings_controller.dart';
import 'state/excluded_records_controller.dart';
import 'state/recent_conversations_controller.dart';

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden at app bootstrap.',
  );
});
final appBuildInfoProvider = Provider<AppBuildInfo>((ref) {
  return const AppBuildInfo.fallback();
});
final secureKeyStoreProvider = Provider<SecureKeyStore>((ref) {
  return FlutterSecureKeyStore(storage: const FlutterSecureStorage());
});
final databaseEncryptionProvider = Provider<DatabaseEncryption>((ref) {
  final buildInfo = ref.watch(appBuildInfoProvider);
  return DatabaseEncryption(
    secureKeyStore: ref.watch(secureKeyStoreProvider),
    appNamespace: buildInfo.packageName,
  );
});
final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
final excludedRecordIdsProvider =
    NotifierProvider<ExcludedRecordsController, Set<String>>(
      ExcludedRecordsController.new,
    );

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
  final settings = ref.watch(appSettingsProvider);
  if (settings.runtimeMode == CurationRuntimeMode.remote) {
    return OnDeviceRuntimeStatus.remoteHarness();
  }

  return ref
      .watch(onDeviceLlmBridgeProvider)
      .prepare(
        llmModelPath: settings.llmModelPath,
        embedderModelPath: settings.embedderModelPath,
      );
});

final fallbackTextEmbeddingServiceProvider = Provider<TextEmbeddingService>((
  ref,
) {
  return const SemanticEmbeddingService();
});

final textEmbeddingServiceProvider = Provider<TextEmbeddingService>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return LiteRtTextEmbeddingService(
    bridge: ref.watch(onDeviceLlmBridgeProvider),
    fallback: ref.watch(fallbackTextEmbeddingServiceProvider),
    llmModelPath: settings.llmModelPath,
    embedderModelPath: settings.embedderModelPath,
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
    databaseEncryption: ref.watch(databaseEncryptionProvider),
  );
});

final llmEngineProvider = Provider<LlmEngine>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return LlmEngine(
    bridge: ref.watch(onDeviceLlmBridgeProvider),
    llmModelPath: settings.llmModelPath,
    embedderModelPath: settings.embedderModelPath,
  );
});

final lifeRecordStoreProvider = Provider<LifeRecordStore>((ref) {
  return LifeRecordStore(
    vectorDb: ref.watch(vectorDbProvider),
    databaseEncryption: ref.watch(databaseEncryptionProvider),
    embeddingService: ref.watch(textEmbeddingServiceProvider),
    seedRecords: ref.watch(seedRecordsProvider),
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final importHistoryServiceProvider = Provider<ImportHistoryService>((ref) {
  return ImportHistoryService(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final importFilePickerProvider = Provider<ImportFilePicker>((ref) {
  return const FilePickerImportFilePicker();
});

final fileRecordImportServiceProvider = Provider<FileRecordImportService>((
  ref,
) {
  return FileRecordImportService(
    recordStore: ref.watch(lifeRecordStoreProvider),
    filePicker: ref.watch(importFilePickerProvider),
    importHistoryService: ref.watch(importHistoryServiceProvider),
  );
});

final pendingSharedImportBridgeProvider = Provider<PendingSharedImportBridge>((
  ref,
) {
  return MethodChannelPendingSharedImportBridge();
});

final pendingSharedImportServiceProvider = Provider<PendingSharedImportService>(
  (ref) {
    return PendingSharedImportService(
      bridge: ref.watch(pendingSharedImportBridgeProvider),
      fileImportService: ref.watch(fileRecordImportServiceProvider),
    );
  },
);

final deviceCalendarGatewayProvider = Provider<DeviceCalendarGateway>((ref) {
  return PluginDeviceCalendarGateway();
});

final calendarImportServiceProvider = Provider<CalendarImportService>((ref) {
  return CalendarImportService(
    recordStore: ref.watch(lifeRecordStoreProvider),
    importHistoryService: ref.watch(importHistoryServiceProvider),
    calendarGateway: ref.watch(deviceCalendarGatewayProvider),
  );
});

final importHistorySnapshotProvider = FutureProvider<ImportHistorySnapshot>((
  ref,
) async {
  ref.watch(localDataRevisionProvider);
  return ref.watch(importHistoryServiceProvider).loadSnapshot();
});

final calendarSyncStatusProvider = FutureProvider<CalendarSyncStatus>((
  ref,
) async {
  ref.watch(localDataRevisionProvider);
  final settings = ref.watch(appSettingsProvider);
  return ref
      .watch(calendarImportServiceProvider)
      .loadStatus(syncEnabled: settings.calendarSyncEnabled);
});

final localDataRevisionProvider =
    NotifierProvider<LocalDataRevisionController, int>(
      LocalDataRevisionController.new,
    );

enum LocalDataInitializationRecoveryReason {
  missingKeyForExistingDatabase,
  encryptedDataUnavailable,
  corruptedDatabase,
  unknown,
}

class LocalDataInitializationRecoveryRequiredException implements Exception {
  const LocalDataInitializationRecoveryRequiredException({
    required this.reason,
    required this.title,
    required this.message,
    required this.lossDescription,
    this.details,
  });

  factory LocalDataInitializationRecoveryRequiredException.fromEncryptionError(
    DatabaseEncryptionResetRequiredException error,
  ) {
    return switch (error.reason) {
      DatabaseEncryptionFailureReason.missingMasterKey =>
        const LocalDataInitializationRecoveryRequiredException(
          reason:
              LocalDataInitializationRecoveryReason.encryptedDataUnavailable,
          title: '기존 로컬 데이터를 복구할 수 없습니다',
          message:
              '암호화 키를 찾지 못해 기기에 남아 있던 기록을 읽을 수 없습니다. 새로 시작할 수 있도록 로컬 데이터를 초기화해 주세요.',
          lossDescription: '기기에 저장된 기록, 검색 인덱스, 가져오기 이력, 앱 설정이 삭제됩니다.',
        ),
      DatabaseEncryptionFailureReason.invalidMasterKey =>
        const LocalDataInitializationRecoveryRequiredException(
          reason: LocalDataInitializationRecoveryReason.corruptedDatabase,
          title: '로컬 데이터가 손상되었습니다',
          message:
              '저장된 암호화 키 또는 데이터 상태가 맞지 않아 기존 기록을 열 수 없습니다. 초기화 후 새로 시작할 수 있습니다.',
          lossDescription: '기기에 저장된 기록, 검색 인덱스, 가져오기 이력, 앱 설정이 삭제됩니다.',
        ),
    };
  }

  const LocalDataInitializationRecoveryRequiredException.missingKeyForExistingDatabase()
    : reason =
          LocalDataInitializationRecoveryReason.missingKeyForExistingDatabase,
      title = '기존 로컬 데이터를 복구할 수 없습니다',
      message = '앱을 다시 설치하는 동안 암호화 키가 사라져 기존 로컬 데이터를 읽을 수 없습니다. 새로 시작하시겠습니까?',
      lossDescription = '기기에 남아 있던 기록, 검색 인덱스, 가져오기 이력, 앱 설정이 삭제됩니다.',
      details = null;

  factory LocalDataInitializationRecoveryRequiredException.corruptedDatabase({
    String? details,
  }) {
    return LocalDataInitializationRecoveryRequiredException(
      reason: LocalDataInitializationRecoveryReason.corruptedDatabase,
      title: '로컬 저장소를 다시 준비해야 합니다',
      message: '데이터베이스 파일이 손상되었거나 이전 초기화가 중간에 멈췄습니다. 초기화 후 다시 시작할 수 있습니다.',
      lossDescription: '기기에 저장된 기록, 검색 인덱스, 가져오기 이력, 앱 설정이 삭제됩니다.',
      details: details,
    );
  }

  factory LocalDataInitializationRecoveryRequiredException.unknown({
    String? details,
  }) {
    return LocalDataInitializationRecoveryRequiredException(
      reason: LocalDataInitializationRecoveryReason.unknown,
      title: '앱을 바로 열 수 없습니다',
      message: '로컬 데이터를 준비하는 중 문제가 발생했습니다. 다시 시도하거나 초기화 후 새로 시작할 수 있습니다.',
      lossDescription: '초기화를 선택하면 기기에 저장된 기록, 검색 인덱스, 가져오기 이력, 앱 설정이 삭제됩니다.',
      details: details,
    );
  }

  final LocalDataInitializationRecoveryReason reason;
  final String title;
  final String message;
  final String lossDescription;
  final String? details;

  @override
  String toString() => '$title: $message';
}

final localDataStatsProvider = FutureProvider<LocalDataStats>((ref) async {
  ref.watch(localDataRevisionProvider);
  return ref.watch(lifeRecordStoreProvider).loadStats();
});

final localLifeRecordsProvider = FutureProvider<List<LifeRecord>>((ref) async {
  ref.watch(localDataRevisionProvider);
  return ref.watch(lifeRecordStoreProvider).loadRecords();
});

final localDataInitializationProvider = FutureProvider<void>((ref) async {
  ref.watch(localDataRevisionProvider);
  final databaseEncryption = ref.watch(databaseEncryptionProvider);
  final vectorDb = ref.watch(vectorDbProvider);

  try {
    if (!await vectorDb.hasPersistedDatabaseFile()) {
      await databaseEncryption.ensureMasterKey();
    }
    await ref.watch(lifeRecordStoreProvider).initialize();
    await databaseEncryption.ensureMasterKey();
  } on DatabaseEncryptionResetRequiredException catch (error) {
    throw LocalDataInitializationRecoveryRequiredException.fromEncryptionError(
      error,
    );
  } on DatabaseException catch (error) {
    throw LocalDataInitializationRecoveryRequiredException.corruptedDatabase(
      details: error.toString(),
    );
  } on FormatException catch (error) {
    throw LocalDataInitializationRecoveryRequiredException.corruptedDatabase(
      details: error.toString(),
    );
  } catch (error) {
    throw LocalDataInitializationRecoveryRequiredException.unknown(
      details: error.toString(),
    );
  }
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
    recordStore: ref.watch(lifeRecordStoreProvider),
  );
});

final curationRepositoryProvider = Provider<CurationRepository>((ref) {
  final settings = ref.watch(appSettingsProvider);
  if (settings.runtimeMode == CurationRuntimeMode.remote) {
    return ref.watch(remoteCurationRepositoryProvider);
  }

  return ref.watch(onDeviceCurationRepositoryProvider);
});

final requestCurationUseCaseProvider = Provider<RequestCurationUseCase>((ref) {
  return RequestCurationUseCase(ref.watch(curationRepositoryProvider));
});

final recentConversationsProvider =
    NotifierProvider<RecentConversationsController, List<RecentConversation>>(
      RecentConversationsController.new,
    );

class LocalDataRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state += 1;
  }
}
