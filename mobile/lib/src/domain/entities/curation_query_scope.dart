import 'life_record.dart';

enum CurationTimeScope { allTime, pastYear, pastMonth }

class CurationQueryScope {
  const CurationQueryScope({
    this.timeScope = CurationTimeScope.allTime,
    this.importSources = const <String>{},
    this.excludedRecordIds = const <String>{},
  });

  static const CurationQueryScope all = CurationQueryScope();

  final CurationTimeScope timeScope;
  final Set<String> importSources;
  final Set<String> excludedRecordIds;

  bool get hasSourceFilter => importSources.isNotEmpty;
  bool get hasExcludedRecords => excludedRecordIds.isNotEmpty;

  DateTime? earliestCreatedAt(DateTime now) {
    return switch (timeScope) {
      CurationTimeScope.allTime => null,
      CurationTimeScope.pastYear => now.subtract(const Duration(days: 365)),
      CurationTimeScope.pastMonth => now.subtract(const Duration(days: 30)),
    };
  }

  bool matchesRecord(LifeRecord record, {required DateTime now}) {
    final earliestCreatedAt = this.earliestCreatedAt(now);
    if (earliestCreatedAt != null &&
        record.createdAt.isBefore(earliestCreatedAt)) {
      return false;
    }
    if (hasSourceFilter && !importSources.contains(record.importSource)) {
      return false;
    }
    if (hasExcludedRecords && excludedRecordIds.contains(record.id)) {
      return false;
    }
    return true;
  }

  String get cacheKey {
    final sortedSources = importSources.toList()..sort();
    final sourceKey = sortedSources.isEmpty
        ? 'all-sources'
        : sortedSources.join(',');
    final sortedExcludedIds = excludedRecordIds.toList()..sort();
    final excludedKey = sortedExcludedIds.isEmpty
        ? 'no-excluded-records'
        : sortedExcludedIds.join(',');
    return '${timeScope.name}:$sourceKey:$excludedKey';
  }
}
