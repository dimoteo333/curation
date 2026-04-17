import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/life_record.dart';
import '../../domain/services/text_embedding_service.dart';
import 'vector_db.dart';

class LocalDataStats {
  const LocalDataStats({
    required this.recordCount,
    required this.databaseSizeBytes,
  });

  final int recordCount;
  final int databaseSizeBytes;
}

class LifeRecordStore {
  LifeRecordStore({
    required this.vectorDb,
    required this.embeddingService,
    required this.seedRecords,
    required this.sharedPreferences,
  });

  static const String _bootstrapKey = 'local_records.bootstrap_completed';

  final VectorDb vectorDb;
  final TextEmbeddingService embeddingService;
  final List<LifeRecord> seedRecords;
  final SharedPreferences sharedPreferences;

  Future<void> initialize() async {
    await vectorDb.initialize();

    final bootstrapCompleted =
        sharedPreferences.getBool(_bootstrapKey) ?? false;
    if (bootstrapCompleted) {
      return;
    }

    if (await vectorDb.documentCount() == 0) {
      await vectorDb.replaceAllRecords(seedRecords, embeddingService);
    }
    await sharedPreferences.setBool(_bootstrapKey, true);
  }

  Future<void> importRecords(List<LifeRecord> records) async {
    await initialize();
    await vectorDb.upsertRecords(records, embeddingService);
  }

  Future<void> resetToSeedRecords() async {
    await vectorDb.initialize();
    await vectorDb.replaceAllRecords(seedRecords, embeddingService);
    await sharedPreferences.setBool(_bootstrapKey, true);
  }

  Future<void> clearAllRecords() async {
    await deleteAllData();
  }

  Future<void> deleteAllData() async {
    await vectorDb.initialize();
    await vectorDb.deleteAllData();
    await sharedPreferences.clear();
  }

  Future<LocalDataStats> loadStats() async {
    await initialize();
    return LocalDataStats(
      recordCount: await vectorDb.documentCount(),
      databaseSizeBytes: await vectorDb.databaseSizeBytes(),
    );
  }
}
