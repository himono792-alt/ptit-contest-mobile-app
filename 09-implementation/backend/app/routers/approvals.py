"""Approval router — endpoint cho BCN xem queue + decide.

Endpoints:
  GET  /api/me/pending-approvals          - BCN list pending của khoa mình
  GET  /api/approvals/{id}                - BCN detail 1 approval
  POST /api/approvals/{id}/decide         - BCN ra quyết định
  POST /api/contests/{id}/submit-for-approval — BTC submit (cũng có ở contests router để URL clean)
"""

from typing import Annotated

from fastapi import APIRouter, Body, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.models.enums import ApprovalTarget
from app.schemas.approval import (
    ApprovalDetail,
    ApprovalSummary,
    DecisionIn,
    SubmitForApprovalOut,
)
from app.services import approval_service

approvals_router = APIRouter(prefix="/approvals", tags=["approvals"])
me_pending_router = APIRouter(prefix="/me", tags=["approvals"])
contests_submit_router = APIRouter(prefix="/contests", tags=["approvals"])


# ---------- BTC submit ----------

@contests_submit_router.post(
    "/{contest_id}/submit-for-approval",
    response_model=SubmitForApprovalOut,
    status_code=status.HTTP_201_CREATED,
)
async def submit_contest_proposal(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    note: Annotated[str | None, Body(embed=True, description="Submission note (optional)")] = None,
) -> SubmitForApprovalOut:
    """GV-02 — BTC submit contest để BCN duyệt (BCN_QĐ1).

    Tạo workflow_approvals record mới với revision_round = max+1.
    Set contest.status = PROPOSED.
    """
    approval = await approval_service.submit_contest_proposal(db, user, contest_id, note)
    return SubmitForApprovalOut(
        approval_id=approval.approval_id,
        revision_round=approval.revision_round,
        target_type=approval.target_type,
        step=approval.step,
        status=approval.status,
    )


# ---------- BCN xem queue ----------

@me_pending_router.get("/pending-approvals", response_model=list[ApprovalSummary])
async def list_my_pending_approvals(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    type_filter: ApprovalTarget | None = None,
) -> list[ApprovalSummary]:
    """BCN-02 + BCN-04 — Queue đề xuất chờ duyệt cho BCN khoa mình.

    Query param `type_filter` = CONTEST_PROPOSAL (BCN_QĐ1) hoặc CONTEST_RESULT (BCN_QĐ2).
    """
    rows = await approval_service.list_pending_for_hod(db, user, type_filter)
    return [
        ApprovalSummary(
            approval_id=ap.approval_id,
            target_type=ap.target_type,
            contest_id=ap.contest_id,
            contest_title=contest.title,
            contest_slug=contest.slug,
            step=ap.step,
            status=ap.status,
            revision_round=ap.revision_round,
            submitted_by=ap.submitted_by,
            submitted_at=ap.submitted_at,
            submission_note=ap.submission_note,
        )
        for ap, contest in rows
    ]


# ---------- BCN detail + decide ----------

@approvals_router.get("/{approval_id}", response_model=ApprovalDetail)
async def get_approval_detail(
    approval_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ApprovalDetail:
    """BCN xem chi tiết approval (snapshot + lịch sử)."""
    ap, contest = await approval_service.get_approval_with_contest(db, user, approval_id)
    return ApprovalDetail(
        approval_id=ap.approval_id,
        target_type=ap.target_type,
        contest_id=ap.contest_id,
        contest_title=contest.title,
        contest_slug=contest.slug,
        step=ap.step,
        status=ap.status,
        revision_round=ap.revision_round,
        submitted_by=ap.submitted_by,
        submitted_at=ap.submitted_at,
        submission_note=ap.submission_note,
        reviewed_by=ap.reviewed_by,
        reviewed_at=ap.reviewed_at,
        bcn_comment=ap.bcn_comment,
        snapshot_json=ap.snapshot_json,
        created_at=ap.created_at,
        updated_at=ap.updated_at,
    )


@approvals_router.post("/{approval_id}/decide", response_model=ApprovalDetail)
async def decide_approval(
    approval_id: int,
    data: DecisionIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ApprovalDetail:
    """BCN-02 / BCN-04 — Ra quyết định: APPROVE / REJECT / REQUEST_REVISION."""
    ap = await approval_service.decide_approval(db, user, approval_id, data.action, data.comment)
    contest = await approval_service.get_approval_with_contest(db, user, approval_id)
    return ApprovalDetail(
        approval_id=ap.approval_id,
        target_type=ap.target_type,
        contest_id=ap.contest_id,
        contest_title=contest[1].title,
        contest_slug=contest[1].slug,
        step=ap.step,
        status=ap.status,
        revision_round=ap.revision_round,
        submitted_by=ap.submitted_by,
        submitted_at=ap.submitted_at,
        submission_note=ap.submission_note,
        reviewed_by=ap.reviewed_by,
        reviewed_at=ap.reviewed_at,
        bcn_comment=ap.bcn_comment,
        snapshot_json=ap.snapshot_json,
        created_at=ap.created_at,
        updated_at=ap.updated_at,
    )
