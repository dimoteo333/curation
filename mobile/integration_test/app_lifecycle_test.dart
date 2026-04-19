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
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/fakes/fake_curation_repository.dart';
import '../test/test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tempDirectory = await Directory.systemTemp.createTemp('curator-lifecycle-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('fresh install은 온보딩 후 메인 앱으로 진입한다', (WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    final harness = _AppHarness(
      databasePath: path.join(tempDirectory.path, 'fresh.db'),
      preferences: preferences,
      secureKeyStore: InMemorySecureKeyStore(),
    );

    await tester.pumpWidget(harness.buildApp());
    await _pumpUntilFound(tester, find.text('큐레이터 시작하기'));

    expect(preferences.getString('app.first_run_version'), isNull);

    await tester.tap(find.byKey(const Key('onboardingSkipButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('completeOnboardingButton')));
    await _pumpUntilFound(tester, find.byKey(const Key('homeEmptyStateCard')));

    expect(find.byKey(const Key('homeEmptyStateCard')), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('질문'), findsOneWidget);
    expect(find.text('타임라인'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(preferences.getString('app.first_run_version'), '1.5.0+15');
  });

  testWidgets('app restart는 온보딩을 반복하지 않고 바로 메인 앱으로 간다', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('app.first_run_version', '1.5.0+15');
    await preferences.setBool('app.onboarding_completed', true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(_buildInfo),
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
          curationRepositoryProvider.overrideWithValue(
            FakeCurationRepository(),
          ),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
        ],
        child: const CuratorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('큐레이터 시작하기'), findsNothing);
    expect(find.byKey(const Key('openSettingsButton')), findsOneWidget);
  });

  testWidgets('data reset는 복구 화면 뒤에 fresh state로 돌아간다', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app.onboarding_completed', true);
    var shouldRecover = true;
    final resetStore = _ResettableLifeRecordStore(
      databasePath: path.join(tempDirectory.path, 'reset.db'),
      preferences: preferences,
      onReset: () async {
        shouldRecover = false;
        await preferences.clear();
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(_buildInfo),
          lifeRecordStoreProvider.overrideWithValue(resetStore),
          localDataInitializationProvider.overrideWith((ref) async {
            if (shouldRecover) {
              throw const LocalDataInitializationRecoveryRequiredException.missingKeyForExistingDatabase();
            }
          }),
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
          curationRepositoryProvider.overrideWithValue(
            FakeCurationRepository(),
          ),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
        ],
        child: const CuratorApp(),
      ),
    );
    await _pumpUntilFound(tester, find.text('기존 로컬 데이터를 복구할 수 없습니다'));

    expect(
      find.byKey(const Key('localDataRecoveryResetButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('localDataRecoveryResetButton')));
    await _pumpUntilFound(tester, find.text('큐레이터 시작하기'));

    expect(find.text('큐레이터 시작하기'), findsOneWidget);
    expect(preferences.getBool('app.onboarding_completed'), isNot(isTrue));
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure(
    'Timed out waiting for ${finder.describeMatch(Plurality.many)}.',
  );
}

class _AppHarness {
  _AppHarness({
    required String databasePath,
    required this.preferences,
    required SecureKeyStore secureKeyStore,
  }) {
    encryption = createTestDatabaseEncryption(
      appNamespace: 'curator.test.integration',
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

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appBuildInfoProvider.overrideWithValue(_buildInfo),
        databaseEncryptionProvider.overrideWithValue(encryption),
        vectorDbProvider.overrideWithValue(vectorDb),
        lifeRecordStoreProvider.overrideWithValue(store),
        curationRepositoryProvider.overrideWithValue(FakeCurationRepository()),
        onDeviceLlmBridgeProvider.overrideWithValue(
          const _FakeOnDeviceLlmBridge(),
        ),
      ],
      child: const CuratorApp(),
    );
  }
}

class _ResettableLifeRecordStore extends LifeRecordStore {
  _ResettableLifeRecordStore({
    required String databasePath,
    required SharedPreferences preferences,
    required this.onReset,
  }) : super(
         vectorDb: VectorDb(
           databaseFactory: databaseFactoryFfi,
           databasePathResolver: () async => databasePath,
           databaseEncryption: createTestDatabaseEncryption(
             appNamespace: 'curator.test.integration.reset',
           ),
         ),
         databaseEncryption: createTestDatabaseEncryption(
           appNamespace: 'curator.test.integration.reset',
         ),
         embeddingService: const SemanticEmbeddingService(),
         seedRecords: const <LifeRecord>[],
         sharedPreferences: preferences,
       );

  final Future<void> Function() onReset;

  @override
  Future<void> deleteAllData() async {
    await onReset();
  }

  @override
  Future<void> initialize() async {}
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
