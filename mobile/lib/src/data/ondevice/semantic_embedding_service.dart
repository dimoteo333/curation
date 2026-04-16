import 'dart:math' as math;

import '../../domain/services/text_embedding_service.dart';

class SemanticEmbeddingService implements TextEmbeddingService {
  const SemanticEmbeddingService({this.lexicalDimensions = 160});

  final int lexicalDimensions;

  static final RegExp _tokenPattern = RegExp(r'[0-9A-Za-z가-힣]+');
  static final RegExp _compactPattern = RegExp(r'[0-9A-Za-z가-힣]');

  static const List<_SemanticConcept> _concepts = <_SemanticConcept>[
    _SemanticConcept(
      key: '무기력',
      aliases: <String>['무기력', '기운없', '기력없', '의욕저하'],
      related: <String>['지침', '번아웃'],
    ),
    _SemanticConcept(
      key: '번아웃',
      aliases: <String>['번아웃', '소진', '탈진'],
      related: <String>['야근', '마감', '회복'],
    ),
    _SemanticConcept(
      key: '지침',
      aliases: <String>['지침', '지쳤', '피곤', '피로', '멍했'],
      related: <String>['휴식', '수면'],
    ),
    _SemanticConcept(
      key: '야근',
      aliases: <String>['야근', '퇴근 후', '늦게까지 일'],
      related: <String>['마감', '번아웃'],
    ),
    _SemanticConcept(
      key: '마감',
      aliases: <String>['마감', '프로젝트', '업무', '회의', '압박', '우선순위'],
      related: <String>['번아웃', '불안'],
    ),
    _SemanticConcept(
      key: '수면',
      aliases: <String>['수면', '잠', '낮잠', '늦게 자', '일찍 자', '불면'],
      related: <String>['집중', '회복'],
    ),
    _SemanticConcept(
      key: '휴식',
      aliases: <String>['휴식', '쉬', '쉼', '재충전'],
      related: <String>['회복', '수면'],
    ),
    _SemanticConcept(
      key: '회복',
      aliases: <String>['회복', '숨통', '맑아졌'],
      related: <String>['산책', '집중'],
    ),
    _SemanticConcept(
      key: '산책',
      aliases: <String>['산책', '한강', '걷', '걸었', '바깥 공기'],
      related: <String>['회복', '휴식'],
    ),
    _SemanticConcept(
      key: '집중',
      aliases: <String>['집중', '집중력', '리듬', '루틴', '스트레칭'],
      related: <String>['수면', '회복'],
    ),
    _SemanticConcept(
      key: '의욕',
      aliases: <String>['의욕', '아이디어', '사이드프로젝트', '사이드 프로젝트', '구현'],
      related: <String>['회복', '집중'],
    ),
    _SemanticConcept(
      key: '불안',
      aliases: <String>['불안', '걱정', '초조', '죄책감', '답답'],
      related: <String>['마감', '무기력'],
    ),
  ];

