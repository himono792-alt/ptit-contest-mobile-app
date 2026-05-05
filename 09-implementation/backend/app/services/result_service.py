"""Contest result business logic (GV-06 compute + publish, SV-09 view)."""

from datetime import datetime, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.contest import Contest, ContestRound
from app.models.entry import ContestEntry, TeamMember
from app.models.enums import (
    ApprovalStatus,
    ApprovalTarget,
    ContestStatus,
    EntryType,
)
from app.models.identity import AppUser
from app.models.judging import ContestResult, RoundResult
from app.models.master_data import Student
from app.models.workflow import WorkflowApproval


# ---------- Helpers ----------

async def _ensure_btc(db: AsyncSession, user: AppUser, contest: Contest) -> None:
    if "ADMIN" in user.role_codes:
        return
    if "ORGANIZER" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần ORGANIZER")
    if contest.created_by != user.user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải BTC contest này")


# ---------- Compute ----------

async def compute_contest_results(
    db: AsyncSession, user: AppUser, contest_id: int
) -> list[ContestResult]:
    """GV-06 — Tổng hợp round_results → contest_results.

    Logic đơn giản: final_score = SUM(round_total_score) qua tất cả rounds.
    Sort → rank_no.
    UPSERT (insert or update existing).
    """
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_btc(db, user, contest)

    # Aggregate qua tất cả rounds của contest
    stmt = (
        select(
            RoundResult.entry_id,
            func.sum(RoundResult.total_score).label("final_score"),
        )
        .join(ContestRound, ContestRound.round_id == RoundResult.round_id)
        .where(ContestRound.contest_id == contest_id)
        .group_by(RoundResult.entry_id)
    )
    rows = (await db.execute(stmt)).all()
    if not rows:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Chưa có round_results nào để tổng hợp. Chạy /rounds/{id}/compute-results trước.",
        )

    # Rank
    ranked = sorted(rows, key=lambda r: (r.final_score or Decimal("0")), reverse=True)

    saved: list[ContestResult] = []
    for rank_no, row in enumerate(ranked, start=1):
        existing = (await db.execute(
            select(ContestResult).where(
                ContestResult.contest_id == contest_id,
                ContestResult.entry_id == row.entry_id,
            )
        )).scalar_one_or_none()
        if existing:
            # Reset approval status nếu đang APPROVED và compute lại (BTC sửa kết quả)
            if existing.bcn_approval_status == ApprovalStatus.APPROVED:
                existing.bcn_approval_status = ApprovalStatus.PENDING
                existing.published_at = None
            existing.final_score = row.final_score
            existing.rank_no = rank_no
            existing.generated_by = user.user_id
            saved.append(existing)
        else:
            cr = ContestResult(
                contest_id=contest_id,
                entry_id=row.entry_id,
                final_score=row.final_score,
                rank_no=rank_no,
                bcn_approval_status=ApprovalStatus.PENDING,
                generated_by=user.user_id,
            )
            db.add(cr)
            saved.append(cr)

    await db.commit()
    for r in saved:
        await db.refresh(r)
    return sorted(saved, key=lambda r: r.rank_no or 999999)


async def list_contest_results(db: AsyncSession, contest_id: int) -> list[ContestResult]:
    stmt = (
        select(ContestResult)
        .where(ContestResult.contest_id == contest_id)
        .order_by(ContestResult.rank_no.nulls_last())
    )
    return list((await db.execute(stmt)).scalars().all())


async def update_award(
    db: AsyncSession, user: AppUser, contest_result_id: int, award_title: str | None
) -> ContestResult:
    """GV-06 PATCH — chỉnh giải thưởng cho 1 entry."""
    cr = await db.get(ContestResult, contest_result_id)
    if cr is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "ContestResult not found")
    contest = await db.get(Contest, cr.contest_id)
    assert contest is not None
    await _ensure_btc(db, user, contest)

    cr.award_title = award_title
    await db.commit()
    await db.refresh(cr)
    return cr


# ---------- Submit BCN_QD2 ----------

