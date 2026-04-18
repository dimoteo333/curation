// Mock data for Curator — Korean life records
const MEMORIES = {
  m_2023_02_14: {
    id: 'm_2023_02_14',
    source: 'diary',
    sourceLabel: '일기',
    date: '2023년 2월 14일',
    dateShort: '2023.02.14',
    timeAgo: '3년 전 2월',
    title: '요즘 너무 지친다',
    mood: '무기력',
    location: '서울 · 망원동',
    content:
      '아침에 눈을 뜨기가 힘들다. 회사에 도착해서도 멍하니 앉아 있는 시간이 길어졌다. 점심도 건너뛰었고, 퇴근하고는 아무것도 하기 싫어서 누워만 있었다. 이 상태가 2주째 이어지고 있다. 뭐가 문제인지 모르겠다. 그냥 다 귀찮다.',
    tags: ['무기력', '번아웃', '겨울'],
  },
  m_2023_03_21: {
    id: 'm_2023_03_21',
    source: 'diary',
    sourceLabel: '일기',
    date: '2023년 3월 21일',
    dateShort: '2023.03.21',
    timeAgo: '3년 전 봄',
    title: '작은 사이드 프로젝트를 시작했다',
    mood: '설렘',
    location: '서울 · 망원동',
    content:
      '주말에 오랜만에 노트북을 열고 예전에 만들고 싶었던 작은 웹사이트를 만들기 시작했다. 아무도 보지 않겠지만, 오랜만에 뭔가를 만든다는 감각이 좋았다. 저녁까지 시간 가는 줄 몰랐고, 자기 전에 오랜만에 기분이 좋았다.',
    tags: ['사이드 프로젝트', '회복', '창작'],
  },
  m_2023_04_09: {
    id: 'm_2023_04_09',
    source: 'memo',
    sourceLabel: '메모',
    date: '2023년 4월 9일',
    dateShort: '2023.04.09',
    timeAgo: '3년 전 봄',
    title: '한강 산책',
    mood: '평온',
    location: '서울 · 한강공원',
    content:
      '친구랑 오랜만에 한강 산책을 했다. 날씨가 좋았고, 별 얘기 안 해도 편했다. 걷는 것만으로도 머리가 가벼워진다는 걸 오랜만에 느꼈다. 다음 주에도 나가기로 했다.',
    tags: ['산책', '친구', '회복'],
  },
  m_2024_11_18: {
    id: 'm_2024_11_18',
    source: 'diary',
    sourceLabel: '일기',
    date: '2024년 11월 18일',
    dateShort: '2024.11.18',
    timeAgo: '1년 전 겨울',
    title: '이직 후 첫 달',
    mood: '불안',
    location: '서울 · 성수동',
    content:
      '새 회사에 온 지 한 달이 됐다. 아직 적응이 안 된다. 일은 어렵지 않은데 사람들과 거리가 느껴지고, 저녁이 되면 기운이 다 빠진다. 예전 팀이 그립기도 하다.',
    tags: ['이직', '불안', '겨울'],
  },
  m_2025_01_07: {
    id: 'm_2025_01_07',
    source: 'calendar',
    sourceLabel: '캘린더',
    date: '2025년 1월 7일',
    dateShort: '2025.01.07',
    timeAgo: '올해 초',
    title: '수영 강습 첫날',
    mood: '의욕',
    location: '마포구민체육센터',
    content:
      '화요일·목요일 저녁 7시 · 3개월 등록. 오래 미뤄온 것. 몸을 움직이는 루틴을 다시 만들어 보기로 했다.',
    tags: ['운동', '루틴', '새해'],
  },
};

const CHAT_HISTORY = [
  { q: '지난 겨울엔 뭘 하면서 기분이 풀렸지?', when: '4일 전', preview: '그때는 한강 산책과 작은 프로젝트가 도움이 됐어요.' },
  { q: '이직하고 나서 한 달 동안 어땠지?', when: '1주 전', preview: '적응에 시간이 걸렸지만, 3주차에 변화가 있었어요.' },
  { q: '책 읽기 루틴이 가장 잘 지켜진 때는?', when: '2주 전', preview: '2024년 9월, 출퇴근 지하철에서 매일 읽으셨네요.' },
];

const TODAY_SNAPSHOTS = [
  { label: '오늘의 일기', value: '아직 작성 전', hint: '저녁 9시 · 평소 시간' },
  { label: '이번 주 기록', value: '12개', hint: '지난주보다 +3' },
  { label: '연결된 소스', value: '4개', hint: '캘린더 · 일기 · 메모 · 음성' },
];

window.CURATOR_DATA = { MEMORIES, CHAT_HISTORY, TODAY_SNAPSHOTS };
