"""주간 감정 리포트 조회용 저장소 계층."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Iterable, List

from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.db.models import Conversation, EmotionAnalysis, EmotionLog


@dataclass
class EmotionRecord:
    label: str
    score: float


class EmotionWeeklyRepository:
    """주간 감정 리포트 생성을 위한 DB 조회 레이어."""

    def __init__(self, db: Session):
        self._db = db

    def fetch_emotion_records(
        self, user_id: int, start: datetime, end: datetime
    ) -> List[EmotionRecord]:
        """감정 분석/로그 테이블에서 감정 레코드를 가져온다."""

        records: List[EmotionRecord] = []
        analysis_items = (
            self._db.query(EmotionAnalysis)
            .filter(EmotionAnalysis.USER_ID == user_id)
            .filter(EmotionAnalysis.CREATED_AT >= start)
            .filter(EmotionAnalysis.CREATED_AT <= end)
            .all()
        )
        for item in analysis_items:
            records.extend(self._to_records_from_analysis(item))

        log_items = (
            self._db.query(EmotionLog)
            .filter(EmotionLog.USER_ID == user_id)
            .filter(EmotionLog.CREATED_AT >= start)
            .filter(EmotionLog.CREATED_AT <= end)
            .all()
        )
        for item in log_items:
            if item.EMOTION_CODE:
                records.append(
                    EmotionRecord(label=item.EMOTION_CODE, score=item.SCORE or 1.0)
                )
        return records

    def fetch_conversations(
        self, user_id: int, start: datetime, end: datetime, limit: int = 50
    ) -> List[Conversation]:
        """주어진 기간의 대화 로그를 최신순으로 조회한다."""

        return (
            self._db.query(Conversation)
            .filter(
                and_(
                    Conversation.USER_ID == user_id,
                    Conversation.CREATED_AT >= start,
                    Conversation.CREATED_AT <= end,
                    Conversation.IS_DELETED == "N",
                )
            )
            .order_by(Conversation.CREATED_AT.desc())
            .limit(limit)
            .all()
        )

    @staticmethod
    def _to_records_from_analysis(item: EmotionAnalysis) -> Iterable[EmotionRecord]:
        records: list[EmotionRecord] = []

        if item.RAW_DISTRIBUTION:
            for entry in item.RAW_DISTRIBUTION:
                label = entry.get("name_ko") or entry.get("code")
                score = float(entry.get("score", 0.0))
                if label and score:
                    records.append(EmotionRecord(label=label, score=score))
            if records:
                return records

        if item.PRIMARY_EMOTION:
            label = item.PRIMARY_EMOTION.get("name_ko") or item.PRIMARY_EMOTION.get("code")
            score = float(item.PRIMARY_EMOTION.get("score") or item.PRIMARY_EMOTION.get("probability") or 0.0)
            if label and score:
                records.append(EmotionRecord(label=label, score=score))

        return records
