import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/security/database_encryption.dart';
import '../../domain/entities/life_record.dart';
import '../../domain/services/text_embedding_service.dart';
import '../ondevice/semantic_embedding_service.dart';

typedef DatabasePathResolver = Future<String> Function();

class VectorSearchMatch {
  const VectorSearchMatch({required this.record, required this.score});

  final LifeRecord record;
  final double score;
}

class VectorDb {
  VectorDb({
    required this.databaseFactory,
    required this.databasePathResolver,
    required this.databaseEncryption,
  });

  final DatabaseFactory databaseFactory;
  final DatabasePathResolver databasePathResolver;
  final DatabaseEncryption databaseEncryption;

  static const int _queryNormalizationCacheLimit = 48;
  static const int _searchResultCacheLimit = 50;
  static const int _fallbackFullScanWindow = 24;
  static const int schemaVersion = 5;

  Database? _database;
  String? _resolvedDatabasePath;
  _VectorIndexSnapshot? _indexSnapshotCache;
  final Map<String, List<double>> _normalizedQueryCache =
      <String, List<double>>{};
  final Map<String, _SearchCacheEntry> _searchResultCache =
      <String, _SearchCacheEntry>{};

  Future<void> initialize() async {
    await _open();
  }

  Future<int> cleanOrphanEmbeddings() async {
    final db = await _open();
    return _cleanOrphanEmbeddings(db);
  }

  Future<int> documentCount() async {
    final db = await _open();
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM documents');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, int>> importSourceCounts() async {
    final db = await _open();
    final rows = await db.rawQuery('''
      SELECT import_source, COUNT(*) AS count
      FROM documents
      GROUP BY import_source
    ''');

    return <String, int>{
      for (final row in rows)
        row['import_source']! as String: ((row['count'] as num?)?.toInt()) ?? 0,
    };
  }

