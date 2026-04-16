from __future__ import annotations

from datetime import datetime

from backend.app.db.models import StoredRecord


SEEDED_RECORDS: tuple[StoredRecord, ...] = (
    StoredRecord(
        id="diary-burnout-feb-2024",
        source="diary",
        title="야근이 길어지던 주간 회고",
        content=(
            "이번 주는 계속 야근이 이어져서 무기력했다. 퇴근 후에는 말할 힘도 없었다. "
            "토요일 아침에 한강을 천천히 걷고 낮잠을 잤더니 조금 회복되는 느낌이 있었다."
        ),
        created_at=datetime.fromisoformat("2024-02-18T21:00:00"),
        tags=("무기력", "야근", "산책", "회복"),
    ),
    StoredRecord(
        id="calendar-restorative-sat-2024",
        source="calendar",
        title="토요일 오전 산책",
        content=(
            "한강 산책 50분. 지난주 내내 지쳤던 상태에서 일부러 바깥 공기를 쐬기로 했다. "
            "산책 뒤에는 머리가 조금 맑아졌다."
        ),
        created_at=datetime.fromisoformat("2024-02-17T09:30:00"),
        tags=("산책", "휴식", "지침"),
    ),
    StoredRecord(
        id="memo-side-project-spring-2023",
        source="memo",
        title="작은 사이드 프로젝트 아이디어",
        content=(
            "의욕이 떨어질 때는 새로운 아이디어를 짧게라도 구현해보면 회복이 빨랐다. "
            "부담이 적은 주말 프로젝트가 생각보다 큰 전환점이 됐다."
        ),
        created_at=datetime.fromisoformat("2023-03-09T20:15:00"),
        tags=("의욕", "사이드프로젝트", "회복"),
    ),
    StoredRecord(
        id="diary-routine-reset-2023",
        source="diary",
        title="생활 리듬을 되돌린 날",
        content=(
            "이틀 연속 늦게 자고 나니 하루 종일 멍했다. 그날은 운동 대신 일찍 자고 "
            "아침에 가볍게 스트레칭했더니 집중력이 돌아왔다."
        ),
        created_at=datetime.fromisoformat("2023-11-02T22:10:00"),
        tags=("수면", "집중", "회복"),
    ),
    StoredRecord(
        id="diary-project-pressure-2022",
        source="diary",
        title="프로젝트 마감 직전의 기록",
        content=(
            "마감이 가까워지자 번아웃 비슷한 감각이 왔다. 해야 할 일은 많았지만 마음이 따라오지 않았다. "
            "우선순위를 줄이고 회의 두 개를 미루자 조금 숨통이 트였다."
        ),
        created_at=datetime.fromisoformat("2022-10-14T18:40:00"),
        tags=("번아웃", "마감", "우선순위", "회복"),
    ),
)
