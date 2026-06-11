"""Pydantic schemas cho judging (rubric, assignment, score, result)."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


# ---------- Round Score Criteria (rubric) ----------

class CriterionCreateIn(BaseModel):
    """GV-05 POST /api/rounds/{id}/criteria — define tiêu chí chấm."""

    criterion_name: str = Field(..., min_length=2, max_length=150)
    description: str | None = None
    max_score: Decimal = Field(..., ge=0, decimal_places=2)
    weight_percent: Decimal | None = Field(None, ge=0, le=100, decimal_places=2)
    display_order: int = Field(1, ge=1)


class CriterionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    criterion_id: int
    round_id: int
    criterion_name: str
    description: str | None = None
    max_score: Decimal
    weight_percent: Decimal | None = None
    display_order: int


# ---------- Judge Assignment ----------

class JudgeAssignmentCreateIn(BaseModel):
    """GV-05 POST /api/rounds/{id}/judge-assignments — gán judge cho entry."""

    entry_id: int
    judge_id: int
    submission_id: int | None = Field(None, description="Optional, link tới submission cụ thể")
    can_view_identity: bool = Field(False, description="False = blind judging")


class JudgeAssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    assignment_id: int
    round_id: int
    entry_id: int
    submission_id: int | None = None
    judge_id: int
    assigned_by: int | None = None
    can_view_identity: bool
    assigned_at: datetime


# ---------- Score ----------

class ScoreItemIn(BaseModel):
    """1 score cho 1 criterion."""

    criterion_id: int
    score_value: Decimal = Field(..., ge=0, decimal_places=2)
    comment_text: str | None = None


class ScoreBulkIn(BaseModel):
    """GV-05 POST /api/assignments/{id}/scores — bulk submit điểm cho 1 assignment."""

    scores: list[ScoreItemIn] = Field(..., min_length=1, description="1 record per criterion")


class ScoreOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    score_id: int
    assignment_id: int
    criterion_id: int
    score_value: Decimal
    comment_text: str | None = None
    scored_at: datetime


# ---------- Round Result ----------

class RoundResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    round_result_id: int
    round_id: int
    entry_id: int
    total_score: Decimal | None = None
    average_score: Decimal | None = None
    rank_no: int | None = None
    is_passed: bool | None = None
    published_at: datetime | None = None
    created_at: datetime