  Future<List<LifeRecord>> loadAllRecords() async {
    final db = await _open();
    final rows = await db.query(
      'documents',
      orderBy: 'created_at DESC',
    );
    final records = <LifeRecord>[];
    for (final row in rows) {
      records.add(await _recordFromRow(row));
    }
    return List<LifeRecord>.unmodifiable(records);
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

  Future<void> deleteAllData() async {
    _invalidateCaches();
    final existing = _database;
    _database = null;

    if (existing != null) {
      await existing.close();
    }

    final path = _resolvedDatabasePath ?? await databasePathResolver();
    _resolvedDatabasePath = path;
    await databaseFactory.deleteDatabase(path);
    await _deleteSidecarFiles(path);
  }

  Future<void> _deleteSidecarFiles(String path) async {
    for (final suffix in const <String>['-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<int> databaseSizeBytes() async {
    final db = await _open();
    final dbPath = db.path;
    _resolvedDatabasePath = dbPath;
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
    int? topK,
    int limit = 5,
    int offset = 0,
  }) async {
    final window = _resolveSearchWindow(
      topK: topK,
      limit: limit,
      offset: offset,
    );
    final normalizedQuery = _normalizeQuery(queryVector);
    final cacheKey = 'vector:${_vectorKey(normalizedQuery)}';
    final cachedResult = _getSearchResultCache(
      cacheKey,
      minimumResults: window.requestedResultCount,
    );
    if (cachedResult != null) {
      return _paginateMatches(
        cachedResult.matches,
        limit: window.limit,
        offset: window.offset,
      );
    }

    final rankedMatches = _rankCandidates(
      normalizedQuery,
      (await _loadIndexSnapshot()).documents,
    );
    _setSearchResultCache(cacheKey, rankedMatches, isCompleteRanking: true);
    return _paginateMatches(
      rankedMatches,
      limit: window.limit,
      offset: window.offset,
    );
  }

  Future<List<VectorSearchMatch>> searchWithPrefilter(
    String question,
    List<double> queryVector, {
    int? topK,
    int limit = 5,
    int offset = 0,
  }) async {
    final window = _resolveSearchWindow(
      topK: topK,
      limit: limit,
      offset: offset,
    );
    final cacheKey = 'question:${_questionHash(question)}';
    final cachedResult = _getSearchResultCache(
      cacheKey,
      minimumResults: window.requestedResultCount,
    );
    if (cachedResult != null) {
      return _paginateMatches(
        cachedResult.matches,
        limit: window.limit,
        offset: window.offset,
      );
    }

    final normalizedQuery = _normalizeQuery(queryVector);
    final queryTags = _normalizedTags(
      SemanticEmbeddingService.suggestTags(question, maxTags: 6),
    );
    final indexSnapshot = await _loadIndexSnapshot();
    final candidates = _prefilterCandidates(indexSnapshot, queryTags);

    final isFallbackFullScan = candidates.isEmpty;
    final rankedMatches = isFallbackFullScan
        ? _rankTopCandidates(
            normalizedQuery,
            indexSnapshot.documents,
            maxResults: math.max(
              window.requestedResultCount,
              _fallbackFullScanWindow,
            ),
          )
        : _rankCandidates(normalizedQuery, candidates);
    _setSearchResultCache(
      cacheKey,
      rankedMatches,
      isCompleteRanking: !isFallbackFullScan,
    );
    return _paginateMatches(
      rankedMatches,
      limit: window.limit,
      offset: window.offset,
    );
  }

  @visibleForTesting
  int get debugCachedQueryCount => _normalizedQueryCache.length;

  @visibleForTesting
  int get debugSearchResultCacheCount => _searchResultCache.length;

  @visibleForTesting
  int get debugIndexedDocumentCount =>
      _indexSnapshotCache?.documents.length ?? 0;

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
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
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
          if (oldVersion < 3) {
            await _encryptExistingPersonalData(db);
          }
          if (oldVersion < 4) {
            await db.execute('''
              ALTER TABLE embeddings
              ADD COLUMN normalized INTEGER NOT NULL DEFAULT 0
            ''');
            await _normalizeStoredEmbeddings(db);
          }
          if (oldVersion < 5) {
            await db.execute('''
              ALTER TABLE documents
              ADD COLUMN source_id TEXT NOT NULL DEFAULT ''
            ''');
            await db.execute('''
              UPDATE documents
              SET source_id = id
              WHERE source_id = ''
            ''');
            await _ensureSourceIdUniqueIndex(db);
          }
        },
      ),
    );

    await _ensureEncryptionState(database);
    await _cleanOrphanEmbeddings(database);
    _database = database;
    return database;
  }

  Future<void> _ensureEncryptionState(Database db) async {
    final encryptedDataExists = await _encryptedDataExists(db);
    await databaseEncryption.ensureKeyAvailableForEncryptedData(
      encryptedDataExists: encryptedDataExists,
    );
    if (!encryptedDataExists) {
      await databaseEncryption.ensureMasterKey();
      return;
    }

    final rows = await db.query(
      'documents',
      columns: <String>['title', 'content', 'tags_json', 'metadata_json'],
      where:
          'title LIKE ? OR content LIKE ? OR tags_json LIKE ? OR metadata_json LIKE ?',
      whereArgs: List<Object>.filled(4, '${DatabaseEncryption.cipherPrefix}:%'),
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }

    final row = rows.first;
    for (final column in const <String>[
      'title',
      'content',
      'tags_json',
      'metadata_json',
    ]) {
      final value = row[column] as String? ?? '';
      if (value.isEmpty || !databaseEncryption.isEncryptedValue(value)) {
        continue;
      }
      await databaseEncryption.decryptValue(value);
    }
  }

  Future<bool> _encryptedDataExists(Database db) async {
    final rows = await db.rawQuery('''
      SELECT 1
      FROM documents
      WHERE title LIKE ?
        OR content LIKE ?
        OR tags_json LIKE ?
        OR metadata_json LIKE ?
      LIMIT 1
    ''', List<Object>.filled(4, '${DatabaseEncryption.cipherPrefix}:%'));
    return rows.isNotEmpty;
  }

  Future<void> _encryptExistingPersonalData(Database db) async {
    final rows = await db.query(
      'documents',
      columns: <String>['id', 'title', 'content', 'tags_json', 'metadata_json'],
    );
    final batch = db.batch();

    for (final row in rows) {
      final id = row['id']! as String;
      final updates = <String, Object?>{};

      Future<void> encryptField(String column) async {
        final value = row[column] as String? ?? '';
        if (_needsEncryption(value)) {
          updates[column] = await databaseEncryption.encryptValue(value);
        }
      }

      await encryptField('title');
      await encryptField('content');
      await encryptField('tags_json');
      await encryptField('metadata_json');

      if (updates.isNotEmpty) {
        batch.update(
          'documents',
          updates,
          where: 'id = ?',
          whereArgs: <Object>[id],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  bool _needsEncryption(String value) {
    return value.isNotEmpty && !databaseEncryption.isEncryptedValue(value);
  }

  Future<LifeRecord> _recordFromRow(Map<String, Object?> row) async {
    final decryptedTagsJson = await databaseEncryption.decryptValue(
      row['tags_json']! as String,
    );
    final tags = (jsonDecode(decryptedTagsJson) as List<dynamic>)
        .map((dynamic value) => value.toString())
        .toList(growable: false);
    final decryptedMetadataJson = await databaseEncryption.decryptValue(
      row['metadata_json']! as String,
    );

    return LifeRecord(
      id: row['id']! as String,
      source: row['source']! as String,
      sourceId: row['source_id']! as String,
      importSource: row['import_source']! as String,
      title: await databaseEncryption.decryptValue(row['title']! as String),
      content: await databaseEncryption.decryptValue(row['content']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      tags: tags,
      metadata: Map<String, dynamic>.from(
        jsonDecode(decryptedMetadataJson) as Map<dynamic, dynamic>,
      ),
    );
  }

  List<double> _vectorFromJson(String rawValue) {
    final values = jsonDecode(rawValue) as List<dynamic>;
    return values.map((dynamic value) => (value as num).toDouble()).toList();
  }

  Future<_VectorIndexSnapshot> _loadIndexSnapshot() async {
    final cached = _indexSnapshotCache;
    if (cached != null) {
      return cached;
    }

    final db = await _open();
    final rows = await db.rawQuery('''
      SELECT
        documents.id,
        documents.source,
        documents.source_id,
        documents.import_source,
        documents.title,
        documents.content,
        documents.created_at,
        documents.tags_json,
        documents.metadata_json,
        embeddings.vector_json,
        embeddings.normalized
      FROM documents
      INNER JOIN embeddings ON documents.id = embeddings.doc_id
    ''');

    final indexedDocuments = <_IndexedDocument>[];
    final documentsByTag = <String, List<_IndexedDocument>>{};
    final documentsByCluster = <String, List<_IndexedDocument>>{};
    final normalizationUpdates = <_EmbeddingNormalizationUpdate>[];
    for (final row in rows) {
      final record = await _recordFromRow(row);
      final rawVector = _vectorFromJson(row['vector_json']! as String);
      final normalized = ((row['normalized'] as num?)?.toInt() ?? 0) == 1;
      final vector = normalized ? rawVector : _normalize(rawVector);
      if (!normalized) {
        normalizationUpdates.add(
          _EmbeddingNormalizationUpdate(documentId: record.id, vector: vector),
        );
      }
      final tagKeys = _normalizedTags(record.tags);
      final clusterKeys = tagKeys
          .map(_clusterKeyForTag)
          .whereType<String>()
          .toSet();
      final indexedDocument = _IndexedDocument(record: record, vector: vector);
      indexedDocuments.add(indexedDocument);
      for (final tagKey in tagKeys) {
        documentsByTag
            .putIfAbsent(tagKey, () => <_IndexedDocument>[])
            .add(indexedDocument);
      }
      for (final clusterKey in clusterKeys) {
        documentsByCluster
            .putIfAbsent(clusterKey, () => <_IndexedDocument>[])
            .add(indexedDocument);
      }
    }

    if (normalizationUpdates.isNotEmpty) {
      final batch = db.batch();
      for (final update in normalizationUpdates) {
        batch.update(
          'embeddings',
          <String, Object?>{
            'vector_json': jsonEncode(update.vector),
            'normalized': 1,
          },
          where: 'doc_id = ?',
          whereArgs: <Object>[update.documentId],
        );
      }
      await batch.commit(noResult: true);
    }

    final snapshot = _VectorIndexSnapshot(
      documents: indexedDocuments,
      documentsByTag: documentsByTag,
      documentsByCluster: documentsByCluster,
    );
    _indexSnapshotCache = snapshot;
    return snapshot;
  }

  List<double> _normalizeQuery(List<double> queryVector) {
    final key = _vectorKey(queryVector);
    final cached = _getLruValue(_normalizedQueryCache, key);
    if (cached != null) {
      return cached;
    }

    final normalized = _normalize(queryVector);
    _setLruValue(_normalizedQueryCache, key, normalized);
    return normalized;
  }

  _SearchCacheEntry? _getSearchResultCache(
    String key, {
    required int minimumResults,
  }) {
    final cached = _getLruValue(_searchResultCache, key);
    if (cached == null) {
      return null;
    }
    if (!cached.isCompleteRanking && cached.matches.length < minimumResults) {
      _searchResultCache.remove(key);
      return null;
    }
    return cached;
  }

  void _setSearchResultCache(
    String key,
    List<VectorSearchMatch> rankedMatches, {
    required bool isCompleteRanking,
  }) {
    _setLruValue(
      _searchResultCache,
      key,
      _SearchCacheEntry(
        matches: List<VectorSearchMatch>.unmodifiable(
          List<VectorSearchMatch>.from(rankedMatches, growable: false),
        ),
        isCompleteRanking: isCompleteRanking,
      ),
    );
  }

  T? _getLruValue<T>(Map<String, T> cache, String key) {
    final value = cache.remove(key);
    if (value == null) {
      return null;
    }
    cache[key] = value;
    return value;
  }

  void _setLruValue<T>(Map<String, T> cache, String key, T value) {
    cache.remove(key);
    cache[key] = value;
    final maxSize = identical(cache, _normalizedQueryCache)
        ? _queryNormalizationCacheLimit
        : _searchResultCacheLimit;
    while (cache.length > maxSize) {
      cache.remove(cache.keys.first);
    }
  }

  String _vectorKey(List<double> vector) {
    return vector.map((double value) => value.toStringAsFixed(5)).join(',');
  }

  void _invalidateCaches() {
    _indexSnapshotCache = null;
    _normalizedQueryCache.clear();
    _searchResultCache.clear();
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        source_id TEXT NOT NULL,
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
        normalized INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(doc_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
    await _ensureSourceIdUniqueIndex(db);
  }

  Future<void> _ensureSourceIdUniqueIndex(DatabaseExecutor db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS documents_import_source_source_id_idx
      ON documents(import_source, source_id)
    ''');
  }

  Future<int> _cleanOrphanEmbeddings(DatabaseExecutor db) async {
    return db.rawDelete('''
      DELETE FROM embeddings
      WHERE doc_id NOT IN (SELECT id FROM documents)
    ''');
  }

  Future<void> _upsertRecords(
    Transaction txn,
    List<LifeRecord> records,
    TextEmbeddingService embeddingService,
  ) async {
    for (final record in records) {
      final existing = await _findDocBySourceId(
        txn,
        record.importSource,
        record.sourceId,
      );
      if (existing != null) {
        await _deleteEmbeddingsByDocId(txn, existing['id']! as String);
      }

      final encryptedTitle = await databaseEncryption.encryptValue(
        record.title,
      );
      final encryptedContent = await databaseEncryption.encryptValue(
        record.content,
      );
      final encryptedTags = await databaseEncryption.encryptValue(
        jsonEncode(record.tags),
      );
      final encryptedMetadata = await databaseEncryption.encryptValue(
        jsonEncode(record.metadata),
      );
      await txn.insert('documents', <String, Object?>{
        'id': record.id,
        'source': record.source,
        'source_id': record.sourceId,
        'import_source': record.importSource,
        'title': encryptedTitle,
        'content': encryptedContent,
        'created_at': record.createdAt.millisecondsSinceEpoch,
        'tags_json': encryptedTags,
        'metadata_json': encryptedMetadata,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final embedding = await embeddingService.embed(record.searchableText);
      final normalizedEmbedding = _normalize(embedding);
      await txn.insert('embeddings', <String, Object?>{
        'doc_id': record.id,
        'dim': embedding.length,
        'vector_json': jsonEncode(normalizedEmbedding),
        'normalized': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Map<String, Object?>?> _findDocBySourceId(
    DatabaseExecutor db,
    String importSource,
    String sourceId,
  ) async {
    final rows = await db.query(
      'documents',
      columns: <String>['id'],
      where: 'import_source = ? AND source_id = ?',
      whereArgs: <Object>[importSource, sourceId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> _deleteEmbeddingsByDocId(
    DatabaseExecutor db,
    String docId,
  ) async {
    await db.delete(
      'embeddings',
      where: 'doc_id = ?',
      whereArgs: <Object>[docId],
    );
  }

  Future<void> _normalizeStoredEmbeddings(Database db) async {
    final rows = await db.query(
      'embeddings',
      columns: <String>['doc_id', 'vector_json'],
    );
    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'embeddings',
        <String, Object?>{
          'vector_json': jsonEncode(
            _normalize(_vectorFromJson(row['vector_json']! as String)),
          ),
          'normalized': 1,
        },
        where: 'doc_id = ?',
        whereArgs: <Object>[row['doc_id']! as String],
      );
    }
    await batch.commit(noResult: true);
  }

  _SearchWindow _resolveSearchWindow({
    required int? topK,
    required int limit,
    required int offset,
  }) {
    final resolvedLimit = topK ?? limit;
    if (resolvedLimit <= 0) {
      throw ArgumentError.value(
        resolvedLimit,
        'limit',
        'Search limit must be greater than zero.',
      );
    }
    if (offset < 0) {
      throw ArgumentError.value(
        offset,
        'offset',
        'Search offset cannot be negative.',
      );
    }
    return _SearchWindow(limit: resolvedLimit, offset: offset);
  }

  List<_IndexedDocument> _prefilterCandidates(
    _VectorIndexSnapshot indexSnapshot,
    List<String> queryTags,
  ) {
    if (queryTags.isEmpty) {
      return const <_IndexedDocument>[];
    }

    final candidates = <_IndexedDocument>{};
    var hasExactTagOverlap = false;
    for (final tag in queryTags) {
      final tagMatches = indexSnapshot.documentsByTag[tag];
      if (tagMatches == null || tagMatches.isEmpty) {
        continue;
      }
      hasExactTagOverlap = true;
      candidates.addAll(tagMatches);
    }

    for (final tag in queryTags) {
      final clusterKey = _clusterKeyForTag(tag);
      if (clusterKey == null) {
        continue;
      }
      final clusterMatches = indexSnapshot.documentsByCluster[clusterKey];
      if (clusterMatches == null || clusterMatches.isEmpty) {
        continue;
      }
      candidates.addAll(clusterMatches);
    }

    if (!hasExactTagOverlap) {
      return const <_IndexedDocument>[];
    }
    return candidates.toList(growable: false);
  }

  List<VectorSearchMatch> _rankCandidates(
    List<double> normalizedQuery,
    Iterable<_IndexedDocument> candidates,
  ) {
    final matches = <VectorSearchMatch>[
      for (final indexedDocument in candidates)
        VectorSearchMatch(
          record: indexedDocument.record,
          score: _cosineSimilarity(normalizedQuery, indexedDocument.vector),
        ),
    ];
    matches.sort(_compareMatches);
    return List<VectorSearchMatch>.unmodifiable(matches);
  }

  List<VectorSearchMatch> _rankTopCandidates(
    List<double> normalizedQuery,
    Iterable<_IndexedDocument> candidates, {
    required int maxResults,
  }) {
    if (maxResults <= 0) {
      return const <VectorSearchMatch>[];
    }

    final topMatches = <VectorSearchMatch>[];
    for (final indexedDocument in candidates) {
      final match = VectorSearchMatch(
        record: indexedDocument.record,
        score: _cosineSimilarity(normalizedQuery, indexedDocument.vector),
      );
      final insertAt = topMatches.indexWhere(
        (VectorSearchMatch existing) => _compareMatches(match, existing) < 0,
      );
      if (insertAt == -1) {
        topMatches.add(match);
      } else {
        topMatches.insert(insertAt, match);
      }
      if (topMatches.length > maxResults) {
        topMatches.removeLast();
      }
    }
    return List<VectorSearchMatch>.unmodifiable(topMatches);
  }

  int _compareMatches(VectorSearchMatch left, VectorSearchMatch right) {
    final scoreCompare = right.score.compareTo(left.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return right.record.createdAt.compareTo(left.record.createdAt);
  }

  List<VectorSearchMatch> _paginateMatches(
    List<VectorSearchMatch> matches, {
    required int limit,
    required int offset,
  }) {
    if (offset >= matches.length) {
      return const <VectorSearchMatch>[];
    }
    final end = math.min(offset + limit, matches.length);
    return List<VectorSearchMatch>.unmodifiable(matches.sublist(offset, end));
  }

  String _questionHash(String question) {
    final normalizedQuestion = question.trim().toLowerCase();
    return sha256.convert(utf8.encode(normalizedQuestion)).toString();
  }

  List<String> _normalizedTags(List<String> tags) {
    final uniqueTags = <String>{};
    for (final tag in tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      uniqueTags.add(normalized);
    }
    return uniqueTags.toList(growable: false);
  }

  String? _clusterKeyForTag(String tag) {
    for (final rule in _tagClusterRules) {
      if (rule.matches(tag)) {
        return rule.key;
      }
    }
    return null;
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

class _VectorIndexSnapshot {
  const _VectorIndexSnapshot({
    required this.documents,
    required this.documentsByTag,
    required this.documentsByCluster,
  });

  final List<_IndexedDocument> documents;
  final Map<String, List<_IndexedDocument>> documentsByTag;
  final Map<String, List<_IndexedDocument>> documentsByCluster;
}

class _EmbeddingNormalizationUpdate {
  const _EmbeddingNormalizationUpdate({
    required this.documentId,
    required this.vector,
  });

  final String documentId;
  final List<double> vector;
}

class _SearchWindow {
  const _SearchWindow({required this.limit, required this.offset});

  final int limit;
  final int offset;

  int get requestedResultCount => limit + offset;
}

class _SearchCacheEntry {
  const _SearchCacheEntry({
    required this.matches,
    required this.isCompleteRanking,
  });

  final List<VectorSearchMatch> matches;
  final bool isCompleteRanking;
}

class _TagClusterRule {
  const _TagClusterRule({required this.key, required this.aliases});

  final String key;
  final List<String> aliases;

  bool matches(String tag) {
    return aliases.any((String alias) => tag.contains(alias));
  }
}

const List<_TagClusterRule> _tagClusterRules = <_TagClusterRule>[
  _TagClusterRule(
    key: 'fatigue',
    aliases: <String>['무기력', '지침', '피곤', '피로', '기운없', '기력없'],
  ),
  _TagClusterRule(key: 'burnout', aliases: <String>['번아웃', '소진', '탈진', '과로']),
  _TagClusterRule(
    key: 'work_pressure',
    aliases: <String>['야근', '마감', '업무', '프로젝트', '회의', '압박'],
  ),
  _TagClusterRule(
    key: 'sleep',
    aliases: <String>['수면', '잠', '숙면', '불면', '기상', '졸림', '낮잠'],
  ),
  _TagClusterRule(
    key: 'recovery',
    aliases: <String>['회복', '휴식', '쉼', '산책', '재충전', '숨통'],
  ),
  _TagClusterRule(key: 'focus', aliases: <String>['집중', '리듬', '루틴', '정리']),
  _TagClusterRule(
    key: 'motivation',
    aliases: <String>['의욕', '아이디어', '구현', '사이드프로젝트'],
  ),
  _TagClusterRule(
    key: 'anxiety',
    aliases: <String>['불안', '걱정', '초조', '죄책감', '답답'],
  ),
  _TagClusterRule(
    key: 'health',
    aliases: <String>['건강', '몸', '운동', '러닝', '통증', '컨디션', '식사'],
  ),
  _TagClusterRule(
    key: 'relationships',
    aliases: <String>['관계', '친구', '가족', '연인', '대화', '동료'],
  ),
  _TagClusterRule(
    key: 'reflection',
    aliases: <String>['회고', '성장', '배움', '기록', '습관'],
  ),
  _TagClusterRule(
    key: 'creativity',
    aliases: <String>['창작', '글쓰기', '그림', '초안', '작업', '스케치'],
  ),
];
