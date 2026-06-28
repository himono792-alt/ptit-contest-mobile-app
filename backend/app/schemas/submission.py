"""Pydantic schemas cho submission (SV-08 nộp bài, GV-04 quản lý)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import SubmissionStatus


class SubmissionVersionCreateIn(BaseModel):
    """SV-08 POST /api/rounds/{id}/submissions/me/versions.

    SV nộp 1 version mới (text + link). Backend tự tạo submission nếu chưa.
    File đính kèm: nộp riêng qua POST /api/submissions/versions/{id}/files
    (multipart, lưu R2 hoặc BYTEA fallback).
    """

    title: str | None = Field(None, max_length=255)
    description: str | None = None
    external_link: str | None = Field(None, description="URL Drive/GitHub")
    text_answer: str | None = None
    note: str | None = None


class SubmissionFileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    submission_file_id: int
    file_name: str
    file_url: str
    mime_type: str | None = None
    file_size_bytes: int | None = None
    created_at: datetime


class SubmissionVersionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    submission_version_id: int
    submission_id: int
    version_no: int
    title: str | None = None
    description: str | None = None
    external_link: str | None = None
    text_answer: str | None = None
    checksum_value: str | None = None
    submitted_by: int | None = None
    submitted_at: datetime
    note: str | None = None
    files: list[SubmissionFileOut] = []


class SubmissionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    submission_id: int
    round_id: int
    entry_id: int
    current_version_no: int
    status: SubmissionStatus
    is_locked: bool
    submitted_at: datetime | None = None
    created_by: int | None = None
    updated_by: int | None = None
    created_at: datetime
    updated_at: datetime


class SubmissionDetail(SubmissionOut):
    versions: list[SubmissionVersionOut] = []
