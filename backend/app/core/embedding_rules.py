from __future__ import annotations

import json
import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path


@dataclass(frozen=True)
class TopicRule:
    key: str
    aliases: tuple[str, ...]
    related: tuple[str, ...] = ()


@dataclass(frozen=True)
class SemanticCluster:
    key: str
    aliases: tuple[str, ...]
    related: tuple[str, ...] = ()


@dataclass(frozen=True)
class NormalizationRuleSet:
    lowercase: bool
    collapse_whitespace: bool
    token_pattern: str
    compact_pattern: str
    numeric_pattern: str
    min_token_length: int


@dataclass(frozen=True)
class EmbeddingRuleSet:
    normalization: NormalizationRuleSet
    topic_rules: tuple[TopicRule, ...]
    semantic_clusters: tuple[SemanticCluster, ...]
    stop_tokens: frozenset[str]


_RULES_PATH = Path(__file__).with_name("embedding_rules.json")


@lru_cache(maxsize=1)
def load_embedding_rules() -> EmbeddingRuleSet:
    payload = json.loads(_RULES_PATH.read_text(encoding="utf-8"))
    normalization = payload["normalization"]
    return EmbeddingRuleSet(
        normalization=NormalizationRuleSet(
            lowercase=bool(normalization["lowercase"]),
            collapse_whitespace=bool(normalization["collapse_whitespace"]),
            token_pattern=str(normalization["token_pattern"]),
            compact_pattern=str(normalization["compact_pattern"]),
            numeric_pattern=str(normalization["numeric_pattern"]),
            min_token_length=int(normalization["min_token_length"]),
        ),
        topic_rules=tuple(
            TopicRule(
                key=str(item["key"]),
                aliases=tuple(str(alias) for alias in item["aliases"]),
                related=tuple(str(related) for related in item.get("related", ())),
            )
            for item in payload["topic_rules"]
        ),
        semantic_clusters=tuple(
            SemanticCluster(
                key=str(item["key"]),
                aliases=tuple(str(alias) for alias in item["aliases"]),
                related=tuple(str(related) for related in item.get("related", ())),
            )
            for item in payload["semantic_clusters"]
        ),
        stop_tokens=frozenset(str(token) for token in payload["stop_tokens"]),
    )


EMBEDDING_RULES = load_embedding_rules()
TOKEN_PATTERN = re.compile(EMBEDDING_RULES.normalization.token_pattern)
TOPIC_RULES: dict[str, TopicRule] = {
    rule.key: rule for rule in EMBEDDING_RULES.topic_rules
}


def normalize_text(value: str) -> str:
    normalized = value
    if EMBEDDING_RULES.normalization.lowercase:
        normalized = normalized.lower()
    if EMBEDDING_RULES.normalization.collapse_whitespace:
        normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized


def tokenize(value: str) -> set[str]:
    return {
        token
        for token in TOKEN_PATTERN.findall(normalize_text(value))
        if len(token) >= EMBEDDING_RULES.normalization.min_token_length
    }


def detect_topics(text: str) -> set[str]:
    normalized = normalize_text(text)
    return {
        topic
        for topic, rule in TOPIC_RULES.items()
        if any(alias in normalized for alias in rule.aliases)
    }
