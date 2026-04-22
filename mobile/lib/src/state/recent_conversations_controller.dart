import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/curated_response.dart';
import '../providers.dart';

class RecentConversation {
  const RecentConversation({
    required this.question,
    required this.preview,
    required this.askedAt,
  });

  final String question;
  final String preview;
  final DateTime askedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'question': question,
    'preview': preview,
    'asked_at': askedAt.toIso8601String(),
  };

  factory RecentConversation.fromJson(Map<String, dynamic> json) {
    return RecentConversation(
      question: json['question'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      askedAt:
          DateTime.tryParse(json['asked_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class RecentConversationsController extends Notifier<List<RecentConversation>> {
  static const String _storageKey = 'app.recent_conversations';
  static const int _maxItems = 8;

  @override
  List<RecentConversation> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <RecentConversation>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
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
    );
    final next = <RecentConversation>[
      item,
      ...state.where((existing) => existing.question != question),
    ];
    state = next.take(_maxItems).toList(growable: false);
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _storageKey,
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
}