  static const List<_SemanticCluster> _clusters = <_SemanticCluster>[
    _SemanticCluster(
      key: 'fatigue',
      aliases: <String>[
        '무기력',
        '기운없',
        '기력없',
        '의욕저하',
        '의욕이 떨어',
        '지침',
        '지쳤',
        '피곤',
        '피로',
        '멍했',
        '멍하다',
      ],
      related: <String>['burnout', 'sleep', 'work_pressure'],
    ),
    _SemanticCluster(
      key: 'burnout',
      aliases: <String>['번아웃', '소진', '탈진', '과로', '숨통이 안', '마음이 따라오지'],
      related: <String>['fatigue', 'work_pressure'],
    ),
    _SemanticCluster(
      key: 'work_pressure',
      aliases: <String>[
        '야근',
        '마감',
        '업무',
        '회사',
        '프로젝트',
        '회의',
        '일정',
        '압박',
        '우선순위',
      ],
      related: <String>['burnout', 'fatigue', 'anxiety'],
    ),
    _SemanticCluster(
      key: 'sleep',
      aliases: <String>[
        '수면',
        '잠',
        '늦게 자',
        '일찍 자',
        '숙면',
        '불면',
        '기상',
        '졸림',
        '낮잠',
      ],
      related: <String>['fatigue', 'recovery', 'focus'],
    ),
    _SemanticCluster(
      key: 'recovery',
      aliases: <String>['회복', '휴식', '쉬', '쉼', '재충전', '숨통', '회복감', '맑아졌'],
      related: <String>['fatigue', 'sleep', 'focus', 'walking'],
    ),
    _SemanticCluster(
      key: 'walking',
      aliases: <String>['산책', '한강', '걷', '걸었', '바깥 공기', '공기를 쐬'],
      related: <String>['recovery', 'fatigue'],
    ),
    _SemanticCluster(
      key: 'focus',
      aliases: <String>['집중', '리듬', '루틴', '스트레칭', '정리', '집중력', '머리가 맑'],
      related: <String>['sleep', 'recovery', 'motivation'],
    ),
    _SemanticCluster(
      key: 'motivation',
      aliases: <String>['의욕', '아이디어', '사이드프로젝트', '사이드 프로젝트', '구현', '전환점'],
      related: <String>['recovery', 'focus'],
    ),
    _SemanticCluster(
      key: 'anxiety',
      aliases: <String>['불안', '걱정', '초조', '죄책감', '답답', '버거'],
      related: <String>['fatigue', 'work_pressure'],
    ),
  ];

  static final Map<String, int> _clusterIndexByKey = <String, int>{
    for (var index = 0; index < _clusters.length; index += 1)
      _clusters[index].key: index,
  };
  static final Map<String, int> _conceptIndexByKey = <String, int>{
    for (var index = 0; index < _concepts.length; index += 1)
      _concepts[index].key: index,
  };

  @override
  Future<List<double>> embed(String text) async {
    final normalizedText = _normalizeText(text);
    final tokens = _extractTokens(normalizedText);
    final compactText = normalizedText
        .split('')
        .where((String char) => _compactPattern.hasMatch(char))
        .join();

    final semanticOffset = _concepts.length;
    final lexicalOffset = _concepts.length + _clusters.length;
    final vector = List<double>.filled(lexicalOffset + lexicalDimensions, 0);
    if (tokens.isEmpty && compactText.isEmpty) {
      return vector;
    }

    final tokenFrequency = <String, int>{};
    for (final token in tokens) {
      tokenFrequency.update(token, (int value) => value + 1, ifAbsent: () => 1);
    }

    final conceptScores = _buildConceptScores(normalizedText, tokenFrequency);
    for (var index = 0; index < conceptScores.length; index += 1) {
      vector[index] = conceptScores[index];
    }

    final clusterScores = _buildClusterScores(normalizedText, tokenFrequency);
    for (var index = 0; index < clusterScores.length; index += 1) {
      vector[semanticOffset + index] = clusterScores[index];
    }
    for (final entry in tokenFrequency.entries) {
      final weight = _lexicalWeight(entry.key, entry.value);
      _addHashed(vector, lexicalOffset, entry.key, weight);

      for (final ngram in _tokenNgrams(entry.key)) {
        _addHashed(vector, lexicalOffset, 'gram:$ngram', weight * 0.36);
      }

      final matchedClusterKeys = _matchedClusterKeys(entry.key);
      for (final clusterKey in matchedClusterKeys) {
        _addHashed(vector, lexicalOffset, 'cluster:$clusterKey', weight * 0.54);
      }
    }

    for (final compactNgram in _compactNgrams(compactText)) {
      _addHashed(vector, lexicalOffset, 'compact:$compactNgram', 0.08);
    }

    return _normalize(vector);
  }

