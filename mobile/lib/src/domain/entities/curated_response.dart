enum CurationRuntimePath { onDeviceNative, onDeviceFallback, remoteHarness }

class CurationRuntimeInfo {
  const CurationRuntimeInfo({
    required this.path,
    required this.label,
    required this.message,
  });

  final CurationRuntimePath path;
  final String label;
  final String message;

  bool get isFallback => path == CurationRuntimePath.onDeviceFallback;
}

class SupportingRecord {
  const SupportingRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.createdAt,
    required this.excerpt,
    required this.relevanceReason,
    this.importSource,
    this.content,
    this.tags = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String source;
  final String title;
  final DateTime createdAt;
  final String excerpt;
  final String relevanceReason;
  final String? importSource;
  final String? content;
  final List<String> tags;
  final Map<String, dynamic> metadata;
}

class CuratedResponse {
  const CuratedResponse({
    required this.insightTitle,
    required this.summary,
    required this.answer,
    required this.supportingRecords,
    required this.suggestedFollowUp,
    this.runtimeInfo,
  });

  final String insightTitle;
  final String summary;
  final String answer;
  final List<SupportingRecord> supportingRecords;
  final String suggestedFollowUp;
  final CurationRuntimeInfo? runtimeInfo;
}
