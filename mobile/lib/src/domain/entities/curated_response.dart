class SupportingRecord {
  const SupportingRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.createdAt,
    required this.excerpt,
    required this.relevanceReason,
  });

  final String id;
  final String source;
  final String title;
  final DateTime createdAt;
  final String excerpt;
  final String relevanceReason;
}

class CuratedResponse {
  const CuratedResponse({
    required this.insightTitle,
    required this.summary,
    required this.answer,
    required this.supportingRecords,
    required this.suggestedFollowUp,
  });

  final String insightTitle;
  final String summary;
  final String answer;
  final List<SupportingRecord> supportingRecords;
  final String suggestedFollowUp;
}