  List<double> _buildConceptScores(
    String normalizedText,
    Map<String, int> tokenFrequency,
  ) {
    final conceptScores = List<double>.filled(_concepts.length, 0);

    for (var index = 0; index < _concepts.length; index += 1) {
      final concept = _concepts[index];
      var score = 0.0;
      for (final alias in concept.aliases) {
        if (normalizedText.contains(alias)) {
          score += 1.8 + math.min(1.2, alias.length * 0.08);
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
        final relatedIndex = _conceptIndexByKey[relatedKey];
        if (relatedIndex != null) {
          conceptScores[relatedIndex] += score * 0.11;
        }
      }
    }

    return conceptScores;
  }

  List<double> _buildClusterScores(
    String normalizedText,
    Map<String, int> tokenFrequency,
  ) {
    final clusterScores = List<double>.filled(_clusters.length, 0);

    for (var index = 0; index < _clusters.length; index += 1) {
      final cluster = _clusters[index];
      var score = 0.0;
      for (final alias in cluster.aliases) {
        final exactWeight = normalizedText.contains(alias)
            ? 1.45 + math.min(1.1, alias.length * 0.08)
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
        final relatedIndex = _clusterIndexByKey[relatedKey];
        if (relatedIndex != null) {
          clusterScores[relatedIndex] += score * 0.12;
        }
      }
    }

    _applyContextBoosts(clusterScores);
    return clusterScores;
  }

  void _applyContextBoosts(List<double> clusterScores) {
    final fatigue = clusterScores[_clusterIndexByKey['fatigue']!];
    final burnout = clusterScores[_clusterIndexByKey['burnout']!];
    final workPressure = clusterScores[_clusterIndexByKey['work_pressure']!];
    final sleep = clusterScores[_clusterIndexByKey['sleep']!];
    final recovery = clusterScores[_clusterIndexByKey['recovery']!];
    final walking = clusterScores[_clusterIndexByKey['walking']!];

    if (fatigue > 0 && workPressure > 0) {
      clusterScores[_clusterIndexByKey['burnout']!] += 0.9;
      clusterScores[_clusterIndexByKey['recovery']!] += 0.2;
    }
    if (sleep > 0 && fatigue > 0) {
      clusterScores[_clusterIndexByKey['focus']!] += 0.42;
      clusterScores[_clusterIndexByKey['recovery']!] += 0.18;
    }
    if (recovery > 0 && walking > 0) {
      clusterScores[_clusterIndexByKey['fatigue']!] += 0.08;
      clusterScores[_clusterIndexByKey['focus']!] += 0.18;
    }
    if (burnout > 0 && recovery > 0) {
      clusterScores[_clusterIndexByKey['motivation']!] += 0.22;
    }
  }

  Iterable<String> _matchedClusterKeys(String token) sync* {
    for (final cluster in _clusters) {
      if (cluster.aliases.any(
        (String alias) => _tokenSemanticallyOverlaps(token, alias),
      )) {
        yield cluster.key;
      }
    }
  }

  bool _tokenSemanticallyOverlaps(String token, String alias) {
    if (token == alias) {
      return true;
    }
    if (token.length < 2 || alias.length < 2) {
      return false;
    }
    return token.contains(alias) || alias.contains(token);
  }

  double _lexicalWeight(String token, int frequency) {
    final lengthFactor = 1.0 + math.min(1.1, token.length * 0.08);
    final frequencyFactor = 1.0 + math.log(frequency + 1) / 2;
    final semanticBonus = _matchedClusterKeys(token).isEmpty ? 1.0 : 1.25;
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
    vector[lexicalOffset + secondaryBucket] += weight * 0.25;
  }

  List<String> _extractTokens(String normalizedText) {
    return _tokenPattern
        .allMatches(normalizedText)
        .map((Match match) => match.group(0)!)
        .where((String token) => token.length > 1)
        .toList(growable: false);
  }

  Iterable<String> _tokenNgrams(String token) sync* {
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

  Iterable<String> _compactNgrams(String compactText) sync* {
    if (compactText.length < 3) {
      return;
    }

    for (var start = 0; start <= compactText.length - 3; start += 2) {
      yield compactText.substring(start, start + 3);
    }
  }

  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
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
