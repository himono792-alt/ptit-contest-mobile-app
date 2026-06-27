"""Pydantic schemas cho Phúc khảo kết quả (Result Appeal) — 2026-06-27."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import AppealStatus


class AppealCreateIn(BaseModel):
    """SV gửi phúc khảo cho 1 entry của mình."""

    entry_id: int
    round_id: int | None = None
    title: str = Field(..., min_length=3, max_length=255)
    content_text: str = Field(..., min_length=5)


class AppealResolveIn(BaseModel):
    """GV/BTC kết luận phúc khảo.

    decision=ACCEPTED  → chấp nhận, kết quả sẽ được chấm lại + duyệt lại + publish lại.
    decision=REJECTED  → giữ nguyên kết quả (kể cả khi đã xem lại thấy điểm đúng).
    response_text bắt buộc để SV biết lý do.
    """

    decision: Literal["ACCEPTED", "REJECTED"]
    response_text: str = Field(..., min_length=5)


class AppealWindowIn(BaseModel):
    """BTC đặt/đổi hạn nhận phúc khảo cho contest. None = đóng kênh phúc khảo."""

    appeal_deadline: datetime | None = None


class AppealOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    appeal_id: int
    contest_id: int
    round_id: int | None = None
    entry_id: int
    submitted_by_student_id: int
    title: str
    content_text: str
    status: AppealStatus
    response_text: str | None = None
    handled_by: int | None = None
    handled_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
