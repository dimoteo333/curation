from __future__ import annotations

import re
from collections import Counter
from typing import TypedDict

from backend.app.db.models import StoredRecord
from backend.app.repositories.record_repository import RecordRepository
from backend.app.schemas.curation import CurationQueryResponse, SupportingRecordResponse

TOKEN_PATTERN = re.compile(r"[0-9A-Za-z가-힣]+")

SYNONYM_GROUPS: dict[str, tuple[str, ...]] = {
    "무기력": ("무기력", "지침", "번아웃", "의욕", "피곤"),
    "지침": ("지침", "피곤", "무기력"),
    "번아웃": ("번아웃", "마감", "무기력"),
    "의욕": ("의욕", "무기력", "회복"),
    "회복": ("회복", "산책", "수면", "휴식"),
    "지치": ("지치", "지침", "무기력", "피곤"),
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
        ranked_records = self._rank_records(records, expanded_terms)
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
        theme_text = ", ".join(top_themes[:2]) if top_themes else "최근 피로 흐름"
        primary_signal = self._primary_signal(expanded_terms, top_themes)
        top_record = supporting_records[0][1]
        second_record = supporting_records[1][1] if len(supporting_records) > 1 else None
        action_hint = self._suggest_action(top_themes)
        evidence_quote = self._build_excerpt(top_record)
        comparison_text = (
            f' 또한 {second_record.created_at.strftime("%Y-%m-%d")} "{second_record.title}"에서도'
            f" 비슷한 결이 이어집니다."
            if second_record is not None
            else ""
        )

        return CurationQueryResponse(
            insight_title=self._insight_title(top_themes, primary_signal),
            summary=(
                f'가장 가까운 기록은 {top_record.created_at.strftime("%Y-%m-%d")} "{top_record.title}"이며, '
                f"질문과 맞닿는 핵심 흐름은 {theme_text} 쪽에 가깝습니다."
                f"{comparison_text}"
            ),
            answer=(
                f'이번 질문은 단순한 하루 컨디션보다 최근 기록에서 반복된 "{primary_signal}" 흐름과 더 가깝습니다. '
                f'"{top_record.title}"에는 "{evidence_quote}"처럼 현재 상태를 설명해 주는 장면이 직접 남아 있습니다.'
                f"{comparison_text} 기록을 함께 보면 {action_hint} 쪽이 회복 단서로 반복됩니다."
            ),
            supporting_records=[
                SupportingRecordResponse(
                    id=record.id,
                    source=record.source,
                    title=record.title,
                    created_at=record.created_at,
                    excerpt=self._build_excerpt(record),
                    relevance_reason=self._relevance_reason(record, expanded_terms),
                )
                for _, record in supporting_records
            ],
            suggested_follow_up="상위 기록 두세 개를 다시 열어 보고, 지금과 가장 비슷한 날을 골라 보시겠어요?",
        )

    def _rank_records(
        self, records: list[StoredRecord], expanded_terms: set[str]
    ) -> list[tuple[int, StoredRecord]]:
        ranked: list[tuple[int, StoredRecord]] = []
        for record in records:
            title_terms = self._tokenize(record.title)
            content_terms = self._tokenize(record.content)
            tag_terms = {tag.lower() for tag in record.tags}
            haystack_terms = title_terms | content_terms | tag_terms
            overlap = expanded_terms & haystack_terms
            if not overlap:
                continue

            score = len(overlap) * 4
            score += len(expanded_terms & tag_terms) * 4
            score += len(expanded_terms & title_terms) * 3
            score += self._phrase_match_bonus(record, expanded_terms)
            if record.source in {"diary", "일기"}:
                score += 2
            score += self._recency_bonus(record)
            ranked.append((score, record))

        return sorted(ranked, key=lambda item: (item[0], item[1].created_at), reverse=True)

    def _collect_themes(self, ranked_records: list[tuple[int, StoredRecord]]) -> list[str]:
        tag_counter: Counter[str] = Counter()
        for _, record in ranked_records:
            tag_counter.update(record.tags)
        return [tag for tag, _ in tag_counter.most_common(3)]

    def _suggest_action(self, themes: list[str]) -> str:
        for theme in themes:
            if theme in {"산책", "휴식"}:
                return "짧은 산책이나 의도적인 휴식"
            if theme == "수면":
                return "수면 리듬 정리"
            if theme == "사이드프로젝트":
                return "부담이 적은 작은 프로젝트"
        return "우선순위를 줄이는 정리"

    def _insight_title(self, themes: list[str], primary_signal: str) -> str:
        for theme in themes:
            if theme in THEME_INSIGHT_TITLES:
                return THEME_INSIGHT_TITLES[theme]
        if primary_signal in THEME_INSIGHT_TITLES:
            return THEME_INSIGHT_TITLES[primary_signal]
        return "최근 기록에서 반복된 흐름"

    def _primary_signal(self, expanded_terms: set[str], themes: list[str]) -> str:
        for signal in ("무기력", "지침", "번아웃", "의욕", "회복"):
            if signal in expanded_terms:
                return signal
        if themes:
            return themes[0]
        return "피로"

    def _expand_terms(self, question: str) -> set[str]:
        tokens = self._tokenize(question)
        expanded = set(tokens)
        for token in list(tokens):
            for root_term, synonyms in SYNONYM_GROUPS.items():
                if token == root_term or token.startswith(root_term) or root_term in token:
                    expanded.add(root_term)
                    expanded.update(synonyms)
        return expanded

    def _relevance_reason(self, record: StoredRecord, expanded_terms: set[str]) -> str:
        tag_match = next((tag for tag in record.tags if tag in expanded_terms), None)
        if tag_match:
            return f"질문과 직접 맞닿는 '{tag_match}' 흐름이 포함된 기록입니다."
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
        return min(bonus, 4)

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
