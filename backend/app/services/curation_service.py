from __future__ import annotations

import re
from collections import Counter
from dataclasses import dataclass
from typing import TypedDict

from backend.app.db.models import StoredRecord
from backend.app.repositories.record_repository import RecordRepository
from backend.app.schemas.curation import CurationQueryResponse, SupportingRecordResponse

TOKEN_PATTERN = re.compile(r"[0-9A-Za-z가-힣]+")


@dataclass(frozen=True)
class _TopicRule:
    key: str
    aliases: tuple[str, ...]
    related: tuple[str, ...] = ()


@dataclass(frozen=True)
class _RankedRecord:
    score: int
    record: StoredRecord
    matched_terms: tuple[str, ...]
    matched_topics: tuple[str, ...]
    recovery_signals: tuple[str, ...]


TOPIC_PRIORITY: tuple[str, ...] = (
    "수면",
    "번아웃",
    "무기력",
    "지침",
    "회복",
    "관계",
    "운동",
    "창작",
    "성장",
    "의욕",
    "집중",
)

TOPIC_RULES: dict[str, _TopicRule] = {
    "무기력": _TopicRule(
        key="무기력",
        aliases=("무기력", "기운없", "기력없", "의욕저하"),
        related=("지침", "번아웃", "회복"),
    ),
    "지침": _TopicRule(
        key="지침",
        aliases=("지침", "지치", "피곤", "피로", "멍했", "멍해"),
        related=("무기력", "수면", "회복"),
    ),
    "번아웃": _TopicRule(
        key="번아웃",
        aliases=("번아웃", "소진", "탈진", "과로"),
        related=("마감", "무기력", "회복"),
    ),
    "마감": _TopicRule(
        key="마감",
        aliases=("마감", "업무", "프로젝트", "회의", "압박", "우선순위"),
        related=("번아웃", "지침"),
    ),
    "수면": _TopicRule(
        key="수면",
        aliases=("수면", "잠", "불면", "뒤척", "새벽", "일찍 자", "늦게 자"),
        related=("집중", "회복", "지침"),
    ),
    "회복": _TopicRule(
        key="회복",
        aliases=("회복", "숨통", "맑아졌", "나아졌", "진정"),
        related=("산책", "휴식", "수면", "운동", "대화"),
    ),
    "휴식": _TopicRule(
        key="휴식",
        aliases=("휴식", "쉬", "쉼", "재충전"),
        related=("회복", "수면"),
    ),
    "산책": _TopicRule(
        key="산책",
        aliases=("산책", "한강", "걷", "걸었", "바깥 공기"),
        related=("회복", "휴식"),
    ),
    "운동": _TopicRule(
        key="운동",
        aliases=("운동", "러닝", "달리기", "헬스", "근력", "스트레칭"),
        related=("건강", "회복", "집중"),
    ),
    "집중": _TopicRule(
        key="집중",
        aliases=("집중", "집중력", "리듬", "루틴"),
        related=("수면", "회복", "성장"),
    ),
    "관계": _TopicRule(
        key="관계",
        aliases=("관계", "친구", "가족", "엄마", "동료", "서운"),
        related=("대화", "회복"),
    ),
    "대화": _TopicRule(
        key="대화",
        aliases=("대화", "이야기", "말했", "통화", "화해"),
        related=("관계", "회복"),
    ),
    "의욕": _TopicRule(
        key="의욕",
        aliases=("의욕", "아이디어", "다시 해볼"),
        related=("회복", "창작", "성장"),
    ),
    "창작": _TopicRule(
        key="창작",
        aliases=("창작", "글쓰기", "초안", "작업", "에세이"),
        related=("의욕", "집중"),
    ),
    "성장": _TopicRule(
        key="성장",
        aliases=("성장", "배움", "습관", "강의"),
        related=("집중", "의욕"),
    ),
}

RECOVERY_SIGNAL_LABELS: tuple[str, ...] = (
    "산책",
    "휴식",
    "수면",
    "운동",
    "대화",
    "우선순위",
    "집중",
    "회복",
)

