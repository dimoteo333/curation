import '../../domain/entities/curated_response.dart';

class SupportingRecordDto {
  const SupportingRecordDto({
    required this.id,
    required this.source,
    required this.title,
    required this.createdAt,
    required this.excerpt,
    required this.relevanceReason,
  });

  factory SupportingRecordDto.fromJson(Map<String, dynamic> json) {
    return SupportingRecordDto(
      id: json['id'] as String,
      source: json['source'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      excerpt: json['excerpt'] as String,
      relevanceReason: json['relevance_reason'] as String,
    );
  }

  final String id;
  final String source;
  final String title;
  final DateTime createdAt;
  final String excerpt;
  final String relevanceReason;

  SupportingRecord toDomain() {
    return SupportingRecord(
      id: id,
      source: source,
      title: title,
      createdAt: createdAt,
      excerpt: excerpt,
      relevanceReason: relevanceReason,
    );
  }
}

class CuratedResponseDto {
  const CuratedResponseDto({
    required this.insightTitle,
    required this.summary,
    required this.answer,
    required this.supportingRecords,
    required this.suggestedFollowUp,
  });

  factory CuratedResponseDto.fromJson(Map<String, dynamic> json) {
    return CuratedResponseDto(
      insightTitle: json['insight_title'] as String,
      summary: json['summary'] as String,
      answer: json['answer'] as String,
      supportingRecords: (json['supporting_records'] as List<dynamic>)
          .map(
            (item) =>
                SupportingRecordDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      suggestedFollowUp: json['suggested_follow_up'] as String,
    );
  }

  final String insightTitle;
  final String summary;
  final String answer;
  final List<SupportingRecordDto> supportingRecords;
  final String suggestedFollowUp;

  CuratedResponse toDomain() {
    return CuratedResponse(
      insightTitle: insightTitle,
      summary: summary,
      answer: answer,
      supportingRecords: supportingRecords
          .map((record) => record.toDomain())
          .toList(),
      suggestedFollowUp: suggestedFollowUp,
      runtimeInfo: const CurationRuntimeInfo(
        path: CurationRuntimePath.remoteHarness,
        label: '원격 API 하네스 사용 중',
        message: 'FastAPI 개발 하네스를 통해 응답을 생성했습니다.',
      ),
    );
  }
}
