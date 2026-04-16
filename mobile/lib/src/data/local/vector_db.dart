import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/life_record.dart';
import '../../domain/services/text_embedding_service.dart';

typedef DatabasePathResolver = Future<String> Function();

class VectorSearchMatch {
  const VectorSearchMatch({required this.record, required this.score});

  final LifeRecord record;
  final double score;
}

class VectorDb {
  VectorDb({required this.databaseFactory, required this.databasePathResolver});

  final DatabaseFactory databaseFactory;
  final DatabasePathResolver databasePathResolver;

  static const int _queryNormalizationCacheLimit = 48;
  static const int _searchResultCacheLimit = 24;
  static const int schemaVersion = 2;

  Database? _database;
  String? _resolvedDatabasePath;
  List<_IndexedDocument>? _indexedDocumentsCache;
  final Map<String, List<double>> _normalizedQueryCache =
      <String, List<double>>{};
  final Map<String, List<VectorSearchMatch>> _searchResultCache =
      <String, List<VectorSearchMatch>>{};

  Future<void> initialize() async {
    await _open();
  }

  Future<int> documentCount() async {
    final db = await _open();
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM documents');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> replaceAllRecords(
    List<LifeRecord> records,
    TextEmbeddingService embeddingService,
  ) async {
    final db = await _open();
    _invalidateCaches();

    await db.transaction((txn) async {
      await txn.delete('embeddings');
      await txn.delete('documents');
      await _upsertRecords(txn, records, embeddingService);
    });

    _invalidateCaches();
  }

  Future<void> upsertRecords(
    List<LifeRecord> records,
    TextEmbeddingService embeddingService,
  ) async {
    if (records.isEmpty) {
      return;
    }

    final db = await _open();
    _invalidateCaches();

    await db.transaction((txn) async {
      await _upsertRecords(txn, records, embeddingService);
    });

    _invalidateCaches();
  }

  Future<void> clearAllRecords() async {
    final db = await _open();
    _invalidateCaches();

    await db.transaction((txn) async {
      await txn.delete('embeddings');
      await txn.delete('documents');
    });

    _invalidateCaches();
  }

  Future<int> databaseSizeBytes() async {
    await _open();
    final path = _resolvedDatabasePath;
    if (path == null) {
      return 0;
    }
    final file = File(path);
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  Future<List<VectorSearchMatch>> search(
    List<double> queryVector, {
    int topK = 3,
  }) async {
    final normalizedQuery = _normalizeQuery(queryVector);
    final cacheKey = '${_vectorKey(normalizedQuery)}::$topK';
    final cachedResult = _searchResultCache[cacheKey];
    if (cachedResult != null) {
      return List<VectorSearchMatch>.from(cachedResult, growable: false);
    }

    final indexedDocuments = await _loadIndexedDocuments();
    final matches = <VectorSearchMatch>[
      for (final indexedDocument in indexedDocuments)
        VectorSearchMatch(
          record: indexedDocument.record,
          score: _cosineSimilarity(normalizedQuery, indexedDocument.vector),
        ),
    ];

    matches.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return right.record.createdAt.compareTo(left.record.createdAt);
    });

