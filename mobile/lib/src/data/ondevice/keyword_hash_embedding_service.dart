import 'dart:math' as math;

import '../../domain/services/text_embedding_service.dart';

class KeywordHashEmbeddingService implements TextEmbeddingService {
  const KeywordHashEmbeddingService({this.dimensions = 96});

  final int dimensions;

  static final RegExp _tokenPattern = RegExp(r'[0-9A-Za-z가-힣]+');

  @override
  Future<List<double>> embed(String text) async {
    final vector = List<double>.filled(dimensions, 0);
    final tokens = _tokenPattern
        .allMatches(text.toLowerCase())
        .map((Match match) => match.group(0)!)
        .toList(growable: false);

    for (final token in tokens) {
      final tokenWeight = _tokenWeight(token);
      final bucket = token.codeUnits.fold<int>(0, (int hash, int unit) {
        return (hash * 31 + unit) % dimensions;
      });
      vector[bucket] += tokenWeight;

      if (token.length > 1) {
        final tailBucket = token.codeUnits.fold<int>(7, (int hash, int unit) {
          return (hash * 17 + unit) % dimensions;
        });
        vector[tailBucket] += tokenWeight * 0.5;
      }
    }

    final magnitude = math.sqrt(
      vector.fold<double>(0, (double sum, double value) => sum + value * value),
    );
    if (magnitude == 0) {
      return vector;
    }

    return vector
        .map((double value) => value / magnitude)
        .toList(growable: false);
  }

  double _tokenWeight(String token) {
    if (token.contains('무기력') ||
        token.contains('번아웃') ||
        token.contains('지침') ||
        token.contains('회복')) {
      return 2.0;
    }
    if (token.contains('산책') || token.contains('수면') || token.contains('휴식')) {
      return 1.6;
    }
    return 1.0;
  }
}
