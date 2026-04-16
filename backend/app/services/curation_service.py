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
        record_labels = ", ".join(
            f"{record.created_at.strftime('%Y-%m-%d')} {record.title}" for _, record in supporting_records[:2]
        )
        action_hint = self._suggest_action(top_themes)

        return CurationQueryResponse(
            insight_title="최근 기록에서 반복된 흐름",
            summary=(
                f"관련 기록 {len(supporting_records)}건에서 {theme_text} 흐름이 함께 보입니다. "
                f"특히 {record_labels} 기록이 현재 질문과 가깝습니다."
            ),
            answer=(
                f"지금의 상태는 단순한 하루 기분이라기보다 최근 기록에서 반복된 {primary_signal} 흐름과 "
                f"{theme_text} 패턴이 함께 보이는 상태에 가깝습니다. 기록을 보면 피로가 높아질 때 일정 압박이 겹치고, "
                f"그 뒤에 {action_hint} 같은 회복 행동이 도움이 되는 흐름이 있었습니다."
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
            haystack_terms = self._tokenize(" ".join((record.title, record.content, " ".join(record.tags))))
            overlap = expanded_terms & haystack_terms
            if not overlap:
                continue

            score = len(overlap) * 3
            score += len(expanded_terms & set(record.tags)) * 2
            if record.source == "diary":
                score += 1
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
