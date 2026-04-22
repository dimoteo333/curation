import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/security/input_sanitizer.dart';
import '../../domain/entities/life_record.dart';
import '../local/life_record_store.dart';
import '../ondevice/semantic_embedding_service.dart';
import 'import_history_service.dart';

enum CalendarImportPermissionStatus {
  granted,
  denied,
  writeOnly,
  restricted,
  notDetermined,
}

class CalendarImportEvent {
  const CalendarImportEvent({
    required this.calendarId,
    required this.calendarName,
    required this.eventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.isAllDay = false,
    this.timeZone,
  });

  final String calendarId;
  final String calendarName;
  final String eventId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? timeZone;
}

class CalendarSyncStatus {
  const CalendarSyncStatus({
    required this.syncEnabled,
    required this.permissionStatus,
    required this.importedEventCount,
    this.lastSyncedAt,
  });

  final bool syncEnabled;
  final CalendarImportPermissionStatus permissionStatus;
  final DateTime? lastSyncedAt;
  final int importedEventCount;

  bool get hasPermission =>
      permissionStatus == CalendarImportPermissionStatus.granted;
}

class CalendarImportResult {
  const CalendarImportResult({
    required this.permissionStatus,
    required this.scannedCount,
    required this.importedCount,
    required this.lastSyncedAt,
  });

  final CalendarImportPermissionStatus permissionStatus;
  final int scannedCount;
  final int importedCount;
  final DateTime? lastSyncedAt;

  bool get hasImportedRecords => importedCount > 0;
}

/// Platform calendar boundary used by the import service and tests.
abstract class DeviceCalendarGateway {
  Future<CalendarImportPermissionStatus> permissionStatus();

  Future<CalendarImportPermissionStatus> requestPermission();

  Future<void> openAppSettings();

  Future<List<CalendarImportEvent>> listEvents({
    required DateTime start,
    required DateTime end,
  });
}

/// Calendar gateway backed by `device_calendar_plus`.
class PluginDeviceCalendarGateway implements DeviceCalendarGateway {
  PluginDeviceCalendarGateway({DeviceCalendar? plugin})
    : _plugin = plugin ?? DeviceCalendar.instance;

  final DeviceCalendar _plugin;

  @override
  Future<List<CalendarImportEvent>> listEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final List<Calendar> calendars;
    try {
      calendars = await _plugin.listCalendars();
    } on MissingPluginException {
      return const <CalendarImportEvent>[];
    } on PlatformException {
      return const <CalendarImportEvent>[];
    }
    final visibleCalendars = calendars.where((calendar) => !calendar.hidden);
    final calendarNameById = <String, String>{
      for (final calendar in visibleCalendars) calendar.id: calendar.name,
    };
    if (calendarNameById.isEmpty) {
      return const <CalendarImportEvent>[];
    }

