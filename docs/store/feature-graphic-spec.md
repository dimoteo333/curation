# Play Store Feature Graphic Spec

기준 문서:

- Google Play preview asset spec: <https://support.google.com/googleplay/android-developer/answer/1078870>
- product message source: `docs/store/play-store-listing.md`
- visual/source copy reference: `website/landing-page.md`

참고:

- 요청에는 `docs/store/landing-page.md`가 언급되어 있지만 현재 저장소에는 없다.
- 현재 feature graphic content guide는 `website/landing-page.md`를 기준으로 잡는다.

## Hard Spec

- Size: `1024 x 500`
- Format: `PNG` or `JPG`
- Color mode: `24-bit`
- Alpha: `없음`
- Text: 최소화
- 실제 업로드 권장 파일명:
  - `captures/store/play-store/ko-KR/feature-graphic/feature-graphic-1024x500.png`

## Core Message

주요 문구:

- `내 기록에서 찾는 오늘의 통찰`

보조 문구 후보:

- `온디바이스 우선`
- `기록 기반`
- `파일 · 캘린더 지원`

메시지 기준:

- `website/landing-page.md`의 hero와 proof point를 그대로 압축한다.
- 첫 1초 안에 `개인 기록`, `온디바이스`, `질문에 답하는 앱`이 읽혀야 한다.

## Recommended Layout

Canvas guide:

- 좌측 45%: headline + short proof points
- 우측 55%: 앱 화면 조각 또는 카드형 UI motif
- Safe margin:
  - 좌우 `48 px`
  - 상하 `40 px`

권장 구성:

1. 배경:
   - warm cream gradient
   - 옅은 paper grain
   - 앱의 종이 질감 카드 느낌 유지
2. 좌측 headline block:
   - 1줄 또는 2줄 headline
   - 작은 보조 tag 2~3개
3. 우측 visual block:
   - 홈 카드 + 답변 카드가 반쯤 겹친 stacked composition
   - 일정 badge, 기록 highlight, 검색 underline 같은 작은 motif
4. 하단:
   - 추가 CTA 문구는 생략하거나 매우 짧게 유지

## Content Direction

반드시 살아 있어야 하는 요소:

- 온디바이스 우선
- 내 기록 기반
- 답변 + 근거 기록
- 파일 / 캘린더 입력

넣지 말아야 하는 요소:

- App icon을 크게 반복 배치한 branding duplication
- 너무 긴 설명 문장
- 과한 device frame
- 작은 body text 여러 줄
- 투명 배경

## Visual Reference From Landing Page Brief

`website/landing-page.md`를 기준으로 다음을 반영한다.

- headline tone: `당신의 기록만으로, 오늘의 답을 찾습니다`
- trust badges:
  - `온디바이스 우선`
  - `개인 기록 기반`
  - `파일/캘린더 지원`
- art direction:
  - warm paper tone
  - gold-cream family
  - slightly stacked product screens

## App Theme Colors

기본 light theme는 `CuratorMood.cream`이다.
출처: `mobile/lib/src/theme/curator_theme.dart`

Primary palette:

- Background top: `#F5EDE0`
- Background bottom: `#E9DDCE`
- Background accent: `#F1E6D8`
- Primary accent: `#C87456`
- Primary accent deep: `#A35A3F`
- Primary accent soft: `#E8B8A4`
- Highlight ochre: `#B89368`
- Support sage: `#96A78A`
- Main text: `#3A332E`
- Secondary text: `#6B625A`
- Muted text: `#9A8F86`
- Divider: `#E8DDD0`
- Divider strong: `#D4C5B5`

추천 사용:

- 배경 gradient: `#F5EDE0 -> #E9DDCE`
- headline text: `#3A332E`
- accent chip / underline: `#C87456`
- secondary badge: `#B89368` 또는 `#96A78A`

## Suggested Composition

가장 안전한 1안:

- 좌측:
  - headline `내 기록에서 찾는 오늘의 통찰`
  - 작은 badge 3개
- 우측:
  - 홈 화면 카드 1장
  - 답변 카드 1장
  - 일정 badge 1개

조금 더 제품 중심인 2안:

- 좌측:
  - 짧은 headline
  - `온디바이스 우선` single badge
- 우측:
  - 홈 화면 일부
  - supporting record 카드
  - 검색 highlight effect

## Export Checklist

- `1024 x 500` 정확히 맞춤
- alpha 없음
- 지나치게 작은 글자 없음
- 앱 아이콘 중복 없음
- 밝은 크림 배경에서 텍스트 대비 확보
- Play Store thumbnail 크기에서도 headline이 읽힘
