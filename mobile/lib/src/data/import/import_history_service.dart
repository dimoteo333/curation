import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ImportHistoryEntry {
  const ImportHistoryEntry({
    required this.importSource,
    required this.label,
    required this.importedAt,
    this.detail,
    this.count,
  });

  final String importSource;
  final String label;
  final String? detail;
  final DateTime importedAt;
  final int? count;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'import_source': importSource,
      'label': label,
      'detail': detail,
      'imported_at': importedAt.toIso8601String(),
      'count': count,
    };
  }

  factory ImportHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ImportHistoryEntry(
      importSource: json['import_source'] as String? ?? 'unknown',
      label: json['label'] as String? ?? '',
      detail: json['detail'] as String?,
      importedAt:
          DateTime.tryParse(json['imported_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      count: (json['count'] as num?)?.toInt(),
    );
  }
}

class FileImportHistoryRecord {
  const FileImportHistoryRecord({
    required this.contentHash,
    required this.fileName,
    required this.sourceId,
    required this.importedAt,
  });

  final String contentHash;
  final String fileName;
  final String sourceId;
  final DateTime importedAt;
}

class ImportHistorySnapshot {
  const ImportHistorySnapshot({
    required this.recentEntries,
    required this.uniqueCountsBySource,
    this.lastCalendarSyncAt,
  });

  final List<ImportHistoryEntry> recentEntries;
  final Map<String, int> uniqueCountsBySource;
  final DateTime? lastCalendarSyncAt;

  int countForSource(String importSource) {
    return uniqueCountsBySource[importSource] ?? 0;
  }
}

class ImportHistoryService {
  ImportHistoryService({required this.sharedPreferences});

  static const String _entriesKey = 'import_history.entries';
  static const String _sourceIndexKey = 'import_history.source_index';
  static const String _fileIndexKey = 'import_history.file_index';
  static const String _calendarLastSyncKey =
      'import_history.calendar.last_sync';
  static const int _maxRecentEntries = 12;

  final SharedPreferences sharedPreferences;

  Future<ImportHistorySnapshot> loadSnapshot() async {
    final sourceIndex = _loadSourceIndex();
    return ImportHistorySnapshot(
      recentEntries: _loadEntries(),
      uniqueCountsBySource: <String, int>{
        for (final entry in sourceIndex.entries) entry.key: entry.value.length,
      },
      lastCalendarSyncAt: _loadCalendarLastSyncAt(),
    );
  }

  Future<bool> hasImportedFile({required String contentHash}) async {
    final fileIndex = _loadFileIndex();
    return fileIndex.containsKey(contentHash);
  }

  Future<void> recordFileImports(List<FileImportHistoryRecord> records) async {
    if (records.isEmpty) {
      return;
    }

    final fileIndex = _loadFileIndex();
    final sourceIndex = _loadSourceIndex();
    final recentEntries = _loadEntries();

    for (final record in records) {
      fileIndex[record.contentHash] = <String, String>{
        'content_hash': record.contentHash,
        'imported_at': record.importedAt.toIso8601String(),
        'source_id': record.sourceId,
        'file_name': record.fileName,
      };
      sourceIndex.putIfAbsent(
        'file',
        () => <String, String>{},
      )[record.sourceId] = record.importedAt
          .toIso8601String();
      recentEntries.insert(
        0,
        ImportHistoryEntry(
          importSource: 'file',
          label: record.fileName,
          detail: '파일 가져오기',
          importedAt: record.importedAt,
        ),
      );
    }

    await _persist(
      recentEntries: recentEntries,
      sourceIndex: sourceIndex,
      fileIndex: fileIndex,
    );
  }

  Future<void> recordCalendarSync({
    required DateTime syncedAt,
    required Iterable<String> sourceIds,
    required int importedCount,
    required int scannedCount,
  }) async {
    final sourceIndex = _loadSourceIndex();
    final calendarIndex = sourceIndex.putIfAbsent(
      'calendar',
      () => <String, String>{},
    );
    for (final sourceId in sourceIds) {
      calendarIndex[sourceId] = syncedAt.toIso8601String();
    }

    final recentEntries = _loadEntries()
      ..insert(
        0,
        ImportHistoryEntry(
          importSource: 'calendar',
          label: '캘린더 동기화',
          detail: '가져온 일정 $importedCount건 / 조회한 일정 $scannedCount건',
          importedAt: syncedAt,
          count: importedCount,
        ),
      );

    await _persist(
      recentEntries: recentEntries,
      sourceIndex: sourceIndex,
      fileIndex: _loadFileIndex(),
      calendarLastSyncAt: syncedAt,
    );
  }

  List<ImportHistoryEntry> _loadEntries() {
    final rawEntries = sharedPreferences.getString(_entriesKey);
    if (rawEntries == null || rawEntries.isEmpty) {
      return <ImportHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(rawEntries) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (entry) =>
                ImportHistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: true);
    } on FormatException {
      return <ImportHistoryEntry>[];
    } on TypeError {
      return <ImportHistoryEntry>[];
    }
  }

  Map<String, Map<String, String>> _loadSourceIndex() {
    return _loadStringIndex(_sourceIndexKey);
  }

  Map<String, Map<String, String>> _loadFileIndex() {
    return _loadStringIndex(_fileIndexKey);
  }

  Map<String, Map<String, String>> _loadStringIndex(String key) {
    final rawIndex = sharedPreferences.getString(key);
    if (rawIndex == null || rawIndex.isEmpty) {
      return <String, Map<String, String>>{};
    }

    try {
      final decoded = jsonDecode(rawIndex) as Map<String, dynamic>;
      return <String, Map<String, String>>{
        for (final entry in decoded.entries)
          entry.key: Map<String, String>.from(
            entry.value as Map<dynamic, dynamic>,
          ),
      };
    } on FormatException {
      return <String, Map<String, String>>{};
    } on TypeError {
      return <String, Map<String, String>>{};
    }
  }

  DateTime? _loadCalendarLastSyncAt() {
    final rawValue = sharedPreferences.getString(_calendarLastSyncKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue);
  }

  Future<void> _persist({
    required List<ImportHistoryEntry> recentEntries,
    required Map<String, Map<String, String>> sourceIndex,
    required Map<String, Map<String, String>> fileIndex,
    DateTime? calendarLastSyncAt,
  }) async {
    final trimmedEntries = recentEntries
        .take(_maxRecentEntries)
        .toList(growable: false);

    await sharedPreferences.setString(
      _entriesKey,
      jsonEncode(trimmedEntries.map((entry) => entry.toJson()).toList()),
    );
    await sharedPreferences.setString(_sourceIndexKey, jsonEncode(sourceIndex));
    await sharedPreferences.setString(_fileIndexKey, jsonEncode(fileIndex));
    if (calendarLastSyncAt != null) {
      await sharedPreferences.setString(
        _calendarLastSyncKey,
        calendarLastSyncAt.toIso8601String(),
      );
    }
  }
}
