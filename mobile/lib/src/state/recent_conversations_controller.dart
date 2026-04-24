import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_preference_keys.dart';
import '../domain/entities/curated_response.dart';
import '../providers.dart';

class RecentConversation {
  const RecentConversation({
    required this.question,
    required this.preview,
    required this.askedAt,
    this.runtimePath,
    this.runtimeBadgeLabel,
  });

  final String question;
  final String preview;
  final DateTime askedAt;
  final CurationRuntimePath? runtimePath;
  final String? runtimeBadgeLabel;

  String? get resolvedRuntimeBadgeLabel {
    final label = runtimeBadgeLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return runtimePath?.runtimeBadgeLabel;
  }

  bool get hasRuntimeBadge => resolvedRuntimeBadgeLabel != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'question': question,
    'preview': preview,
    'asked_at': askedAt.toIso8601String(),
    if (runtimePath != null) 'runtime_path': runtimePath!.name,
    if (resolvedRuntimeBadgeLabel != null)
      'runtime_badge_label': resolvedRuntimeBadgeLabel,
  };

  factory RecentConversation.fromJson(Map<String, dynamic> json) {
    final runtimePath = _runtimePathFromJson(json['runtime_path']);
    return RecentConversation(
      question: json['question'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      askedAt:
          DateTime.tryParse(json['asked_at'] as String? ?? '') ??
          DateTime.now(),
      runtimePath: runtimePath,
      runtimeBadgeLabel:
          _runtimeBadgeLabelFromJson(json['runtime_badge_label']) ??
          runtimePath?.runtimeBadgeLabel,
    );
  }

  static CurationRuntimePath? _runtimePathFromJson(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    for (final path in CurationRuntimePath.values) {
      if (path.name == value) {
        return path;
      }
    }
    return null;
  }

  static String? _runtimeBadgeLabelFromJson(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class RecentConversationsController extends Notifier<List<RecentConversation>> {
  static const int _maxItems = 8;

  @override
  List<RecentConversation> build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(AppPreferenceKeys.recentConversations);
    if (raw == null || raw.isEmpty) {
      return const <RecentConversation>[];
    }

    final decoded = _decodeStoredItems(raw);
    if (decoded == null) {
      return const <RecentConversation>[];
    }

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) =>
              RecentConversation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> recordConversation({
    required String question,
    required CuratedResponse response,
    DateTime Function()? nowProvider,
  }) async {
    final now = (nowProvider ?? DateTime.now).call();
    final item = RecentConversation(
      question: question,
      preview: _previewFromResponse(response),
      askedAt: now,
      runtimePath: response.runtimeInfo?.path,
      runtimeBadgeLabel: response.runtimeInfo?.runtimeBadgeLabel,
    );
    final next = <RecentConversation>[
      item,
      ...state.where((existing) => existing.question != question),
    ];
    state = next.take(_maxItems).toList(growable: false);
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          AppPreferenceKeys.recentConversations,
          jsonEncode(
            state.map((item) => item.toJson()).toList(growable: false),
          ),
        );
  }

  String _previewFromResponse(CuratedResponse response) {
    final base = response.summary.trim().isNotEmpty
        ? response.summary.trim()
        : response.answer.trim();
    return base.replaceAll('\n', ' ');
  }

  List<dynamic>? _decodeStoredItems(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List<dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
