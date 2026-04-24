import 'dart:io';

import 'package:curator_mobile/src/data/import/calendar_import_service.dart';
import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
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
    tempDirectory = await Directory.systemTemp.createTemp(
      'curator-calendar-import-',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('캘린더 이벤트를 LifeRecord로 변환한다', () async {
    final service = await _createService(
      gateway: _FakeDeviceCalendarGateway(
        calendars: const <DeviceCalendarSource>[
          DeviceCalendarSource(id: 'cal-1', name: '개인'),
        ],
        events: const <CalendarImportEvent>[],
      ),
      databasePath: path.join(tempDirectory.path, 'calendar.db'),
    );

    final record = await service.toLifeRecord(
      CalendarImportEvent(
        calendarId: 'cal-1',
        calendarName: '개인',
        eventId: 'evt-1',
        title: '엄마와 점심',
        description: '오랜만에 점심 약속',
        location: '합정',
        startTime: DateTime(2026, 4, 15, 12, 30),
        endTime: DateTime(2026, 4, 15, 13, 30),
      ),
    );

    expect(record.sourceId, 'evt-1');
    expect(record.source, '캘린더');
    expect(record.importSource, 'calendar');
    expect(record.title, '엄마와 점심');
    expect(record.content, '오랜만에 점심 약속');
    expect(record.createdAt, DateTime(2026, 4, 15, 12, 30));
    expect(record.metadata['calendar_id'], 'cal-1');
    expect(record.metadata['event_id'], 'evt-1');
    expect(record.metadata['location'], '합정');
    expect(record.tags, isNotEmpty);
  });

  test('캘린더 sync는 eventId 기준으로 중복을 합치고 history를 남긴다', () async {
    final service = await _createService(
      gateway: _FakeDeviceCalendarGateway(
        calendars: const <DeviceCalendarSource>[
          DeviceCalendarSource(id: 'cal-1', name: '개인'),
          DeviceCalendarSource(id: 'cal-2', name: '업무'),
        ],
        events: <CalendarImportEvent>[
          CalendarImportEvent(
            calendarId: 'cal-1',
            calendarName: '개인',
            eventId: 'evt-1',
            title: '반복 운동',
            startTime: DateTime(2026, 4, 10, 7, 0),
            endTime: DateTime(2026, 4, 10, 8, 0),
          ),
          CalendarImportEvent(
            calendarId: 'cal-1',
            calendarName: '개인',
            eventId: 'evt-1',
            title: '반복 운동',
            startTime: DateTime(2026, 4, 12, 7, 0),
            endTime: DateTime(2026, 4, 12, 8, 0),
          ),
          CalendarImportEvent(
            calendarId: 'cal-2',
            calendarName: '업무',
            eventId: 'evt-2',
            title: '주간 회고',
            startTime: DateTime(2026, 4, 13, 18, 0),
            endTime: DateTime(2026, 4, 13, 19, 0),
          ),
        ],
      ),
      databasePath: path.join(tempDirectory.path, 'calendar.db'),
      nowProvider: () => DateTime(2026, 4, 17, 9),
    );

    final result = await service.syncRecentEvents();

    expect(result.importedCount, 2);
    expect(result.scannedCount, 3);

    final snapshot = await service.importHistoryService.loadSnapshot();
    expect(snapshot.countForSource('calendar'), 2);
    expect(snapshot.lastCalendarSyncAt, DateTime(2026, 4, 17, 9));

    final stats = await service.recordStore.loadStats();
    expect(stats.recordCount, 2);
    expect(stats.sourceCounts['calendar'], 2);
  });

  test('제외된 캘린더 소스의 이벤트는 가져오지 않는다', () async {
    final service = await _createService(
      gateway: _FakeDeviceCalendarGateway(
        calendars: const <DeviceCalendarSource>[
          DeviceCalendarSource(id: 'cal-1', name: '개인'),
          DeviceCalendarSource(id: 'cal-2', name: '업무'),
        ],
        events: <CalendarImportEvent>[
          CalendarImportEvent(
            calendarId: 'cal-1',
            calendarName: '개인',
            eventId: 'evt-1',
            title: '개인 일정',
            startTime: DateTime(2026, 4, 10, 7, 0),
            endTime: DateTime(2026, 4, 10, 8, 0),
          ),
          CalendarImportEvent(
            calendarId: 'cal-2',
            calendarName: '업무',
            eventId: 'evt-2',
            title: '업무 일정',
            startTime: DateTime(2026, 4, 11, 9, 0),
            endTime: DateTime(2026, 4, 11, 10, 0),
          ),
        ],
      ),
      databasePath: path.join(tempDirectory.path, 'calendar-filtered.db'),
      nowProvider: () => DateTime(2026, 4, 17, 9),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('app.excluded_calendar_ids', <String>[
      'cal-2',
    ]);

    final result = await service.syncRecentEvents();

    expect(result.scannedCount, 1);
    expect(result.importedCount, 1);

    final records = await service.recordStore.loadRecords();
    expect(records, hasLength(1));
    expect(records.single.metadata['calendar_id'], 'cal-1');
  });
}

Future<CalendarImportService> _createService({
  required DeviceCalendarGateway gateway,
  required String databasePath,
  DateTime Function()? nowProvider,
}) async {
  final encryption = createTestDatabaseEncryption();
  final vectorDb = VectorDb(
    databaseFactory: databaseFactoryFfi,
    databasePathResolver: () async => databasePath,
    databaseEncryption: encryption,
  );
  final preferences = await SharedPreferences.getInstance();
  return CalendarImportService(
    recordStore: LifeRecordStore(
      vectorDb: vectorDb,
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: const [],
      sharedPreferences: preferences,
    ),
    importHistoryService: ImportHistoryService(sharedPreferences: preferences),
    calendarGateway: gateway,
    sharedPreferences: preferences,
    nowProvider: nowProvider,
  );
}

class _FakeDeviceCalendarGateway implements DeviceCalendarGateway {
  const _FakeDeviceCalendarGateway({
    required this.calendars,
    required this.events,
  });

  final List<DeviceCalendarSource> calendars;
  final List<CalendarImportEvent> events;

  @override
  Future<List<DeviceCalendarSource>> listAvailableCalendars() async {
    return calendars;
  }

  @override
  Future<List<CalendarImportEvent>> listEvents({
    required DateTime start,
    required DateTime end,
    required List<DeviceCalendarSource> calendars,
  }) async {
    final allowedIds = calendars.map((calendar) => calendar.id).toSet();
    return events
        .where((event) => allowedIds.contains(event.calendarId))
        .toList(growable: false);
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<CalendarImportPermissionStatus> permissionStatus() async {
    return CalendarImportPermissionStatus.granted;
  }

  @override
  Future<CalendarImportPermissionStatus> requestPermission() async {
    return CalendarImportPermissionStatus.granted;
  }
}
