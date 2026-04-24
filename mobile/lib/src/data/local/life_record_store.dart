import 'package:shared_preferences/shared_preferences.dart';

import '../../core/security/database_encryption.dart';
import '../../domain/entities/life_record.dart';
import '../../domain/services/text_embedding_service.dart';
import 'vector_db.dart';

class LocalDataStats {
  const LocalDataStats({
    required this.recordCount,
    required this.databaseSizeBytes,
    required this.sourceCounts,
  });

  final int recordCount;
  final int databaseSizeBytes;
  final Map<String, int> sourceCounts;
}

/// Coordinates local record storage, embedding, encryption, and destructive reset.
class LifeRecordStore {
  LifeRecordStore({
    required this.vectorDb,
    required this.databaseEncryption,
    required this.embeddingService,
    required this.seedRecords,
    required this.sharedPreferences,
  });

  final VectorDb vectorDb;
  final DatabaseEncryption databaseEncryption;
  final TextEmbeddingService embeddingService;
  final List<LifeRecord> seedRecords;
  final SharedPreferences sharedPreferences;

  Future<void> initialize() async {
    await vectorDb.initialize();
  }

  Future<void> importRecords(List<LifeRecord> records) async {
    await initialize();
    await vectorDb.upsertRecords(records, embeddingService);
  }

  Future<void> loadDemoData() async {
    await initialize();
    await vectorDb.replaceAllRecords(seedRecords, embeddingService);
  }

  Future<bool> isEmpty() async {
    await initialize();
    return await vectorDb.documentCount() == 0;
  }

  Future<void> deleteAllData() async {
    await vectorDb.deleteAllData();
    await databaseEncryption.deleteMasterKey();
    await sharedPreferences.clear();
  }

  Future<LocalDataStats> loadStats() async {
    await initialize();
    return LocalDataStats(
      recordCount: await vectorDb.documentCount(),
      databaseSizeBytes: await vectorDb.databaseSizeBytes(),
      sourceCounts: await vectorDb.importSourceCounts(),
    );
  }

  Future<List<LifeRecord>> loadRecords() async {
    await initialize();
    return vectorDb.loadAllRecords();
  }
}