    final List<Event> events;
    try {
      events = await _plugin.listEvents(
        start,
        end,
        calendarIds: calendarNameById.keys.toList(growable: false),
      );
    } on MissingPluginException {
      return const <CalendarImportEvent>[];
    } on PlatformException {
      return const <CalendarImportEvent>[];
    }
    return events
        .map(
          (event) => CalendarImportEvent(
            calendarId: event.calendarId,
            calendarName: calendarNameById[event.calendarId] ?? '기기 캘린더',
            eventId: event.eventId,
            title: event.title,
            description: event.description,
            location: event.location,
            startTime: event.startDate,
            endTime: event.endDate,
            isAllDay: event.isAllDay,
            timeZone: event.timeZone,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> openAppSettings() {
    return _plugin.openAppSettings();
  }

  @override
  Future<CalendarImportPermissionStatus> permissionStatus() async {
    try {
      return _mapPermissionStatus(await _plugin.hasPermissions());
    } on MissingPluginException {
      return CalendarImportPermissionStatus.restricted;
    } on PlatformException {
      return CalendarImportPermissionStatus.restricted;
    }
  }

  @override
  Future<CalendarImportPermissionStatus> requestPermission() async {
    try {
      return _mapPermissionStatus(await _plugin.requestPermissions());
    } on MissingPluginException {
      return CalendarImportPermissionStatus.restricted;
    } on PlatformException {
      return CalendarImportPermissionStatus.restricted;
    }
  }

  CalendarImportPermissionStatus _mapPermissionStatus(
    CalendarPermissionStatus status,
  ) {
    return switch (status) {
      CalendarPermissionStatus.granted =>
        CalendarImportPermissionStatus.granted,
      CalendarPermissionStatus.writeOnly =>
        CalendarImportPermissionStatus.writeOnly,
      CalendarPermissionStatus.restricted =>
        CalendarImportPermissionStatus.restricted,
      CalendarPermissionStatus.notDetermined =>
        CalendarImportPermissionStatus.notDetermined,
      CalendarPermissionStatus.denied => CalendarImportPermissionStatus.denied,
    };
  }
}

/// Imports recent device calendar events into the local life-record store.
class CalendarImportService {
  CalendarImportService({
    required this.recordStore,
    required this.importHistoryService,
    required this.calendarGateway,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final LifeRecordStore recordStore;
  final ImportHistoryService importHistoryService;
  final DeviceCalendarGateway calendarGateway;
  final DateTime Function() _nowProvider;

  Future<CalendarSyncStatus> loadStatus({required bool syncEnabled}) async {
    final historySnapshot = await importHistoryService.loadSnapshot();
    return CalendarSyncStatus(
      syncEnabled: syncEnabled,
      permissionStatus: await calendarGateway.permissionStatus(),
      lastSyncedAt: historySnapshot.lastCalendarSyncAt,
      importedEventCount: historySnapshot.countForSource('calendar'),
    );
  }

  Future<CalendarImportPermissionStatus> requestPermission() {
    return calendarGateway.requestPermission();
  }

  Future<void> openAppSettings() {
    return calendarGateway.openAppSettings();
  }

  Future<CalendarImportResult> syncRecentEvents({int pastDays = 30}) async {
    final permissionStatus = await calendarGateway.requestPermission();
    if (permissionStatus != CalendarImportPermissionStatus.granted) {
      return CalendarImportResult(
        permissionStatus: permissionStatus,
        scannedCount: 0,
        importedCount: 0,
        lastSyncedAt: null,
      );
    }

    final now = _nowProvider();
    final rawEvents = await calendarGateway.listEvents(
      start: now.subtract(Duration(days: pastDays)),
      end: now,
    );
    final dedupedEvents = _dedupeEvents(rawEvents);
    final records = dedupedEvents.map(toLifeRecord).toList(growable: false);

    if (records.isNotEmpty) {
      await recordStore.importRecords(records);
    }
    await importHistoryService.recordCalendarSync(
      syncedAt: now,
      sourceIds: records.map((record) => record.sourceId),
      importedCount: records.length,
      scannedCount: rawEvents.length,
    );

    return CalendarImportResult(
      permissionStatus: permissionStatus,
      scannedCount: rawEvents.length,
      importedCount: records.length,
      lastSyncedAt: now,
    );
  }

  @visibleForTesting
  LifeRecord toLifeRecord(CalendarImportEvent event) {
    final normalizedTitle = _normalizeTitle(event.title);
    final normalizedDescription = _normalizeDescription(event.description);
    final fallbackContent = _buildFallbackContent(
      title: normalizedTitle,
      startTime: event.startTime,
      endTime: event.endTime,
      isAllDay: event.isAllDay,
    );
    final content = normalizedDescription ?? fallbackContent;
    final tags = _extractTags(event, normalizedTitle, content);
    final location = _normalizeMetadataValue(event.location);

    return LifeRecord(
      id: 'calendar-${event.eventId}',
      sourceId: event.eventId,
      source: '캘린더',
      importSource: 'calendar',
      title: normalizedTitle,
      content: content,
      createdAt: event.startTime,
      tags: tags,
      metadata: <String, dynamic>{
        'calendar_id': event.calendarId,
        'calendar_name': event.calendarName,
        'event_id': event.eventId,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
        'location': location,
        'is_all_day': event.isAllDay,
        'time_zone': event.timeZone,
      },
    );
  }

  List<CalendarImportEvent> _dedupeEvents(List<CalendarImportEvent> events) {
    final eventsById = <String, CalendarImportEvent>{};
    for (final event in events) {
      final existing = eventsById[event.eventId];
      if (existing == null || event.startTime.isAfter(existing.startTime)) {
        eventsById[event.eventId] = event;
      }
    }
    return eventsById.values.toList(growable: false);
  }

  String _normalizeTitle(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) {
      return '제목 없는 일정';
    }
    try {
      return InputSanitizer.sanitizeTitle(trimmed);
    } on InputValidationException {
      return '제목 없는 일정';
    }
  }

  String? _normalizeDescription(String? rawDescription) {
    final trimmed = rawDescription?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return InputSanitizer.sanitizeContent(trimmed);
    } on InputValidationException {
      return null;
    }
  }

  String? _normalizeMetadataValue(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _extractTags(
    CalendarImportEvent event,
    String title,
    String content,
  ) {
    final tagSeed = <String>[
      title,
      if (event.calendarName.trim().isNotEmpty) event.calendarName.trim(),
      content,
    ].join(' ');
    return SemanticEmbeddingService.suggestTags(tagSeed, maxTags: 6);
  }

  String _buildFallbackContent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required bool isAllDay,
  }) {
    final timeRange = isAllDay
        ? '${_formatDate(startTime)} 종일'
        : '${_formatDateTime(startTime)} ~ ${_formatDateTime(endTime)}';
    return '일정: $title ($timeRange)';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_formatDate(value)} $hour:$minute';
  }
}
