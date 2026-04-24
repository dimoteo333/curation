import 'dart:math' as math;

import '../../domain/services/text_embedding_service.dart';
import 'embedding_rules.dart';

Future<_SemanticRuntimeRules>? _sharedRuntimeRulesFuture;

/// Deterministic Dart semantic embedding fallback used when native embedding is unavailable.
class SemanticEmbeddingService implements TextEmbeddingService {
  const SemanticEmbeddingService({this.lexicalDimensions = 160});

  final int lexicalDimensions;

  static const int _defaultSuggestedTagCount = 5;

  @override
  Future<List<double>> embed(String text) async {
    final rules = await _loadRules();
    final normalizedText = _normalizeText(text, rules);
    final tokens = _extractTokens(normalizedText, rules);
    final compactText = normalizedText
        .split('')
        .where((String char) => rules.compactPattern.hasMatch(char))
        .join();

    final semanticOffset = rules.concepts.length;
    final lexicalOffset = rules.concepts.length + rules.clusters.length;
    final vector = List<double>.filled(lexicalOffset + lexicalDimensions, 0);
    if (tokens.isEmpty && compactText.isEmpty) {
      return vector;
    }

    final tokenFrequency = <String, int>{};
    for (final token in tokens) {
      tokenFrequency.update(token, (int value) => value + 1, ifAbsent: () => 1);
    }

    final conceptScores = _buildConceptScores(
      rules,
      normalizedText,
      tokenFrequency,
    );
    for (var index = 0; index < conceptScores.length; index += 1) {
      vector[index] = conceptScores[index];
    }

    final clusterScores = _buildClusterScores(
      rules,
      normalizedText,
      tokenFrequency,
    );
    for (var index = 0; index < clusterScores.length; index += 1) {
      vector[semanticOffset + index] = clusterScores[index];
    }

    for (final entry in tokenFrequency.entries) {
      final weight = _lexicalWeight(rules, entry.key, entry.value);
      _addHashed(vector, lexicalOffset, entry.key, weight);

      for (final ngram in _tokenNgrams(entry.key)) {
        _addHashed(vector, lexicalOffset, 'gram:$ngram', weight * 0.22);
      }

      final matchedClusterKeys = _matchedClusterKeys(rules, entry.key);
      for (final clusterKey in matchedClusterKeys) {
        _addHashed(vector, lexicalOffset, 'cluster:$clusterKey', weight * 0.34);
      }
    }

    for (final compactNgram in _compactNgrams(compactText)) {
      _addHashed(vector, lexicalOffset, 'compact:$compactNgram', 0.04);
    }

    return _normalize(vector);
  }

