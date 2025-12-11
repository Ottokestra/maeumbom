from __future__ import annotations
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class WeeklyEmotionDialogSnippetBase(BaseModel):
    role: str
    content: str
    emotion: Optional[str] = None
    created_at: Optional[datetime] = Field(None, alias="createdAt")


class WeeklyEmotionDialogSnippet(WeeklyEmotionDialogSnippetBase):
    id: int

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class WeeklyEmotionReportBase(BaseModel):
    user_id: int = Field(..., alias="userId")
    week_start: datetime = Field(..., alias="weekStart")
    week_end: datetime = Field(..., alias="weekEnd")

    emotion_temperature: float = Field(..., alias="emotionTemperature")
    positive_score: float = Field(0.0, alias="positiveScore")
    negative_score: float = Field(0.0, alias="negativeScore")
    neutral_score: float = Field(0.0, alias="neutralScore")

    main_emotion: Optional[str] = Field(None, alias="mainEmotion")
    main_emotion_confidence: float = Field(0.0, alias="mainEmotionConfidence")
    main_emotion_character_code: Optional[str] = Field(
        None, alias="mainEmotionCharacterCode"
    )

    badges: List[str] = Field(default_factory=list)
    summary_text: Optional[str] = Field(None, alias="summaryText")


class WeeklyEmotionReport(WeeklyEmotionReportBase):
    report_id: int = Field(..., alias="reportId")  # Maps to ID in DB
    created_at: datetime = Field(..., alias="createdAt")

    # Snippets usually fetched separately or included?
    # PDF spec: "GET .../{reportId} to retrieve a specific weekly report and its dialog snippets."
    # So we might need a Detail schema including snippets.

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class WeeklyEmotionReportDetail(WeeklyEmotionReport):
    dialog_snippets: List[WeeklyEmotionDialogSnippet] = Field(
        default_factory=list, alias="dialogSnippets"
    )


class WeeklyReportGenerateRequest(BaseModel):
    user_id: int = Field(..., alias="userId")
    week_start: datetime = Field(..., alias="weekStart")
    week_end: Optional[datetime] = Field(None, alias="weekEnd")
    regenerate: bool = False


class WeeklyReportListResponse(BaseModel):
    items: List[WeeklyEmotionReport]
