"""Judging router (rubric + assignment + score + compute results)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.judging import (
    CriterionCreateIn,
    CriterionOut,
    JudgeAssignmentCreateIn,
    JudgeAssignmentOut,
    RoundResultOut,
    ScoreBulkIn,
    ScoreOut,
)
from app.services import judging_service

# 3 router prefix khác nhau
rounds_router = APIRouter(prefix="/rounds", tags=["judging"])
me_assignments_router = APIRouter(prefix="/me", tags=["judging"])
assignments_router = APIRouter(prefix="/assignments", tags=["judging"])


# ---------- Rubric ----------

@rounds_router.get("/{round_id}/criteria", response_model=list[CriterionOut])
async def list_criteria(
    round_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[CriterionOut]:
    crits = await judging_service.list_criteria(db, round_id)
    return [CriterionOut.model_validate(c) for c in crits]


@rounds_router.post(
    "/{round_id}/criteria",
    response_model=CriterionOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_criterion(
    round_id: int,
    data: CriterionCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CriterionOut:
    """GV-05 — Define rubric criterion cho round."""
    crit = await judging_service.add_criterion(db, user, round_id, data)
    return CriterionOut.model_validate(crit)


@rounds_router.delete(
    "/{round_id}/criteria/{criterion_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_criterion(
    round_id: int,
    criterion_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """GV-05 — Xóa criterion (chỉ khi chưa có score)."""
    await judging_service.delete_criterion(db, user, round_id, criterion_id)


# ---------- Judge Assignment ----------

@rounds_router.post(
    "/{round_id}/judge-assignments",
    response_model=JudgeAssignmentOut,
    status_code=status.HTTP_201_CREATED,
)
async def assign_judge(
    round_id: int,
    data: JudgeAssignmentCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> JudgeAssignmentOut:
    """GV-05 — Phân công judge chấm 1 entry trong round."""
    assignment = await judging_service.assign_judge(
        db, user, round_id, data.entry_id, data.judge_id,
        data.submission_id, data.can_view_identity,
    )
    return JudgeAssignmentOut.model_validate(assignment)


@me_assignments_router.get("/judge-assignments")
async def list_my_assignments(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[dict]:
    """JUDGE — Xem các assignment của mình (cần chấm).

    Sprint 18 fix (2026-05-08): trả `list[dict]` enriched với is_scored +
    scored_count + total_criteria. FE filter "Bài cần chấm" theo is_scored
    để assignment không còn xuất hiện sau khi submit (cũ: vẫn hiện y nguyên).
    """
    return await judging_service.list_my_judge_assignments(db, user)


# ---------- Score ----------

@assignments_router.post(
    "/{assignment_id}/scores",
    response_model=list[ScoreOut],
    status_code=status.HTTP_200_OK,
)
async def submit_scores(
    assignment_id: int,
    data: ScoreBulkIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ScoreOut]:
    """JUDGE — Submit điểm cho assignment (bulk theo các criteria, idempotent)."""
    items = await judging_service.submit_scores_bulk(db, user, assignment_id, data.scores)
    return [ScoreOut.model_validate(s) for s in items]


# ---------- Round Results ----------

@rounds_router.post(
    "/{round_id}/compute-results",
    response_model=list[RoundResultOut],
)
async def compute_results(
    round_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[RoundResultOut]:
    """GV-05 — Tổng hợp scores → round_results với rank."""
    results = await judging_service.compute_round_results(db, user, round_id)
    return [RoundResultOut.model_validate(r) for r in results]


@rounds_router.get("/{round_id}/results", response_model=list[RoundResultOut])
async def list_results(
    round_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[RoundResultOut]:
    results = await judging_service.list_round_results(db, round_id)
    return [RoundResultOut.model_validate(r) for r in results]
