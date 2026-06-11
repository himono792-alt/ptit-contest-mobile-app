"""Workflow approval business logic (BCN_QĐ1 + BCN_QĐ2).

Pattern: mỗi lần BTC submit là tạo workflow_approvals record MỚI với
revision_round = max+1. Không update record cũ. Mỗi record chứa
snapshot_json để audit/diff.
"""

from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest, ContestRound
from app.models.enums import (
    ApprovalStatus,
    ApprovalStep,
    ApprovalTarget,
    ContestStatus,
)
from app.models.identity import AppUser
from app.models.judging import ContestResult
from app.models.master_data import DepartmentHead
from app.models.workflow import WorkflowApproval
from app.schemas.approval import DecideAction


# ---------- Helpers ----------

async def _ensure_hod_for_contest(db: AsyncSession, user: AppUser, contest: Contest) -> None:
    if "ADMIN" in user.role_codes:
        return
    if "HOD" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role HOD để duyệt")
    stmt = select(DepartmentHead).where(DepartmentHead.user_id == user.user_id)
    dh = (await db.execute(stmt)).scalar_one_or_none()
    if dh is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User chưa có profile department_head")
    if contest.host_faculty_id != dh.faculty_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Bạn là BCN khoa #{dh.faculty_id}, không duyệt được contest khoa #{contest.host_faculty_id}",
        )


async def _build_contest_snapshot(db: AsyncSession, contest: Contest) -> dict[str, Any]:
    rounds_stmt = select(ContestRound).where(ContestRound.contest_id == contest.contest_id)
    rounds = (await db.execute(rounds_stmt)).scalars().all()
    return {
        "title": contest.title,
        "slug": contest.slug,
        "delivery_mode": contest.delivery_mode.value,
        "participation_mode": contest.participation_mode.value,
        "start_at": contest.start_at.isoformat(),
        "end_at": contest.end_at.isoformat(),
        "max_entries": contest.max_entries,
        "host_faculty_id": contest.host_faculty_id,
        "rounds": [
            {
                "round_no": r.round_no,
                "round_name": r.round_name,
                "round_type": r.round_type.value,
                "start_at": r.start_at.isoformat(),
                "end_at": r.end_at.isoformat(),
            }
            for r in rounds
        ],
    }


# ---------- Submit ----------

async def submit_contest_proposal(
    db: AsyncSession, user: AppUser, contest_id: int, note: str | None
) -> WorkflowApproval:
    """GV-02 — BTC submit cuộc thi cho BCN duyệt (BCN_QĐ1)."""
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")

    if "ADMIN" not in user.role_codes and contest.created_by != user.user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ owner mới submit được")

    if contest.status not in (ContestStatus.DRAFT, ContestStatus.REVISION_REQUESTED):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ submit khi DRAFT/REVISION_REQUESTED. Hiện: {contest.status.value}",
        )
    if contest.host_faculty_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Contest cần host_faculty_id để biết BCN nào duyệt",
        )

    max_rev_stmt = select(func.coalesce(func.max(WorkflowApproval.revision_round), 0)).where(
        WorkflowApproval.contest_id == contest_id,
        WorkflowApproval.target_type == ApprovalTarget.CONTEST_PROPOSAL,
    )
    next_rev = (await db.execute(max_rev_stmt)).scalar_one() + 1

    snapshot = await _build_contest_snapshot(db, contest)

    approval = WorkflowApproval(
        target_type=ApprovalTarget.CONTEST_PROPOSAL,
        contest_id=contest_id,
        step=ApprovalStep.BCN_QD1,
        status=ApprovalStatus.PENDING,
        revision_round=next_rev,
        submitted_by=user.user_id,
        submission_note=note,
        snapshot_json=snapshot,
    )
    db.add(approval)
    contest.status = ContestStatus.PROPOSED
    await db.commit()
    await db.refresh(approval)
    return approval


# ---------- Decide ----------

_ACTION_TO_STATUS = {
    DecideAction.APPROVE: ApprovalStatus.APPROVED,
    DecideAction.REJECT: ApprovalStatus.REJECTED,
    DecideAction.REQUEST_REVISION: ApprovalStatus.REVISION_REQUESTED,
}

_PROPOSAL_NEXT_STATUS = {
    DecideAction.APPROVE: ContestStatus.PUBLISHED,
    DecideAction.REJECT: ContestStatus.DRAFT,
    DecideAction.REQUEST_REVISION: ContestStatus.REVISION_REQUESTED,
}


async def decide_approval(
    db: AsyncSession,
    user: AppUser,
    approval_id: int,
    action: DecideAction,
    comment: str | None,
) -> WorkflowApproval:
    """BCN-02 / BCN-04 — BCN review + ra quyết định."""
    approval = await db.get(WorkflowApproval, approval_id)
    if approval is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Approval not found")
    if approval.status != ApprovalStatus.PENDING:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Approval đã được decide (status={approval.status.value})",
        )

    contest = await db.get(Contest, approval.contest_id)
    assert contest is not None
    await _ensure_hod_for_contest(db, user, contest)

    if action != DecideAction.APPROVE and not (comment and comment.strip()):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Comment bắt buộc khi REJECT hoặc REQUEST_REVISION",
        )

    approval.status = _ACTION_TO_STATUS[action]
    approval.reviewed_by = user.user_id
    approval.bcn_comment = comment
    approval.reviewed_at = datetime.now(timezone.utc)

    # Side effect on contest / contest_results
    if approval.target_type == ApprovalTarget.CONTEST_PROPOSAL:
        contest.status = _PROPOSAL_NEXT_STATUS[action]
    elif approval.target_type == ApprovalTarget.CONTEST_RESULT:
        # Update bcn_approval_status cho TẤT CẢ contest_results của contest
        cr_stmt = select(ContestResult).where(ContestResult.contest_id == contest.contest_id)
        for cr in (await db.execute(cr_stmt)).scalars().all():
            cr.bcn_approval_status = _ACTION_TO_STATUS[action]

    await db.commit()
    await db.refresh(approval)
    return approval


# ---------- Query ----------

async def list_pending_for_hod(
    db: AsyncSession, user: AppUser, target_type: ApprovalTarget | None = None
) -> list[tuple[WorkflowApproval, Contest]]:
    if "ADMIN" not in user.role_codes:
        dh_stmt = select(DepartmentHead).where(DepartmentHead.user_id == user.user_id)
        dh = (await db.execute(dh_stmt)).scalar_one_or_none()
        if dh is None:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "User chưa có profile HOD")
        faculty_filter = dh.faculty_id
    else:
        faculty_filter = None

    stmt = (
        select(WorkflowApproval, Contest)
        .join(Contest, Contest.contest_id == WorkflowApproval.contest_id)
        .where(WorkflowApproval.status == ApprovalStatus.PENDING)
        .order_by(desc(WorkflowApproval.submitted_at))
    )
    if target_type is not None:
        stmt = stmt.where(WorkflowApproval.target_type == target_type)
    if faculty_filter is not None:
        stmt = stmt.where(Contest.host_faculty_id == faculty_filter)

    return [(row[0], row[1]) for row in (await db.execute(stmt)).all()]


async def get_approval_with_contest(
    db: AsyncSession, user: AppUser, approval_id: int
) -> tuple[WorkflowApproval, Contest]:
    approval = await db.get(WorkflowApproval, approval_id)
    if approval is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Approval not found")
    contest = await db.get(Contest, approval.contest_id)
    assert contest is not None
    await _ensure_hod_for_contest(db, user, contest)
    return approval, contest
