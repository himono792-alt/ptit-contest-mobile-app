"""Result router (GV-06 compute/submit/publish, SV-09 view)."""

from typing import Annotated

from fastapi import APIRouter, Body, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.approval import SubmitForApprovalOut
from app.schemas.result import (
    AwardUpdateIn,
    ContestResultOut,
    MyResultOut,
    PublishResultsOut,
)
from app.services import result_service

contests_results_router = APIRouter(prefix="/contests", tags=["results"])
me_results_router = APIRouter(prefix="/me", tags=["results"])
contest_result_router = APIRouter(prefix="/contest-results", tags=["results"])


# ---------- GV-06 compute + list + update award ----------

@contests_results_router.post(
    "/{contest_id}/results/compute",
    response_model=list[ContestResultOut],
)
async def compute_results(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ContestResultOut]:
    """GV-06 — Aggregate round_results → contest_results với rank."""
    items = await result_service.compute_contest_results(db, user, contest_id)
    return [ContestResultOut.model_validate(r) for r in items]


@contests_results_router.get(
    "/{contest_id}/results",
    response_model=list[ContestResultOut],
)
async def list_results(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ContestResultOut]:
    """List contest_results (public — anyone xem được nếu published)."""
    items = await result_service.list_contest_results(db, contest_id)
    return [ContestResultOut.model_validate(r) for r in items]


@contest_result_router.patch(
    "/{contest_result_id}",
    response_model=ContestResultOut,
)
async def update_award(
    contest_result_id: int,
    data: AwardUpdateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestResultOut:
    """GV-06 — Chỉnh giải thưởng cho 1 entry (vd: 'Giải Nhất')."""
    cr = await result_service.update_award(db, user, contest_result_id, data.award_title)
    return ContestResultOut.model_validate(cr)


# ---------- GV-06 submit BCN_QD2 ----------

@contests_results_router.post(
    "/{contest_id}/results/submit-for-approval",
    response_model=SubmitForApprovalOut,
    status_code=status.HTTP_201_CREATED,
)
async def submit_results_for_approval(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    note: Annotated[str | None, Body(embed=True)] = None,
) -> SubmitForApprovalOut:
    """GV-06 — BTC submit kết quả cho BCN duyệt (BCN_QĐ2)."""
    approval = await result_service.submit_results_for_approval(db, user, contest_id, note)
    return SubmitForApprovalOut(
        approval_id=approval.approval_id,
        revision_round=approval.revision_round,
        target_type=approval.target_type,
        step=approval.step,
        status=approval.status,
    )


# ---------- GV-06 publish ----------

@contests_results_router.post(
    "/{contest_id}/results/publish",
    response_model=PublishResultsOut,
)
async def publish_results(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> PublishResultsOut:
    """GV-06 — Publish results (cần BCN_QĐ2 APPROVED). Set contest = FINISHED."""
    contest, published_at, count = await result_service.publish_results(db, user, contest_id)
    return PublishResultsOut(
        contest_id=contest.contest_id,
        published_at=published_at,
        contest_status=contest.status.value,
        notified_count=count,  # TODO: thêm bulk notification thật
    )


# ---------- SV-09 ----------

@me_results_router.get("/results", response_model=list[MyResultOut])
async def list_my_results(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[MyResultOut]:
    """SV-09 — Lịch sử kết quả của SV (chỉ contest đã published)."""
    items = await result_service.list_my_results(db, user)
    return [MyResultOut.model_validate(it) for it in items]
