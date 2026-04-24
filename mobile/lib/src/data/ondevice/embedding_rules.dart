import 'dart:convert';

import 'package:flutter/services.dart';

const String embeddingRulesAssetPath = 'assets/config/embedding_rules.json';

Future<EmbeddingRules>? _sharedEmbeddingRulesFuture;

Future<EmbeddingRules> loadSharedEmbeddingRules({AssetBundle? bundle}) {
  if (bundle != null) {
    return _loadEmbeddingRules(bundle);
  }
  return _sharedEmbeddingRulesFuture ??= _loadEmbeddingRules(rootBundle);
}

Future<EmbeddingRules> _loadEmbeddingRules(AssetBundle bundle) async {
  final rawJson = await bundle.loadString(embeddingRulesAssetPath);
  final payload = jsonDecode(rawJson) as Map<String, dynamic>;
  return EmbeddingRules.fromJson(payload);
}

class EmbeddingRules {
  const EmbeddingRules({
    required this.version,
    required this.normalization,
    required this.topicRules,
    required this.semanticClusters,
    required this.stopTokens,
  });

  factory EmbeddingRules.fromJson(Map<String, dynamic> json) {
    return EmbeddingRules(
      version: json['version'] as int,
      normalization: EmbeddingNormalization.fromJson(
        json['normalization'] as Map<String, dynamic>,
      ),
      topicRules:
          (json['topic_rules'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(EmbeddingTopicRule.fromJson)
              .toList(growable: false),
      semanticClusters:
          (json['semantic_clusters'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(EmbeddingSemanticCluster.fromJson)
              .toList(growable: false),
      stopTokens:
          (json['stop_tokens'] as List<dynamic>)
              .cast<String>()
              .toSet(),
    );
  }

  final int version;
  final EmbeddingNormalization normalization;
  final List<EmbeddingTopicRule> topicRules;
  final List<EmbeddingSemanticCluster> semanticClusters;
  final Set<String> stopTokens;
}

class EmbeddingNormalization {
  const EmbeddingNormalization({
    required this.lowercase,
    required this.collapseWhitespace,
    required this.tokenPattern,
    required this.compactPattern,
    required this.numericPattern,
    required this.minTokenLength,
  });

  factory EmbeddingNormalization.fromJson(Map<String, dynamic> json) {
    return EmbeddingNormalization(
      lowercase: json['lowercase'] as bool,
      collapseWhitespace: json['collapse_whitespace'] as bool,
      tokenPattern: json['token_pattern'] as String,
      compactPattern: json['compact_pattern'] as String,
      numericPattern: json['numeric_pattern'] as String,
      minTokenLength: json['min_token_length'] as int,
    );
  }

  final bool lowercase;
  final bool collapseWhitespace;
  final String tokenPattern;
  final String compactPattern;
  final String numericPattern;
  final int minTokenLength;
}

class EmbeddingTopicRule {
  const EmbeddingTopicRule({
    required this.key,
    required this.aliases,
    required this.related,
  });

  factory EmbeddingTopicRule.fromJson(Map<String, dynamic> json) {
    return EmbeddingTopicRule(
      key: json['key'] as String,
      aliases: (json['aliases'] as List<dynamic>).cast<String>(),
      related: (json['related'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
    );
  }

  final String key;
  final List<String> aliases;
  final List<String> related;
}

class EmbeddingSemanticCluster {
  const EmbeddingSemanticCluster({
    required this.key,
    required this.aliases,
    required this.related,
  });

  factory EmbeddingSemanticCluster.fromJson(Map<String, dynamic> json) {
    return EmbeddingSemanticCluster(
      key: json['key'] as String,
      aliases: (json['aliases'] as List<dynamic>).cast<String>(),
      related: (json['related'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
    );
  }

  final String key;
  final List<String> aliases;
  final List<String> related;
}
