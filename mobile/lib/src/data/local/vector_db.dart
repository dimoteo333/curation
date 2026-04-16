import 'dart:convert';
import 'dart:math' as math;

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

  Database? _database;

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

    await db.transaction((txn) async {
      await txn.delete('embeddings');
      await txn.delete('documents');

      for (final record in records) {
        await txn.insert('documents', <String, Object?>{
          'id': record.id,
          'source': record.source,
          'title': record.title,
          'content': record.content,
          'created_at': record.createdAt.millisecondsSinceEpoch,
          'tags_json': jsonEncode(record.tags),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final embedding = await embeddingService.embed(record.searchableText);
        await txn.insert('embeddings', <String, Object?>{
          'doc_id': record.id,
          'dim': embedding.length,
          'vector_json': jsonEncode(_normalize(embedding)),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<VectorSearchMatch>> search(
    List<double> queryVector, {
    int topK = 3,
  }) async {
    final normalizedQuery = _normalize(queryVector);
    final db = await _open();
    final rows = await db.rawQuery('''
      SELECT
        documents.id,
        documents.source,
        documents.title,
        documents.content,
        documents.created_at,
        documents.tags_json,
        embeddings.vector_json
      FROM documents
      INNER JOIN embeddings ON documents.id = embeddings.doc_id
    ''');

    final matches = <VectorSearchMatch>[
      for (final row in rows)
        VectorSearchMatch(
          record: _recordFromRow(row),
          score: _cosineSimilarity(
            normalizedQuery,
            _vectorFromJson(row['vector_json']! as String),
          ),
        ),
    ];

    matches.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return right.record.createdAt.compareTo(left.record.createdAt);
    });

    return matches.take(topK).toList(growable: false);
  }

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = await databasePathResolver();
    final database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              source TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              tags_json TEXT NOT NULL
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
      title: row['title']! as String,
      content: row['content']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      tags: tags,
    );
  }

  List<double> _vectorFromJson(String rawValue) {
    final values = jsonDecode(rawValue) as List<dynamic>;
    return values.map((dynamic value) => (value as num).toDouble()).toList();
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