  static Future<List<String>> suggestTags(
    String text, {
    int maxTags = _defaultSuggestedTagCount,
  }) async {
    final rules = await _sharedRuntimeRules();
    final normalizedText = _normalizeStatic(text, rules);
    if (normalizedText.isEmpty) {
      return const <String>[];
    }

    final tokenFrequency = <String, int>{};
    for (final token in _extractTokens(normalizedText, rules)) {
      tokenFrequency.update(token, (int value) => value + 1, ifAbsent: () => 1);
    }

    final scores = <String, double>{};
    for (final concept in rules.concepts) {
      var score = 0.0;
      for (final alias in concept.aliases) {
        if (normalizedText.contains(alias)) {
          score += 2.0 + math.min(1.1, alias.length * 0.07);
          continue;
        }

        for (final entry in tokenFrequency.entries) {
          if (_tokenSemanticallyOverlapsStatic(entry.key, alias)) {
            score += (0.45 + alias.length * 0.02) * entry.value;
          }
        }
      }

      if (score > 0) {
        scores[concept.key] = score;
      }
    }

    final supplementalTokens =
        tokenFrequency.entries
            .where(
              (MapEntry<String, int> entry) =>
                  !_looksNumeric(entry.key, rules) &&
                  !_isCommonStopToken(entry.key, rules),
            )
            .map(
              (MapEntry<String, int> entry) => MapEntry<String, double>(
                entry.key,
                entry.value * (1.0 + math.min(0.8, entry.key.length * 0.06)),
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => right.value.compareTo(left.value));

    final ordered = scores.entries.toList(growable: false)
      ..sort((left, right) {
        final byScore = right.value.compareTo(left.value);
        if (byScore != 0) {
          return byScore;
        }
        return left.key.compareTo(right.key);
      });

    final tags = <String>[];
    for (final entry in ordered) {
      tags.add(entry.key);
      if (tags.length >= maxTags) {
        return tags;
      }
    }

    for (final entry in supplementalTokens) {
      if (tags.any(
        (String tag) =>
            tag == entry.key ||
            tag.contains(entry.key) ||
            entry.key.contains(tag),
      )) {
        continue;
      }
      tags.add(entry.key);
      if (tags.length >= maxTags) {
        break;
      }
    }

    return tags;
  }

  Future<_SemanticRuntimeRules> _loadRules() {
    return _sharedRuntimeRules();
  }

  static Future<_SemanticRuntimeRules> _sharedRuntimeRules() {
    return _sharedRuntimeRulesFuture ??= _loadRuntimeRules();
  }

  static Future<_SemanticRuntimeRules> _loadRuntimeRules() async {
    final sharedRules = await loadSharedEmbeddingRules();
    return _SemanticRuntimeRules.fromShared(sharedRules);
  }

  List<double> _buildConceptScores(
    _SemanticRuntimeRules rules,
    String normalizedText,
    Map<String, int> tokenFrequency,
  ) {
    final conceptScores = List<double>.filled(rules.concepts.length, 0);

    for (var index = 0; index < rules.concepts.length; index += 1) {
      final concept = rules.concepts[index];
      var score = 0.0;
      for (final alias in concept.aliases) {
        if (normalizedText.contains(alias)) {
          score += 2.35 + math.min(1.35, alias.length * 0.09);
          continue;
        }

        for (final entry in tokenFrequency.entries) {
          if (_tokenSemanticallyOverlaps(entry.key, alias)) {
            score += (0.42 + alias.length * 0.02) * entry.value;
          }
        }
      }

      if (score == 0) {
        continue;
      }

      conceptScores[index] += math.sqrt(score) * 1.15;
      for (final relatedKey in concept.related) {
        final relatedIndex = rules.conceptIndexByKey[relatedKey];
        if (relatedIndex != null) {
          conceptScores[relatedIndex] += score * 0.11;
        }
      }
    }

    return conceptScores;
  }

  List<double> _buildClusterScores(
    _SemanticRuntimeRules rules,
    String normalizedText,
    Map<String, int> tokenFrequency,
  ) {
    final clusterScores = List<double>.filled(rules.clusters.length, 0);

    for (var index = 0; index < rules.clusters.length; index += 1) {
      final cluster = rules.clusters[index];
      var score = 0.0;
      for (final alias in cluster.aliases) {
        final exactWeight = normalizedText.contains(alias)
            ? 2.15 + math.min(1.25, alias.length * 0.08)
            : 0.0;
        if (exactWeight > 0) {
          score += exactWeight;
          continue;
        }

        for (final entry in tokenFrequency.entries) {
          final token = entry.key;
          if (_tokenSemanticallyOverlaps(token, alias)) {
            score += (0.34 + alias.length * 0.025) * entry.value;
          }
        }
      }

      if (score == 0) {
        continue;
      }

      clusterScores[index] += math.sqrt(score);
      for (final relatedKey in cluster.related) {
        final relatedIndex = rules.clusterIndexByKey[relatedKey];
        if (relatedIndex != null) {
          clusterScores[relatedIndex] += score * 0.12;
        }
      }
    }

    _applyContextBoosts(clusterScores, rules);
    return clusterScores;
  }

  void _applyContextBoosts(
    List<double> clusterScores,
    _SemanticRuntimeRules rules,
  ) {
    final fatigue = clusterScores[rules.clusterIndexByKey['fatigue']!];
    final burnout = clusterScores[rules.clusterIndexByKey['burnout']!];
    final workPressure = clusterScores[rules.clusterIndexByKey['work_pressure']!];
    final sleep = clusterScores[rules.clusterIndexByKey['sleep']!];
    final recovery = clusterScores[rules.clusterIndexByKey['recovery']!];
    final walking = clusterScores[rules.clusterIndexByKey['walking']!];
    final exercise = clusterScores[rules.clusterIndexByKey['exercise']!];
    final health = clusterScores[rules.clusterIndexByKey['health']!];
    final relationships = clusterScores[rules.clusterIndexByKey['relationships']!];
    final reflection = clusterScores[rules.clusterIndexByKey['reflection']!];
    final creativity = clusterScores[rules.clusterIndexByKey['creativity']!];

    if (fatigue > 0 && workPressure > 0) {
      clusterScores[rules.clusterIndexByKey['burnout']!] += 0.9;
      clusterScores[rules.clusterIndexByKey['recovery']!] += 0.2;
    }
    if (sleep > 0 && fatigue > 0) {
      clusterScores[rules.clusterIndexByKey['focus']!] += 0.42;
      clusterScores[rules.clusterIndexByKey['recovery']!] += 0.18;
    }
    if (recovery > 0 && walking > 0) {
      clusterScores[rules.clusterIndexByKey['fatigue']!] += 0.08;
      clusterScores[rules.clusterIndexByKey['focus']!] += 0.18;
    }
    if (burnout > 0 && recovery > 0) {
      clusterScores[rules.clusterIndexByKey['motivation']!] += 0.22;
    }
    if (exercise > 0 && health > 0) {
      clusterScores[rules.clusterIndexByKey['recovery']!] += 0.26;
      clusterScores[rules.clusterIndexByKey['focus']!] += 0.18;
    }
    if (relationships > 0 && reflection > 0) {
      clusterScores[rules.clusterIndexByKey['recovery']!] += 0.18;
    }
    if (relationships > 0 &&
        clusterScores[rules.clusterIndexByKey['anxiety']!] > 0) {
      clusterScores[rules.clusterIndexByKey['reflection']!] += 0.22;
    }
    if (creativity > 0 && recovery > 0) {
      clusterScores[rules.clusterIndexByKey['motivation']!] += 0.24;
    }
  }

  Iterable<String> _matchedClusterKeys(
    _SemanticRuntimeRules rules,
    String token,
  ) sync* {
    for (final cluster in rules.clusters) {
      if (cluster.aliases.any(
        (String alias) => _tokenSemanticallyOverlaps(token, alias),
      )) {
        yield cluster.key;
      }
    }
  }

  bool _tokenSemanticallyOverlaps(String token, String alias) {
    return _tokenSemanticallyOverlapsStatic(token, alias);
  }

  static bool _tokenSemanticallyOverlapsStatic(String token, String alias) {
    if (token == alias) {
      return true;
    }
    if (token.length < 2 || alias.length < 2) {
      return false;
    }
    return token.contains(alias) || alias.contains(token);
  }

  double _lexicalWeight(
    _SemanticRuntimeRules rules,
    String token,
    int frequency,
  ) {
    final lengthFactor = 1.0 + math.min(0.7, token.length * 0.05);
    final frequencyFactor = 1.0 + math.log(frequency + 1) / 3;
    final semanticBonus =
        _matchedClusterKeys(rules, token).isEmpty ? 1.0 : 1.12;
    return lengthFactor * frequencyFactor * semanticBonus;
  }

  void _addHashed(
    List<double> vector,
    int lexicalOffset,
    String key,
    double weight,
  ) {
    final lexicalBucket = key.codeUnits.fold<int>(19, (int hash, int unit) {
      return (hash * 37 + unit) % lexicalDimensions;
    });
    vector[lexicalOffset + lexicalBucket] += weight;

    final secondaryBucket = key.codeUnits.fold<int>(7, (int hash, int unit) {
      return (hash * 29 + unit) % lexicalDimensions;
    });
    vector[lexicalOffset + secondaryBucket] += weight * 0.14;
  }

  static List<String> _extractTokens(
    String normalizedText,
    _SemanticRuntimeRules rules,
  ) {
    return rules.tokenPattern
        .allMatches(normalizedText)
        .map((Match match) => match.group(0)!)
        .where((String token) => token.length >= rules.minTokenLength)
        .toList(growable: false);
  }

  static Iterable<String> _tokenNgrams(String token) sync* {
    final compactToken = token.replaceAll(' ', '');
    if (compactToken.length < 2) {
      return;
    }

    for (var size = 2; size <= math.min(3, compactToken.length); size += 1) {
      for (var start = 0; start <= compactToken.length - size; start += 1) {
        yield compactToken.substring(start, start + size);
      }
    }
  }

  static Iterable<String> _compactNgrams(String compactText) sync* {
    if (compactText.length < 3) {
      return;
    }

    for (var start = 0; start <= compactText.length - 3; start += 2) {
      yield compactText.substring(start, start + 3);
    }
  }

  String _normalizeText(String text, _SemanticRuntimeRules rules) {
    return _normalizeStatic(text, rules);
  }

  static String _normalizeStatic(String text, _SemanticRuntimeRules rules) {
    var normalized = text;
    if (rules.lowercase) {
      normalized = normalized.toLowerCase();
    }
    if (rules.collapseWhitespace) {
      normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return normalized;
  }

  static bool _looksNumeric(String value, _SemanticRuntimeRules rules) {
    return rules.numericPattern.hasMatch(value);
  }

  static bool _isCommonStopToken(String token, _SemanticRuntimeRules rules) {
    return rules.stopTokens.contains(token);
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
}

class _SemanticRuntimeRules {
  const _SemanticRuntimeRules({
    required this.lowercase,
    required this.collapseWhitespace,
    required this.minTokenLength,
    required this.tokenPattern,
    required this.compactPattern,
    required this.numericPattern,
    required this.concepts,
    required this.clusters,
    required this.conceptIndexByKey,
    required this.clusterIndexByKey,
    required this.stopTokens,
  });

  factory _SemanticRuntimeRules.fromShared(EmbeddingRules rules) {
    final concepts =
        rules.topicRules
            .map(
              (EmbeddingTopicRule rule) => _SemanticConcept(
                key: rule.key,
                aliases: rule.aliases,
                related: rule.related,
              ),
            )
            .toList(growable: false);
    final clusters =
        rules.semanticClusters
            .map(
              (EmbeddingSemanticCluster cluster) => _SemanticCluster(
                key: cluster.key,
                aliases: cluster.aliases,
                related: cluster.related,
              ),
            )
            .toList(growable: false);
    return _SemanticRuntimeRules(
      lowercase: rules.normalization.lowercase,
      collapseWhitespace: rules.normalization.collapseWhitespace,
      minTokenLength: rules.normalization.minTokenLength,
      tokenPattern: RegExp(rules.normalization.tokenPattern),
      compactPattern: RegExp(rules.normalization.compactPattern),
      numericPattern: RegExp(rules.normalization.numericPattern),
      concepts: concepts,
      clusters: clusters,
      conceptIndexByKey: <String, int>{
        for (var index = 0; index < concepts.length; index += 1)
          concepts[index].key: index,
      },
      clusterIndexByKey: <String, int>{
        for (var index = 0; index < clusters.length; index += 1)
          clusters[index].key: index,
      },
      stopTokens: rules.stopTokens,
    );
  }

  final bool lowercase;
  final bool collapseWhitespace;
  final int minTokenLength;
  final RegExp tokenPattern;
  final RegExp compactPattern;
  final RegExp numericPattern;
  final List<_SemanticConcept> concepts;
  final List<_SemanticCluster> clusters;
  final Map<String, int> conceptIndexByKey;
  final Map<String, int> clusterIndexByKey;
  final Set<String> stopTokens;
}

class _SemanticCluster {
  const _SemanticCluster({
    required this.key,
    required this.aliases,
    required this.related,
  });

  final String key;
  final List<String> aliases;
  final List<String> related;
}

class _SemanticConcept {
  const _SemanticConcept({
    required this.key,
    required this.aliases,
    required this.related,
  });

  final String key;
  final List<String> aliases;
  final List<String> related;
}
