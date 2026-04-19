import 'dart:io';

import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/core/security/database_encryption.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tempDirectory = await Directory.systemTemp.createTemp('curator-app-init-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'fresh install initializes local storage without storing first_run_version before onboarding',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final harness = _ProviderHarness(
        databasePath: path.join(tempDirectory.path, 'fresh.db'),
        preferences: preferences,
        secureKeyStore: InMemorySecureKeyStore(),
      );

      final container = harness.createContainer();
      addTearDown(container.dispose);

      await container.read(localDataInitializationProvider.future);

      expect(preferences.getString('app.first_run_version'), isNull);
      expect(await harness.encryption.hasMasterKey(), isTrue);
      expect(container.read(appSettingsProvider).onboardingCompleted, isFalse);
    },
  );

  test(
    'persisted unencrypted database without key initializes and recreates the key',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final secureKeyStore = InMemorySecureKeyStore();
      final firstHarness = _ProviderHarness(
        databasePath: path.join(tempDirectory.path, 'stale.db'),
        preferences: preferences,
        secureKeyStore: secureKeyStore,
      );

      final firstContainer = firstHarness.createContainer();
      await firstContainer.read(localDataInitializationProvider.future);
      expect(await firstHarness.vectorDb.hasPersistedDatabaseFile(), isTrue);
      expect(await firstHarness.encryption.hasMasterKey(), isTrue);

      await firstHarness.encryption.deleteMasterKey();
      expect(await firstHarness.encryption.hasMasterKey(), isFalse);
      firstContainer.dispose();

      final secondHarness = _ProviderHarness(
        databasePath: path.join(tempDirectory.path, 'stale.db'),
        preferences: preferences,
        secureKeyStore: secureKeyStore,
      );
      final secondContainer = secondHarness.createContainer();
      addTearDown(secondContainer.dispose);

      await secondContainer.read(localDataInitializationProvider.future);

      expect(await secondHarness.encryption.hasMasterKey(), isTrue);
      expect(preferences.getString('app.first_run_version'), isNull);
    },
  );

  testWidgets('unknown initialization errors show retry only', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(_buildInfo),
          localDataInitializationProvider.overrideWith((ref) async {
            throw StateError('unexpected init failure');
          }),
        ],
        child: const CuratorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('앱을 바로 열 수 없습니다'), findsOneWidget);
    expect(find.byKey(const Key('localDataRetryOnlyButton')), findsOneWidget);
    expect(find.byKey(const Key('localDataRecoveryResetButton')), findsNothing);
  });

  testWidgets('successful shell render lazily stores first_run_version', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(_buildInfo),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
          localDataInitializationProvider.overrideWith((ref) async {}),
          localDataStatsProvider.overrideWith(
            (ref) => const LocalDataStats(
              recordCount: 0,
              databaseSizeBytes: 0,
              sourceCounts: <String, int>{},
            ),
          ),
          localLifeRecordsProvider.overrideWith(
            (ref) async => const <LifeRecord>[],
          ),
        ],
        child: const CuratorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('openSettingsButton')), findsOneWidget);
    expect(preferences.getString('app.first_run_version'), '1.5.0+15');
  });
}

class _ProviderHarness {
  _ProviderHarness({
    required String databasePath,
    required this.preferences,
    required SecureKeyStore secureKeyStore,
  }) {
    encryption = createTestDatabaseEncryption(
      appNamespace: 'curator.test.app',
      secureKeyStore: secureKeyStore,
    );
    vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: encryption,
    );
    store = LifeRecordStore(
      vectorDb: vectorDb,
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(4).toList(),
      sharedPreferences: preferences,
    );
  }

  final SharedPreferences preferences;
  late final DatabaseEncryption encryption;
  late final VectorDb vectorDb;
  late final LifeRecordStore store;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appBuildInfoProvider.overrideWithValue(
          const AppBuildInfo(
            appName: '큐레이터',
            packageName: 'curator_mobile',
            version: '1.5.0',
            buildNumber: '15',
          ),
        ),
        databaseEncryptionProvider.overrideWithValue(encryption),
        vectorDbProvider.overrideWithValue(vectorDb),
        lifeRecordStoreProvider.overrideWithValue(store),
      ],
    );
  }
}

const AppBuildInfo _buildInfo = AppBuildInfo(
  appName: '큐레이터',
  packageName: 'curator_mobile',
  version: '1.5.0',
  buildNumber: '15',
);

class _FakeOnDeviceLlmBridge implements OnDeviceLlmBridge {
  const _FakeOnDeviceLlmBridge();

  @override
  Future<List<double>> embed(String text) async => <double>[0.1, 0.2, 0.3];

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    return '테스트 응답';
  }

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    return const OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'template-fallback',
      message: '테스트 폴백',
      platform: 'flutter-test',
      llmModelConfigured: false,
      embedderModelConfigured: false,
      llmModelAvailable: false,
      embedderModelAvailable: false,
      fallbackActive: true,
    );
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async => prepare();
}
