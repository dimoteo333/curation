import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/core/security/database_encryption.dart';
import 'package:curator_mobile/src/data/import/calendar_import_service.dart';
import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/services/text_embedding_service.dart';
import 'package:curator_mobile/src/presentation/screens/settings_screen.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:curator_mobile/src/theme/curator_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
    });
  });

  testWidgets('설정 화면은 런타임, 데이터 상태, import 액션을 노출한다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final preferences = await SharedPreferences.getInstance();
    _FakeLifeRecordStore._prefs = preferences;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(
            const AppBuildInfo(
              appName: '큐레이터',
              packageName: 'curator_mobile',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
          localDataStatsProvider.overrideWith(
            (ref) => const LocalDataStats(
              recordCount: 5,
              databaseSizeBytes: 2048,
              sourceCounts: <String, int>{'file': 2, 'calendar': 1, 'diary': 2},
            ),
          ),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
          deviceCalendarGatewayProvider.overrideWithValue(
            const _FakeDeviceCalendarGateway(),
          ),
          lifeRecordStoreProvider.overrideWithValue(_FakeLifeRecordStore()),
          importHistoryServiceProvider.overrideWithValue(
            _FakeImportHistoryService(preferences),
          ),
        ],
        child: MaterialApp(
          theme: buildCuratorTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Core sections are visible
    expect(find.text('사용 방식'), findsOneWidget);
    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('데이터'), findsOneWidget);

    // Developer runtime section exists but LLM fields are hidden
    expect(find.text('데모 데이터 로드'), findsNothing);
    expect(find.byKey(const Key('developerRuntimeSection')), findsOneWidget);
    expect(find.byKey(const Key('llmModelPathField')), findsNothing);

    // Runtime mode toggle
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(preferences.getString('app.runtime_mode'), 'remote');

    // Developer toggle reveals LLM / embedder fields
    await tester.ensureVisible(
      find.byKey(const Key('developerRuntimeToggleButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('developerRuntimeToggleButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('llmModelPathField')), findsOneWidget);
    expect(find.byKey(const Key('embedderModelPathField')), findsOneWidget);
  });
}

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeDeviceCalendarGateway implements DeviceCalendarGateway {
  const _FakeDeviceCalendarGateway();

  @override
  Future<List<DeviceCalendarSource>> listAvailableCalendars() async {
    return const <DeviceCalendarSource>[
      DeviceCalendarSource(id: 'personal', name: '개인'),
      DeviceCalendarSource(id: 'work', name: '업무'),
    ];
  }

  @override
  Future<List<CalendarImportEvent>> listEvents({
    required DateTime start,
    required DateTime end,
    required List<DeviceCalendarSource> calendars,
  }) async =>
      const <CalendarImportEvent>[];

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<CalendarImportPermissionStatus> permissionStatus() async =>
      CalendarImportPermissionStatus.granted;

  @override
  Future<CalendarImportPermissionStatus> requestPermission() async =>
      CalendarImportPermissionStatus.granted;
}

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
  }) async =>
      '테스트 응답';

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async =>
      const OnDeviceRuntimeStatus(
        llmReady: true,
        embedderReady: false,
        runtime: 'partial-native',
        message: 'LLM은 준비됐고 임베딩은 폴백입니다.',
        platform: 'flutter-test',
        llmModelConfigured: true,
        embedderModelConfigured: false,
        llmModelAvailable: true,
        embedderModelAvailable: false,
        fallbackActive: true,
      );

  @override
  Future<OnDeviceRuntimeStatus> status() async => prepare();
}

class _FakeLifeRecordStore extends LifeRecordStore {
  static SharedPreferences? _prefs;

  _FakeLifeRecordStore()
      : super(
          vectorDb: _NilVectorDb(),
          databaseEncryption: _NilDatabaseEncryption(),
          embeddingService: _NilTextEmbeddingService(),
          seedRecords: const [],
          sharedPreferences: _prefs!,
        );

  @override
  Future<void> initialize() async {}

  @override
  Future<LocalDataStats> loadStats() async => const LocalDataStats(
        recordCount: 5,
        databaseSizeBytes: 2048,
        sourceCounts: <String, int>{'file': 2, 'calendar': 1, 'diary': 2},
      );

  @override
  Future<void> deleteAllData() async {}

  @override
  Future<void> loadDemoData() async {}

  @override
  Future<List<LifeRecord>> loadRecords() async => const [];
}

class _FakeImportHistoryService extends ImportHistoryService {
  _FakeImportHistoryService(SharedPreferences prefs)
      : super(sharedPreferences: prefs);

  @override
  Future<ImportHistorySnapshot> loadSnapshot() async =>
      const ImportHistorySnapshot(
        recentEntries: [],
        uniqueCountsBySource: {},
      );

  @override
  Future<bool> hasImportedFile({required String contentHash}) async => false;

  @override
  Future<void> recordFileImports(List<FileImportHistoryRecord> records) async {}

  @override
  Future<void> recordCalendarSync({
    required DateTime syncedAt,
    required Iterable<String> sourceIds,
    required int importedCount,
    required int scannedCount,
  }) async {}
}

// ─── Nil instances (satisfy constructors, never actually used) ────────────────

class _NilVectorDb extends VectorDb {
  _NilVectorDb()
      : super(
          databaseFactory: _dummyDatabaseFactory,
          databasePathResolver: () async => '',
          databaseEncryption: _NilDatabaseEncryption(),
        );
}

class _NilDatabaseEncryption extends DatabaseEncryption {
  _NilDatabaseEncryption()
      : super(secureKeyStore: _NilSecureKeyStore(), appNamespace: 'test');
}

class _NilTextEmbeddingService implements TextEmbeddingService {
  @override
  Future<List<double>> embed(String text) async => [0.0];
}

class _NilSecureKeyStore extends SecureKeyStore {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
}

final _dummyDatabaseFactory = _DummyDatabaseFactory();

class _DummyDatabaseFactory implements DatabaseFactory {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