ACTION_HINTS: dict[str, str] = {
    "산책": "짧은 산책으로 몸의 속도를 먼저 바꾸기",
    "휴식": "일정을 줄이고 의도적으로 쉬는 시간 확보하기",
    "수면": "잠드는 시간과 카페인 리듬을 다시 정리하기",
    "운동": "무리가 없는 짧은 움직임으로 몸을 먼저 깨우기",
    "대화": "혼자 버티지 말고 한 번은 말로 꺼내 보기",
    "우선순위": "해야 할 일의 수를 줄여 숨통을 만들기",
    "집중": "루틴을 작게 다시 세워 흐트러진 리듬을 복구하기",
    "회복": "회복 단서가 있었던 행동을 하루에 하나만 다시 붙이기",
    "사이드프로젝트": "부담이 적은 작은 프로젝트로 감각을 깨우기",
}

THEME_INSIGHT_TITLES: dict[str, str] = {
    "수면": "수면 리듬이 흔들릴 때 반복된 흐름",
    "번아웃": "압박이 높아질 때 먼저 흐트러지는 리듬",
    "회복": "회복 단서가 함께 남아 있는 기록",
    "관계": "관계 속에서 마음의 무게가 달라진 순간",
    "운동": "몸의 리듬이 집중을 회복시킨 장면",
    "창작": "작은 실행이 다시 움직이게 한 흐름",
    "성장": "작은 루틴이 버팀목이 된 기록",
}


