import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/data/import/calendar_import_service.dart';
import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/domain/entities/curation_query_scope.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/repositories/curation_repository.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/fake_pending_import.dart';

const AppBuildInfo testAppBuildInfo = AppBuildInfo(
  appName: '큐레이터',
  packageName: 'com.curator.mobile',
  version: '0.2.0',
  buildNumber: '42',
);

final List<LifeRecord> testSeedRecords = seededLifeRecords
    .take(4)
    .toList(growable: false);

final SupportingRecord testPrimarySupportingRecord = SupportingRecord(
  id: testSeedRecords.first.id,
  source: testSeedRecords.first.source,
  importSource: testSeedRecords.first.importSource,
  title: testSeedRecords.first.title,
  createdAt: testSeedRecords.first.createdAt,
  excerpt: '야근이 이어진 뒤 산책과 휴식이 회복의 전환점으로 반복됐습니다.',
  relevanceReason: '무기력감 뒤에 회복 패턴이 어떻게 바뀌는지 가장 직접적으로 보여 줍니다.',
  content: testSeedRecords.first.content,
  tags: testSeedRecords.first.tags,
  metadata: testSeedRecords.first.metadata,
);

final CuratedResponse testCuratedResponse = CuratedResponse(
  insightTitle: '무기력은 과로 다음의 회복 패턴과 함께 나타났습니다',
  summary: '최근 기록에서는 야근 이후 무기력감이 커졌고, 산책과 짧은 휴식이 회복을 만들었습니다.',
  answer:
      '최근 기록을 보면 무기력감은 야근이 길어진 직후 가장 크게 나타났습니다. 그 다음에는 한강 산책이나 잠깐의 낮잠처럼 몸의 자극을 낮추는 행동이 회복을 앞당겼습니다.',
  supportingRecords: <SupportingRecord>[testPrimarySupportingRecord],
  suggestedFollowUp: '최근 2주 안에 비슷하게 지쳤던 날의 패턴도 같이 볼까요?',
  runtimeInfo: const CurationRuntimeInfo(
    path: CurationRuntimePath.onDeviceFallback,
    label: '온디바이스 폴백',
    message: '통합 테스트용 응답입니다.',
  ),
);

class FakeCurationRepository implements CurationRepository {
  const FakeCurationRepository(this.response);

  final CuratedResponse response;

  @override
  Future<CuratedResponse> curateQuestion(
    String question, {
    CurationQueryScope scope = CurationQueryScope.all,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return response;
  }
}

Future<SharedPreferences> integrationTestPreferences(
  Map<String, Object> initialValues,
) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return SharedPreferences.getInstance();
}

Future<void> pumpIntegrationTestApp(
  WidgetTester tester, {
  required SharedPreferences preferences,
  List<LifeRecord> localRecords = const <LifeRecord>[],
  CurationRepository? curationRepository,
  Future<void>? initializationFuture,
}) async {
  final pendingImportService = FakePendingSharedImportService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appBuildInfoProvider.overrideWithValue(testAppBuildInfo),
        localDataInitializationProvider.overrideWith(
          (ref) => initializationFuture ?? Future<void>.value(),
        ),
        pendingSharedImportBridgeProvider.overrideWithValue(
          pendingImportService.bridge,
        ),
        pendingSharedImportServiceProvider.overrideWithValue(
          pendingImportService,
        ),
        localDataStatsProvider.overrideWith(
          (ref) => Future<LocalDataStats>.value(_statsFor(localRecords)),
        ),
        localLifeRecordsProvider.overrideWith(
          (ref) => Future<List<LifeRecord>>.value(localRecords),
        ),
        onDeviceRuntimeStatusProvider.overrideWith(
          (ref) => Future<OnDeviceRuntimeStatus>.value(
            const OnDeviceRuntimeStatus(
              llmReady: false,
              embedderReady: false,
              runtime: 'template-fallback',
              message: '통합 테스트에서는 검증용 폴백 상태를 사용합니다.',
              platform: 'integration-test',
              llmModelConfigured: false,
              embedderModelConfigured: false,
              llmModelAvailable: false,
              embedderModelAvailable: false,
              fallbackActive: true,
            ),
          ),
        ),
        calendarSyncStatusProvider.overrideWith(
          (ref) => Future<CalendarSyncStatus>.value(
            const CalendarSyncStatus(
              syncEnabled: true,
              permissionStatus: CalendarImportPermissionStatus.granted,
              importedEventCount: 3,
            ),
          ),
        ),
        availableCalendarSourcesProvider.overrideWith(
          (ref) => Future<List<DeviceCalendarSource>>.value(
            const <DeviceCalendarSource>[
              DeviceCalendarSource(id: 'calendar-1', name: '개인 캘린더'),
            ],
          ),
        ),
        importHistorySnapshotProvider.overrideWith(
          (ref) => Future<ImportHistorySnapshot>.value(
            ImportHistorySnapshot(
              recentEntries: <ImportHistoryEntry>[
                ImportHistoryEntry(
                  importSource: 'calendar',
                  label: '캘린더 동기화',
                  detail: '가져온 일정 3건 / 조회한 일정 5건',
                  importedAt: DateTime(2026, 4, 20, 9, 30),
                  count: 3,
                ),
              ],
              uniqueCountsBySource: const <String, int>{
                'calendar': 3,
                'diary': 2,
                'note': 1,
              },
              lastCalendarSyncAt: DateTime(2026, 4, 20, 9, 30),
            ),
          ),
        ),
        if (curationRepository != null)
          curationRepositoryProvider.overrideWithValue(curationRepository),
      ],
      child: const CuratorApp(),
    ),
  );
}

Future<void> pumpUntilFound(
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

  throw TestFailure('Timed out waiting for $finder.');
}

Future<void> dismissActiveInput(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

LocalDataStats _statsFor(List<LifeRecord> records) {
  final sourceCounts = <String, int>{};
  for (final record in records) {
    sourceCounts.update(
      record.importSource,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  return LocalDataStats(
    recordCount: records.length,
    databaseSizeBytes: records.isEmpty ? 0 : records.length * 1024,
    sourceCounts: sourceCounts,
  );
}