    final result = matches.take(topK).toList(growable: false);
    _setSearchResultCache(cacheKey, result);
    return result;
  }

  @visibleForTesting
  int get debugCachedQueryCount => _normalizedQueryCache.length;

  @visibleForTesting
  int get debugSearchResultCacheCount => _searchResultCache.length;

  @visibleForTesting
  int get debugIndexedDocumentCount => _indexedDocumentsCache?.length ?? 0;

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = await databasePathResolver();
    _resolvedDatabasePath = path;
    final database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (Database db, int version) async {
          await _createSchema(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              ALTER TABLE documents
              ADD COLUMN import_source TEXT NOT NULL DEFAULT 'note'
            ''');
            await db.execute('''
              ALTER TABLE documents
              ADD COLUMN metadata_json TEXT NOT NULL DEFAULT '{}'
            ''');
            await db.execute('''
              UPDATE documents
              SET import_source = CASE source
                WHEN '일기' THEN 'diary'
                WHEN '캘린더' THEN 'calendar'
                WHEN '메모' THEN 'note'
                ELSE 'note'
              END
            ''');
          }
        },
      ),
    );

    _database = database;
    return database;
  }

  LifeRecord _recordFromRow(Map<String, Object?> row) {
    final tags = (jsonDecode(row['tags_json']! as String) as List<dynamic>)
        .map((dynamic value) => value.toString())
        .toList(growable: false);

    return LifeRecord(
      id: row['id']! as String,
      source: row['source']! as String,
      importSource: row['import_source']! as String,
      title: row['title']! as String,
      content: row['content']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      tags: tags,
      metadata: Map<String, dynamic>.from(
        jsonDecode(row['metadata_json']! as String) as Map<dynamic, dynamic>,
      ),
    );
  }

  List<double> _vectorFromJson(String rawValue) {
    final values = jsonDecode(rawValue) as List<dynamic>;
    return values.map((dynamic value) => (value as num).toDouble()).toList();
  }

  Future<List<_IndexedDocument>> _loadIndexedDocuments() async {
    final cached = _indexedDocumentsCache;
    if (cached != null) {
      return cached;
    }

    final db = await _open();
    final rows = await db.rawQuery('''
      SELECT
        documents.id,
        documents.source,
        documents.import_source,
        documents.title,
        documents.content,
        documents.created_at,
        documents.tags_json,
        documents.metadata_json,
        embeddings.vector_json
      FROM documents
      INNER JOIN embeddings ON documents.id = embeddings.doc_id
    ''');

    final indexedDocuments = <_IndexedDocument>[
      for (final row in rows)
        _IndexedDocument(
          record: _recordFromRow(row),
          vector: _normalize(_vectorFromJson(row['vector_json']! as String)),
        ),
    ];

    _indexedDocumentsCache = indexedDocuments;
    return indexedDocuments;
  }

  List<double> _normalizeQuery(List<double> queryVector) {
    final key = _vectorKey(queryVector);
    final cached = _normalizedQueryCache[key];
    if (cached != null) {
      return cached;
    }

    final normalized = _normalize(queryVector);
    _normalizedQueryCache[key] = normalized;
    _trimCache(_normalizedQueryCache, _queryNormalizationCacheLimit);
    return normalized;
  }

  void _setSearchResultCache(String key, List<VectorSearchMatch> matches) {
    _searchResultCache[key] = List<VectorSearchMatch>.from(
      matches,
      growable: false,
    );
    _trimCache(_searchResultCache, _searchResultCacheLimit);
  }

  void _trimCache<T>(Map<String, T> cache, int maxSize) {
    while (cache.length > maxSize) {
      cache.remove(cache.keys.first);
    }
  }

  String _vectorKey(List<double> vector) {
    return vector.map((double value) => value.toStringAsFixed(5)).join(',');
  }

  void _invalidateCaches() {
    _indexedDocumentsCache = null;
    _normalizedQueryCache.clear();
    _searchResultCache.clear();
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        import_source TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        tags_json TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE embeddings (
        doc_id TEXT PRIMARY KEY,
        dim INTEGER NOT NULL,
        vector_json TEXT NOT NULL,
        FOREIGN KEY(doc_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upsertRecords(
    Transaction txn,
    List<LifeRecord> records,
    TextEmbeddingService embeddingService,
  ) async {
    for (final record in records) {
      await txn.insert('documents', <String, Object?>{
        'id': record.id,
        'source': record.source,
        'import_source': record.importSource,
        'title': record.title,
        'content': record.content,
        'created_at': record.createdAt.millisecondsSinceEpoch,
        'tags_json': jsonEncode(record.tags),
        'metadata_json': jsonEncode(record.metadata),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final embedding = await embeddingService.embed(record.searchableText);
      await txn.insert('embeddings', <String, Object?>{
        'doc_id': record.id,
        'dim': embedding.length,
        'vector_json': jsonEncode(_normalize(embedding)),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  List<double> _normalize(List<double> vector) {
    final magnitude = math.sqrt(
      vector.fold<double>(0, (double sum, double value) => sum + value * value),
    );
    if (magnitude == 0) {
      return List<double>.filled(vector.length, 0);
    }
    return vector
        .map((double value) => value / magnitude)
        .toList(growable: false);
  }

  double _cosineSimilarity(List<double> left, List<double> right) {
    if (left.length != right.length) {
      return 0;
    }

    var sum = 0.0;
    for (var index = 0; index < left.length; index += 1) {
      sum += left[index] * right[index];
    }
    return sum;
  }
}

class _IndexedDocument {
  const _IndexedDocument({required this.record, required this.vector});

  final LifeRecord record;
  final List<double> vector;
}