async def submit_results_for_approval(
    db: AsyncSession, user: AppUser, contest_id: int, note: str | None
) -> WorkflowApproval:
    """GV-06 POST /api/contests/{id}/results/submit-for-approval (BCN_QĐ2).

    Pre-condition: phải có ≥1 contest_results đã compute.
    """
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_btc(db, user, contest)

    # Check có results
    count_stmt = (
        select(func.count())
        .select_from(ContestResult)
        .where(ContestResult.contest_id == contest_id)
    )
    if (await db.execute(count_stmt)).scalar_one() == 0:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Chưa có contest_results. Compute trước.",
        )

    if contest.host_faculty_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Contest cần host_faculty_id để biết BCN nào duyệt",
        )

    # Find max revision_round
    from app.models.enums import ApprovalStep

    max_rev_stmt = select(func.coalesce(func.max(WorkflowApproval.revision_round), 0)).where(
        WorkflowApproval.contest_id == contest_id,
        WorkflowApproval.target_type == ApprovalTarget.CONTEST_RESULT,
    )
    next_rev = (await db.execute(max_rev_stmt)).scalar_one() + 1

    # Snapshot
    results = await list_contest_results(db, contest_id)
    snapshot = {
        "contest_id": contest_id,
        "results": [
            {
                "entry_id": r.entry_id,
                "rank_no": r.rank_no,
                "final_score": float(r.final_score) if r.final_score else None,
                "award_title": r.award_title,
            }
            for r in results
        ],
    }

    approval = WorkflowApproval(
        target_type=ApprovalTarget.CONTEST_RESULT,
        contest_id=contest_id,
        step=ApprovalStep.BCN_QD2,
        status=ApprovalStatus.PENDING,
        revision_round=next_rev,
        submitted_by=user.user_id,
        submission_note=note,
        snapshot_json=snapshot,
    )
    db.add(approval)
    await db.commit()
    await db.refresh(approval)
    return approval


# ---------- Publish ----------

async def publish_results(
    db: AsyncSession, user: AppUser, contest_id: int
) -> tuple[Contest, datetime, int]:
    """GV-06 POST /api/contests/{id}/results/publish.

    Pre-condition: workflow_approvals(target=CONTEST_RESULT) latest revision = APPROVED.
    Set: contest_results.published_at, contest.status = FINISHED.
    """
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_btc(db, user, contest)

    # Check latest BCN_QD2 approval = APPROVED
    latest_stmt = (
        select(WorkflowApproval)
        .where(
            WorkflowApproval.contest_id == contest_id,
            WorkflowApproval.target_type == ApprovalTarget.CONTEST_RESULT,
        )
        .order_by(desc(WorkflowApproval.revision_round))
        .limit(1)
    )
    latest = (await db.execute(latest_stmt)).scalar_one_or_none()
    if latest is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Chưa submit-for-approval. Submit trước, BCN duyệt rồi mới publish được.",
        )
    if latest.status != ApprovalStatus.APPROVED:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"BCN_QĐ2 chưa APPROVED (hiện: {latest.status.value}). Không publish được.",
        )

    # Set published_at cho all results
    now = datetime.now(timezone.utc)
    results = await list_contest_results(db, contest_id)
    for r in results:
        r.published_at = now
        # bcn_approval_status đã set bởi decide_approval handler

    contest.status = ContestStatus.FINISHED

    await db.commit()
    return contest, now, len(results)


# ---------- SV view own results ----------

async def list_my_results(db: AsyncSession, user: AppUser) -> list[dict]:
    """SV-09 — list các contest_results đã publish của SV.

    Returns dict thay vì model để có thêm contest_title/slug.
    """
    student_stmt = select(Student).where(Student.user_id == user.user_id)
    student = (await db.execute(student_stmt)).scalar_one_or_none()
    if student is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User không phải sinh viên")

    # Find entries của SV (individual + team membership)
    indiv_stmt = (
        select(ContestEntry.entry_id)
        .where(
            ContestEntry.student_id == student.student_id,
            ContestEntry.entry_type == EntryType.INDIVIDUAL,
        )
    )
    team_stmt = (
        select(ContestEntry.entry_id)
        .join(TeamMember, TeamMember.team_id == ContestEntry.team_id)
        .where(
            ContestEntry.entry_type == EntryType.TEAM,
            TeamMember.student_id == student.student_id,
        )
    )
    entry_ids = (await db.execute(indiv_stmt.union(team_stmt))).scalars().all()
    if not entry_ids:
        return []

    # Get published results với contest info
    stmt = (
        select(ContestResult, Contest)
        .join(Contest, Contest.contest_id == ContestResult.contest_id)
        .where(
            ContestResult.entry_id.in_(entry_ids),
            ContestResult.published_at.is_not(None),
        )
        .order_by(desc(ContestResult.published_at))
    )
    rows = (await db.execute(stmt)).all()
    return [
        {
            "contest_id": cr.contest_id,
            "contest_title": contest.title,
            "contest_slug": contest.slug,
            "entry_id": cr.entry_id,
            "final_score": cr.final_score,
            "rank_no": cr.rank_no,
            "award_title": cr.award_title,
            "published_at": cr.published_at,
        }
        for cr, contest in rows
    ]
