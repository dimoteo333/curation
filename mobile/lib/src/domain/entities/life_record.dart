class LifeRecord {
  const LifeRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.tags,
  });

  final String id;
  final String source;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<String> tags;

  String get searchableText => '$title $content ${tags.join(' ')}';
}
