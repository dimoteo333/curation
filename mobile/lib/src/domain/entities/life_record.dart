class LifeRecord {
  const LifeRecord({
    required this.id,
    required this.sourceId,
    required this.source,
    required this.importSource,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.tags,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String sourceId;
  final String source;
  final String importSource;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  String get searchableText => '$title $content ${tags.join(' ')}';
}