class CurationService:
    def __init__(self, repository: RecordRepository) -> None:
        self._repository = repository

    def curate(self, question: str, top_k: int = 3) -> CurationQueryResponse:
        records = self._repository.list_records()
        expanded_terms = self._expand_terms(question)
        question_topics = self._detect_topics(question)
        ranked_records = self._rank_records(records, expanded_terms, question_topics)
        supporting_records = ranked_records[:top_k]

        if not supporting_records:
            return CurationQueryResponse(
                insight_title="연결할 기록이 부족합니다",
                summary="현재 질문과 직접 연결되는 개인 기록을 아직 충분히 찾지 못했습니다.",
                answer=(
                    "지금 질문과 직접 맞닿는 기록을 찾지 못했습니다. 최근 감정이나 일정, 몸 상태를 "
                    "조금 더 구체적으로 적어 주시면 다음 탐색에서 더 정확히 연결해 볼 수 있습니다."
                ),
                supporting_records=[],
                suggested_follow_up="최근 일주일의 감정 변화나 피로 원인을 한 문장씩 적어 보시겠어요?",
            )

        top_themes = self._collect_themes(supporting_records)
        primary_signal = self._primary_signal(question_topics, top_themes)
        top_record = supporting_records[0]
        second_record = supporting_records[1] if len(supporting_records) > 1 else None
        matched_signal_text = self._matched_signal_text(top_record)
        action_hint = self._suggest_action(top_themes, top_record.recovery_signals)
        evidence_quote = self._build_excerpt(top_record.record)
        comparison_text = (
            f' 또한 {second_record.record.created_at.strftime("%Y-%m-%d")} '
            f'"{second_record.record.title}"에서도 비슷한 결이 이어집니다.'
            if second_record is not None
            else ""
        )

        return CurationQueryResponse(
            insight_title=self._insight_title(top_themes, primary_signal),
            summary=(
                f'가장 가까운 기록은 {top_record.record.created_at.strftime("%Y-%m-%d")} '
                f'"{top_record.record.title}"이며, 질문과 직접 맞닿는 단서는 {matched_signal_text}입니다.'
                f"{comparison_text}"
            ),
            answer=(
                f'이번 질문은 단발성 컨디션보다 최근 기록에 반복된 "{primary_signal}" 흐름과 더 가깝습니다. '
                f'"{top_record.record.title}"에는 "{evidence_quote}"처럼 현재 상태를 설명해 주는 장면이 남아 있습니다.'
                f"{comparison_text} 함께 보면 {action_hint} 같은 회복 단서가 반복됩니다."
            ),
            supporting_records=[
                SupportingRecordResponse(
                    id=item.record.id,
                    source=item.record.source,
                    title=item.record.title,
                    created_at=item.record.created_at,
                    excerpt=self._build_excerpt(item.record),
                    relevance_reason=self._relevance_reason(item),
                )
                for item in supporting_records
            ],
            suggested_follow_up="상위 기록 두세 개를 다시 열어 보고, 지금과 가장 비슷한 날을 골라 보시겠어요?",
        )

    def _rank_records(
        self,
        records: list[StoredRecord],
        expanded_terms: set[str],
        question_topics: set[str],
    ) -> list[_RankedRecord]:
        ranked: list[_RankedRecord] = []
        for record in records:
            title_terms = self._tokenize(record.title)
            content_terms = self._tokenize(record.content)
            tag_terms = {tag.lower() for tag in record.tags}
            haystack_terms = title_terms | content_terms | tag_terms
            overlap = expanded_terms & haystack_terms
            record_topics = self._detect_topics(
                " ".join((record.title, record.content, " ".join(record.tags)))
            )
            direct_topic_hits = question_topics & record_topics
            related_topic_hits = self._related_topic_hits(question_topics, record_topics)
            if not overlap and not direct_topic_hits and not related_topic_hits:
                continue

            score = 0
            score += len(expanded_terms & title_terms) * 6
            score += len(expanded_terms & tag_terms) * 5
            score += len(expanded_terms & content_terms) * 3
            score += len(direct_topic_hits) * 9
            score += len(related_topic_hits) * 4
            score += self._phrase_match_bonus(record, expanded_terms)
            score += self._context_alignment_bonus(question_topics, record_topics, record)
            if record.source in {"diary", "일기"}:
                score += 1
            score += self._recency_bonus(record)

            matched_topics = tuple(
                self._sorted_labels(direct_topic_hits | related_topic_hits)
            )
            recovery_signals = tuple(
                self._sorted_labels(self._extract_recovery_signals(record_topics, record.tags))
            )
            ranked.append(
                _RankedRecord(
                    score=score,
                    record=record,
                    matched_terms=tuple(sorted(overlap)),
                    matched_topics=matched_topics,
                    recovery_signals=recovery_signals,
                )
            )

        return sorted(
            ranked,
            key=lambda item: (item.score, item.record.created_at),
            reverse=True,
        )

    def _collect_themes(self, ranked_records: list[_RankedRecord]) -> list[str]:
        counter: Counter[str] = Counter()
        for index, item in enumerate(ranked_records[:3]):
            weight = 4 - index
            counter.update({topic: weight for topic in item.matched_topics})
            counter.update({tag: 1 for tag in item.record.tags if tag in THEME_INSIGHT_TITLES})
        return [topic for topic, _ in counter.most_common(3)]

    def _suggest_action(self, themes: list[str], recovery_signals: tuple[str, ...]) -> str:
        for signal in (*recovery_signals, *themes):
            if signal in ACTION_HINTS:
                return ACTION_HINTS[signal]
        return "우선순위를 줄이고 리듬을 다시 세우기"

    def _insight_title(self, themes: list[str], primary_signal: str) -> str:
        for theme in themes:
            if theme in THEME_INSIGHT_TITLES:
                return THEME_INSIGHT_TITLES[theme]
        if primary_signal in THEME_INSIGHT_TITLES:
            return THEME_INSIGHT_TITLES[primary_signal]
        return "최근 기록에서 반복된 흐름"

    def _primary_signal(self, question_topics: set[str], themes: list[str]) -> str:
        for signal in TOPIC_PRIORITY:
            if signal in question_topics:
                return signal
        if themes:
            return themes[0]
        return "피로"

    def _expand_terms(self, question: str) -> set[str]:
        tokens = self._tokenize(question)
        expanded = set(tokens)
        normalized = question.lower()
        for topic, rule in TOPIC_RULES.items():
            if any(alias in normalized for alias in rule.aliases):
                expanded.add(topic)
                expanded.update(rule.aliases)
                expanded.update(rule.related)
        return expanded

    def _relevance_reason(self, ranked_record: _RankedRecord) -> str:
        topic_label = ", ".join(ranked_record.matched_topics[:2])
        recovery_label = ", ".join(ranked_record.recovery_signals[:2])
        if topic_label and recovery_label:
            return f"질문과 맞닿는 {topic_label} 흐름과 {recovery_label} 단서가 함께 남아 있는 기록입니다."
        if topic_label:
            return f"질문과 직접 겹치는 {topic_label} 흐름이 확인되는 기록입니다."
        if ranked_record.matched_terms:
            return f"질문과 가까운 표현({', '.join(ranked_record.matched_terms[:2])})이 포함된 기록입니다."
        return "현재 질문과 유사한 정서 또는 상황 맥락이 담긴 기록입니다."

    def _build_excerpt(self, record: StoredRecord) -> str:
        excerpt = record.content.strip()
        if len(excerpt) <= 88:
            return excerpt
        return f"{excerpt[:85].rstrip()}..."

    def _phrase_match_bonus(self, record: StoredRecord, expanded_terms: set[str]) -> int:
        normalized_haystack = " ".join((record.title, record.content, " ".join(record.tags))).lower()
        bonus = 0
        for term in expanded_terms:
            if len(term) < 2:
                continue
            if term in normalized_haystack:
                bonus += 1
        return min(bonus, 6)

    def _context_alignment_bonus(
        self,
        question_topics: set[str],
        record_topics: set[str],
        record: StoredRecord,
    ) -> int:
        bonus = 0
        if {"무기력", "지침", "번아웃"} & question_topics:
            if "회복" in record_topics:
                bonus += 3
            if {"산책", "휴식", "운동", "우선순위"} & set(record.tags):
                bonus += 2
        if "수면" in question_topics and "수면" in record_topics:
            bonus += 4
        if "수면" in question_topics and "집중" in record_topics:
            bonus += 2
        if {"관계", "대화"} & question_topics and {"관계", "대화"} & record_topics:
            bonus += 3
        if {"창작", "의욕"} & question_topics and {"창작", "의욕"} & record_topics:
            bonus += 3
        return bonus

    def _recency_bonus(self, record: StoredRecord) -> int:
        if record.created_at.year >= 2025:
            return 3
        if record.created_at.year >= 2024:
            return 2
        if record.created_at.year >= 2023:
            return 1
        return 0

    def _tokenize(self, value: str) -> set[str]:
        return {token.lower() for token in TOKEN_PATTERN.findall(value)}

    def _detect_topics(self, text: str) -> set[str]:
        normalized = text.lower()
        matched = {
            topic
            for topic, rule in TOPIC_RULES.items()
            if any(alias in normalized for alias in rule.aliases)
        }
        return matched

    def _related_topic_hits(
        self,
        question_topics: set[str],
        record_topics: set[str],
    ) -> set[str]:
        related_hits: set[str] = set()
        for topic in question_topics:
            rule = TOPIC_RULES.get(topic)
            if rule is None:
                continue
            related_hits.update(set(rule.related) & record_topics)
        return related_hits - question_topics

    def _extract_recovery_signals(
        self,
        record_topics: set[str],
        record_tags: tuple[str, ...],
    ) -> set[str]:
        normalized_tags = {tag.lower() for tag in record_tags}
        signals = {signal for signal in RECOVERY_SIGNAL_LABELS if signal in record_topics}
        for signal in RECOVERY_SIGNAL_LABELS:
            if signal.lower() in normalized_tags:
                signals.add(signal)
        return signals

    def _matched_signal_text(self, ranked_record: _RankedRecord) -> str:
        labels = list(ranked_record.matched_topics[:2] or ranked_record.matched_terms[:2])
        if not labels:
            return "최근 피로 흐름"
        if len(labels) == 1:
            return labels[0]
        return f"{labels[0]}, {labels[1]}"

    def _sorted_labels(self, labels: set[str]) -> list[str]:
        priority = {label: index for index, label in enumerate(TOPIC_PRIORITY)}
        return sorted(labels, key=lambda label: (priority.get(label, 999), label))


class HealthStatus(TypedDict):
    status: str
    record_count: int


class HealthService:
    def __init__(self, repository: RecordRepository) -> None:
        self._repository = repository

    def check(self) -> HealthStatus:
        return {
            "status": "ok",
            "record_count": len(self._repository.list_records()),
        }
