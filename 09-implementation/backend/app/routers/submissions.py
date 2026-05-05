"""Submission router (SV-08 nộp bài, GV-04 quản lý).

Endpoints:
  POST /api/rounds/{round_id}/submissions/me/versions  — SV nộp version mới
  GET  /api/rounds/{round_id}/submissions/me           — SV xem submission của mình
  GET  /api/rounds/{round_id}/submissions              — GV list (BTC contest only)
  GET  /api/submissions/{id}                           — Detail (perm check)
  POST /api/submissions/{id}/lock                      — GV lock
"""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.submission import (
    SubmissionDetail,
    SubmissionOut,
    SubmissionVersionCreateIn,
    SubmissionVersionOut,
)
from app.services import submission_service

rounds_router = APIRouter(prefix="/rounds", tags=["submissions"])
submissions_router = APIRouter(prefix="/submissions", tags=["submissions"])


# ---------- SV ----------

@rounds_router.post(
    "/{round_id}/submissions/me/versions",
    response_model=SubmissionVersionOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_my_version(
    round_id: int,
    data: SubmissionVersionCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionVersionOut:
    """SV-08 — Nộp version mới cho submission. Tự tạo submission nếu chưa."""
    _, version = await submission_service.add_my_version(db, user, round_id, data)
    return SubmissionVersionOut.model_validate(version)


@rounds_router.get(
    "/{round_id}/submissions/me",
    response_model=SubmissionDetail | None,
)
async def get_my_submission(
    round_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionDetail | None:
    """SV-08 — Xem submission của mình trong round (kèm versions). Trả null nếu chưa nộp."""
    submission = await submission_service.get_my_submission_in_round(db, user, round_id)
    if submission is None:
        return None
    return SubmissionDetail.model_validate(submission)


# ---------- GV-04 ----------

@rounds_router.get(
    "/{round_id}/submissions",
    response_model=list[SubmissionOut],
)
async def list_round_submissions(
    round_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[SubmissionOut]:
    """GV-04 — Danh sách submissions trong round (BTC + JUDGE assigned only)."""
    subs = await submission_service.list_round_submissions(db, user, round_id)
    return [SubmissionOut.model_validate(s) for s in subs]


@submissions_router.get("/{submission_id}", response_model=SubmissionDetail)
async def get_submission_detail(
    submission_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionDetail:
    submission = await submission_service.get_submission_detail(db, user, submission_id)
    return SubmissionDetail.model_validate(submission)


@submissions_router.post("/{submission_id}/lock", response_model=SubmissionOut)
async def lock_submission(
    submission_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionOut:
    """GV-04 — Lock submission (SV không nộp tiếp được)."""
    submission = await submission_service.lock_submission(db, user, submission_id)
    return SubmissionOut.model_validate(submission)
