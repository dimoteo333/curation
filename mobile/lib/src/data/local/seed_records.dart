import '../../domain/entities/life_record.dart';

LifeRecord _seedRecord({
  required String id,
  required String source,
  required String importSource,
  required String title,
  required String content,
  required DateTime createdAt,
  required List<String> tags,
  required Map<String, dynamic> metadata,
}) {
  return LifeRecord(
    id: id,
    sourceId: id,
    source: source,
    importSource: importSource,
    title: title,
    content: content,
    createdAt: createdAt,
    tags: tags,
    metadata: <String, dynamic>{'seed': true, ...metadata},
  );
}

final List<LifeRecord> seededLifeRecords = <LifeRecord>[
  _seedRecord(
    id: 'diary-burnout-feb-2024',
    source: '일기',
    importSource: 'diary',
    title: '야근이 길어지던 주간 회고',
    content:
        '이번 주는 계속 야근이 이어져서 무기력했다. 퇴근 후에는 말할 힘도 없었다. 토요일 아침에 한강을 천천히 걷고 낮잠을 잤더니 조금 회복되는 느낌이 있었다.',
    createdAt: DateTime(2024, 2, 18, 21),
    tags: <String>['무기력', '야근', '산책', '회복'],
    metadata: <String, dynamic>{
      'mood': 'drained',
      'energy': 2,
      'topic': 'work-burnout',
      'season': 'late-winter',
    },
  ),
  _seedRecord(
    id: 'calendar-restorative-sat-2024',
    source: '캘린더',
    importSource: 'calendar',
    title: '토요일 오전 산책',
    content:
        '한강 산책 50분. 지난주 내내 지쳤던 상태에서 일부러 바깥 공기를 쐬기로 했다. 산책 뒤에는 머리가 조금 맑아졌다.',
    createdAt: DateTime(2024, 2, 17, 9, 30),
    tags: <String>['산책', '휴식', '지침'],
    metadata: <String, dynamic>{
      'mood': 'steady',
      'energy': 4,
      'topic': 'recovery-routine',
      'weather': 'clear',
    },
  ),
  _seedRecord(
    id: 'memo-side-project-spring-2023',
    source: '메모',
    importSource: 'note',
    title: '작은 사이드 프로젝트 아이디어',
    content:
        '의욕이 떨어질 때는 새로운 아이디어를 짧게라도 구현해보면 회복이 빨랐다. 부담이 적은 주말 프로젝트가 생각보다 큰 전환점이 됐다. 완성도보다 시작 속도가 중요하다는 걸 다시 적어 둔다.',
    createdAt: DateTime(2023, 3, 9, 20, 15),
    tags: <String>['의욕', '사이드프로젝트', '회복', '창작'],
    metadata: <String, dynamic>{
      'mood': 'hopeful',
      'energy': 6,
      'topic': 'creative-project',
      'format': 'idea-note',
    },
  ),
  _seedRecord(
    id: 'diary-routine-reset-2023',
    source: '일기',
    importSource: 'diary',
    title: '생활 리듬을 되돌린 날',
    content:
        '이틀 연속 늦게 자고 나니 하루 종일 멍했다. 그날은 운동 대신 일찍 자고 아침에 가볍게 스트레칭했더니 집중력이 돌아왔다. 수면 시간이 짧아지면 예민해진다는 사실을 또 확인했다.',
    createdAt: DateTime(2023, 11, 2, 22, 10),
    tags: <String>['수면', '집중', '회복'],
    metadata: <String, dynamic>{
      'mood': 'foggy',
      'energy': 3,
      'topic': 'sleep-pattern',
      'sleep_hours': 5,
    },
  ),
  _seedRecord(
    id: 'diary-project-pressure-2022',
    source: '일기',
    importSource: 'diary',
    title: '프로젝트 마감 직전의 기록',
    content:
        '마감이 가까워지자 번아웃 비슷한 감각이 왔다. 해야 할 일은 많았지만 마음이 따라오지 않았다. 우선순위를 줄이고 회의 두 개를 미루자 조금 숨통이 트였다.',
    createdAt: DateTime(2022, 10, 14, 18, 40),
    tags: <String>['번아웃', '마감', '우선순위', '회복'],
    metadata: <String, dynamic>{
      'mood': 'pressured',
      'energy': 2,
      'topic': 'work-pressure',
      'team_context': 'product-launch',
    },
  ),
  _seedRecord(
    id: 'diary-sleep-apr-2024',
    source: '일기',
    importSource: 'diary',
    title: '새벽 세 시에 다시 깬 밤',
    content:
        '새벽 세 시쯤 눈이 떠져서 한참 뒤척였다. 다음 날 회의에서 말이 자꾸 꼬였고 사소한 질문에도 예민하게 반응했다. 저녁에 카페인을 줄이니 조금 안정됐다.',
    createdAt: DateTime(2024, 4, 11, 7, 20),
    tags: <String>['수면', '불안', '집중'],
    metadata: <String, dynamic>{
      'mood': 'fragile',
      'energy': 2,
      'topic': 'sleep-anxiety',
      'sleep_hours': 4,
    },
  ),
  _seedRecord(
    id: 'memo-running-reset-2024',
    source: '메모',
    importSource: 'note',
    title: '퇴근 후 20분 러닝 메모',
    content:
        '퇴근 후 20분만 천천히 달려도 머리가 정리됐다. 몸은 피곤했지만 샤워를 하고 나면 일 이야기에서 한 걸음 떨어질 수 있었다. 운동은 시간을 더 쓰는 일이 아니라 회복을 앞당기는 일이었다.',
    createdAt: DateTime(2024, 5, 3, 22, 5),
    tags: <String>['운동', '건강', '회복'],
    metadata: <String, dynamic>{
      'mood': 'lighter',
      'energy': 5,
      'topic': 'exercise-health',
      'duration_min': 20,
    },
  ),
  _seedRecord(
    id: 'diary-relationship-apology-2024',
    source: '일기',
    importSource: 'diary',
    title: '친구와의 대화가 풀린 저녁',
    content:
        '괜히 서운했던 마음을 오래 끌고 갔는데, 저녁에 차분히 이야기하니 오해가 많이 풀렸다. 말하지 않으면 상대가 다 알 거라고 기대했던 내가 더 지쳐 있었다. 대화 뒤에는 몸의 긴장도 조금 내려갔다.',
    createdAt: DateTime(2024, 6, 21, 23, 0),
    tags: <String>['관계', '대화', '회복'],
    metadata: <String, dynamic>{
      'mood': 'relieved',
      'energy': 5,
      'topic': 'relationship-repair',
      'person': 'friend',
    },
  ),
  _seedRecord(
    id: 'calendar-family-lunch-2024',
    source: '캘린더',
    importSource: 'calendar',
    title: '엄마와 점심',
    content:
        '엄마와 점심을 먹으며 최근에 힘들었던 이야기를 조금 꺼냈다. 조언보다도 그냥 들어주는 시간이 필요했다는 걸 알았다. 집에 돌아오는 길에는 마음이 덜 거칠었다.',
    createdAt: DateTime(2024, 7, 7, 13, 10),
    tags: <String>['관계', '가족', '회복'],
    metadata: <String, dynamic>{
      'mood': 'softer',
      'energy': 4,
      'topic': 'family-support',
      'person': 'mother',
    },
  ),
  _seedRecord(
    id: 'diary-growth-course-2024',
    source: '일기',
    importSource: 'diary',
    title: '작은 공부 루틴이 생긴 주',
    content:
        '하루 15분씩 강의를 듣고 메모를 남겼다. 양은 적었지만 매일 쌓이니 스스로를 덜 자책하게 됐다. 성장에는 큰 결심보다 작게 이어지는 리듬이 더 중요했다.',
    createdAt: DateTime(2024, 8, 12, 21, 50),
    tags: <String>['성장', '습관', '기록'],
    metadata: <String, dynamic>{
      'mood': 'steady',
      'energy': 6,
      'topic': 'personal-growth',
      'duration_min': 15,
    },
  ),
  _seedRecord(
    id: 'memo-writing-draft-2024',
    source: '메모',
    importSource: 'note',
    title: '에세이 초안을 밀어붙인 밤',
    content:
        '완성되지 않은 문장을 오래 붙잡고 있었지만, 세 문단만 쓰기로 하니 오히려 끝까지 갔다. 창작이 막힐 때는 잘 쓰는 것보다 계속 이어 가는 감각이 중요했다. 초안을 남긴 날은 이상하게 잠도 조금 더 잘 왔다.',
    createdAt: DateTime(2024, 9, 2, 0, 10),
    tags: <String>['창작', '글쓰기', '의욕'],
    metadata: <String, dynamic>{
      'mood': 'engaged',
      'energy': 6,
      'topic': 'creative-writing',
      'format': 'essay-draft',
    },
  ),
  _seedRecord(
    id: 'diary-burnout-nov-2024',
    source: '일기',
    importSource: 'diary',
    title: '쉬어도 피곤한 주말',
    content:
        '토요일 내내 누워 있었는데도 피로가 풀리지 않았다. 쉬는 시간에도 머릿속에서 업무 대화가 계속 재생됐다. 일정을 줄이는 것만큼 머리를 비우는 전환 행동이 필요하다고 적어 두었다.',
    createdAt: DateTime(2024, 11, 16, 20, 30),
    tags: <String>['번아웃', '피로', '휴식'],
    metadata: <String, dynamic>{
      'mood': 'depleted',
      'energy': 1,
      'topic': 'burnout-weekend',
      'rest_quality': 'low',
    },
  ),
  _seedRecord(
    id: 'calendar-gym-morning-2025',
    source: '캘린더',
    importSource: 'calendar',
    title: '아침 헬스장',
    content:
        '출근 전에 가볍게 근력 운동을 했다. 오전 회의에서 집중이 덜 흔들렸고 점심 이후에도 덜 처졌다. 몸을 먼저 깨우면 생각도 덜 뒤엉킨다는 느낌이 있었다.',
    createdAt: DateTime(2025, 1, 23, 7, 15),
    tags: <String>['운동', '집중', '건강'],
    metadata: <String, dynamic>{
      'mood': 'focused',
      'energy': 7,
      'topic': 'morning-exercise',
      'duration_min': 35,
    },
  ),
  _seedRecord(
    id: 'diary-creative-retreat-2025',
    source: '일기',
    importSource: 'diary',
    title: '혼자 카페에 앉아 초안을 정리한 오후',
    content:
        '사람 많은 일정에서 잠시 빠져나와 카페에 앉으니 머리가 조금 잠잠해졌다. 해야 할 말을 먼저 적어 보니 생각보다 덜 막혔고, 창작은 고립이 아니라 정리의 시간이 필요하다는 걸 느꼈다. 돌아오는 길에는 다시 해볼 의욕이 생겼다.',
    createdAt: DateTime(2025, 3, 6, 16, 25),
    tags: <String>['창작', '집중', '회복'],
    metadata: <String, dynamic>{
      'mood': 'clearer',
      'energy': 6,
      'topic': 'creative-reset',
      'location': 'cafe',
    },
  ),
];
