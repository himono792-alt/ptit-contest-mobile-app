"""Judging business logic (rubric + assignment + score + compute result)."""

from datetime import datetime, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest, ContestRound
from app.models.entry import ContestEntry
from app.models.enums import RegistrationStatus
from app.models.identity import AppUser
from app.models.judging import (
    JudgeAssignment,
    RoundResult,
    RoundScoreCriterion,
    Score,
)
from app.models.master_data import Judge
from app.schemas.judging import CriterionCreateIn, ScoreItemIn


# ---------- Helpers ----------

async def _ensure_btc_of_round(
    db: AsyncSession, user: AppUser, round_id: int
) -> tuple[ContestRound, Contest]:
    """Check user là BTC contest chứa round này."""
    round_obj = await db.get(ContestRound, round_id)
    if round_obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Round not found")
    contest = await db.get(Contest, round_obj.contest_id)
    assert contest is not None
    if "ADMIN" not in user.role_codes:
        if "ORGANIZER" not in user.role_codes:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần ORGANIZER")
        if contest.created_by != user.user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải BTC contest này")
    return round_obj, contest


# ---------- Rubric ----------

async def add_criterion(
    db: AsyncSession, user: AppUser, round_id: int, data: CriterionCreateIn
) -> RoundScoreCriterion:
    await _ensure_btc_of_round(db, user, round_id)

    crit = RoundScoreCriterion(round_id=round_id, **data.model_dump())
    db.add(crit)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "criterion_name hoặc display_order đã tồn tại trong round này",
        ) from e
    await db.refresh(crit)
    return crit


async def list_criteria(db: AsyncSession, round_id: int) -> list[RoundScoreCriterion]:
    stmt = (
        select(RoundScoreCriterion)
        .where(RoundScoreCriterion.round_id == round_id)
        .order_by(RoundScoreCriterion.display_order)
    )
    return list((await db.execute(stmt)).scalars().all())


async def delete_criterion(
    db: AsyncSession, user: AppUser, round_id: int, criterion_id: int
) -> None:
    await _ensure_btc_of_round(db, user, round_id)
    crit = await db.get(RoundScoreCriterion, criterion_id)
    if crit is None or crit.round_id != round_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Criterion not found")
    # Check chưa có score nào
    score_count_stmt = (
        select(func.count())
        .select_from(Score)
        .where(Score.criterion_id == criterion_id)
    )
    if (await db.execute(score_count_stmt)).scalar_one() > 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Đã có scores cho criterion này, không xóa được",
        )
    await db.delete(crit)
    await db.commit()


# ---------- Judge Assignment ----------

async def assign_judge(
    db: AsyncSession,
    user: AppUser,
    round_id: int,
    entry_id: int,
    judge_id: int,
    submission_id: int | None,
    can_view_identity: bool,
) -> JudgeAssignment:
    round_obj, _ = await _ensure_btc_of_round(db, user, round_id)

    entry = await db.get(ContestEntry, entry_id)
    if entry is None or entry.contest_id != round_obj.contest_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Entry không thuộc contest của round")
    if entry.registration_status != RegistrationStatus.APPROVED:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Entry chưa được duyệt (status={entry.registration_status.value})",
        )

    judge = await db.get(Judge, judge_id)
    if judge is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Judge not found")

    assignment = JudgeAssignment(
        round_id=round_id,
        entry_id=entry_id,
        judge_id=judge_id,
        submission_id=submission_id,
        can_view_identity=can_view_identity,
        assigned_by=user.user_id,
    )
    db.add(assignment)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Assignment (round, entry, judge) đã tồn tại",
        ) from e
    await db.refresh(assignment)
    return assignment


async def list_my_judge_assignments(
    db: AsyncSession, user: AppUser
) -> list[dict]:
    """JUDGE — list các assignment của mình (chấm bài nào).

    Sprint 18 fix (2026-05-08): trả `dict` thay model để enrich `is_scored`,
    `scored_count`, `total_criteria`. FE dùng để filter hero count + show
    pill "Đã chấm" thay vì im lặng giữ assignment trong list sau submit.

    Định nghĩa is_scored = (scored_count >= total_criteria) AND total_criteria > 0
    """
    judge_stmt = select(Judge).where(Judge.user_id == user.user_id)
    judge = (await db.execute(judge_stmt)).scalar_one_or_none()
    if judge is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User chưa có judge profile")

    stmt = (
        select(JudgeAssignment)
        .where(JudgeAssignment.judge_id == judge.judge_id)
        .order_by(desc(JudgeAssignment.assigned_at))
    )
    assignments = list((await db.execute(stmt)).scalars().all())
    if not assignments:
        return []

    # Bulk count criteria per round
    round_ids = {a.round_id for a in assignments}
    crit_stmt = (
        select(RoundScoreCriterion.round_id, func.count(RoundScoreCriterion.criterion_id))
        .where(RoundScoreCriterion.round_id.in_(round_ids))
        .group_by(RoundScoreCriterion.round_id)
    )
    criteria_count_by_round: dict[int, int] = {
        rid: cnt for rid, cnt in (await db.execute(crit_stmt)).all()
    }

    # Bulk count scores per assignment
    assignment_ids = [a.assignment_id for a in assignments]
    score_stmt = (
        select(Score.assignment_id, func.count(Score.score_id))
        .where(Score.assignment_id.in_(assignment_ids))
        .group_by(Score.assignment_id)
    )
    scored_count_by_assignment: dict[int, int] = {
        aid: cnt for aid, cnt in (await db.execute(score_stmt)).all()
    }

    out: list[dict] = []
    for a in assignments:
        total = criteria_count_by_round.get(a.round_id, 0)
        scored = scored_count_by_assignment.get(a.assignment_id, 0)
        out.append({
            "assignment_id": a.assignment_id,
            "round_id": a.round_id,
            "entry_id": a.entry_id,
            "submission_id": a.submission_id,
            "judge_id": a.judge_id,
            "assigned_by": a.assigned_by,
            "can_view_identity": a.can_view_identity,
            "assigned_at": a.assigned_at.isoformat(),
            # Sprint 18 enrichment fields
            "is_scored": scored >= total and total > 0,
            "scored_count": scored,
            "total_criteria": total,
        })
    return out


# ---------- Score ----------

async def submit_scores_bulk(
    db: AsyncSession, user: AppUser, assignment_id: int, items: list[ScoreItemIn]
) -> list[Score]:
    """JUDGE — submit điểm cho 1 assignment (bulk theo các criteria).

    Idempotent: nếu đã có score cho (assignment, criterion), update; nếu chưa, insert.
    """
    assignment = await db.get(JudgeAssignment, assignment_id)
    if assignment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Assignment not found")

    judge_stmt = select(Judge).where(Judge.user_id == user.user_id)
    judge = (await db.execute(judge_stmt)).scalar_one_or_none()
    if judge is None or judge.judge_id != assignment.judge_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Bạn không phải judge của assignment này",
        )

    # Validate scores ≤ max_score của từng criterion
    crit_stmt = (
        select(RoundScoreCriterion)
        .where(RoundScoreCriterion.round_id == assignment.round_id)
    )
    criteria_by_id = {
        c.criterion_id: c for c in (await db.execute(crit_stmt)).scalars().all()
    }

    saved: list[Score] = []
    for item in items:
        crit = criteria_by_id.get(item.criterion_id)
        if crit is None:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"criterion_id={item.criterion_id} không thuộc round của assignment",
            )
        if item.score_value > crit.max_score:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"score {item.score_value} vượt max_score {crit.max_score} của '{crit.criterion_name}'",
            )

        # Find existing score (assignment, criterion) — UNIQUE constraint
        exist_stmt = select(Score).where(
            Score.assignment_id == assignment_id,
            Score.criterion_id == item.criterion_id,
        )
        existing = (await db.execute(exist_stmt)).scalar_one_or_none()
        if existing:
            existing.score_value = item.score_value
            existing.comment_text = item.comment_text
            existing.scored_at = datetime.now(timezone.utc)
            saved.append(existing)
        else:
            new_score = Score(
                assignment_id=assignment_id,
                criterion_id=item.criterion_id,
                score_value=item.score_value,
                comment_text=item.comment_text,
            )
            db.add(new_score)
            saved.append(new_score)

    await db.commit()
    for s in saved:
        await db.refresh(s)
    return saved


# ---------- Compute Round Results ----------

async def compute_round_results(
    db: AsyncSession, user: AppUser, round_id: int
) -> list[RoundResult]:
    """GV-05 POST /api/rounds/{id}/compute-results.

    Logic:
      1. Cho mỗi entry có ≥1 assignment trong round:
         a. Group scores theo criterion → average across judges
         b. Weighted total = SUM(avg_score × weight_percent / 100)
            (Nếu weight_percent NULL: dùng max_score làm trọng số)
      2. Sắp xếp theo total → rank_no
      3. UPSERT vào round_results
    """
    round_obj, _ = await _ensure_btc_of_round(db, user, round_id)

    # 1. Lấy criteria
    criteria = await list_criteria(db, round_id)
    if not criteria:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Round chưa có criteria. Define rubric trước.",
        )

    # 2. Lấy tất cả scores trong round (qua join assignment)
    score_stmt = (
        select(
            JudgeAssignment.entry_id,
            Score.criterion_id,
            func.avg(Score.score_value).label("avg_score"),
        )
        .join(Score, Score.assignment_id == JudgeAssignment.assignment_id)
        .where(JudgeAssignment.round_id == round_id)
        .group_by(JudgeAssignment.entry_id, Score.criterion_id)
    )
    rows = (await db.execute(score_stmt)).all()
    if not rows:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Chưa có score nào để compute. Judges cần chấm trước.",
        )

    # 3. Aggregate per entry
    crit_by_id = {c.criterion_id: c for c in criteria}
    per_entry: dict[int, Decimal] = {}
    per_entry_count: dict[int, int] = {}

    for row in rows:
        entry_id, crit_id, avg = row
        crit = crit_by_id.get(crit_id)
        if crit is None:
            continue
        weight = crit.weight_percent if crit.weight_percent is not None else Decimal("100")
        contribution = Decimal(str(avg)) * weight / Decimal("100")
        per_entry[entry_id] = per_entry.get(entry_id, Decimal("0")) + contribution
        per_entry_count[entry_id] = per_entry_count.get(entry_id, 0) + 1

    # 4. Rank
    ranked = sorted(per_entry.items(), key=lambda kv: kv[1], reverse=True)

    # 5. UPSERT round_results
    saved: list[RoundResult] = []
    for rank_no, (entry_id, total) in enumerate(ranked, start=1):
        avg = total / Decimal(per_entry_count[entry_id]) if per_entry_count[entry_id] else None
        existing = (await db.execute(
            select(RoundResult).where(
                RoundResult.round_id == round_id,
                RoundResult.entry_id == entry_id,
            )
        )).scalar_one_or_none()
        if existing:
            existing.total_score = total
            existing.average_score = avg
            existing.rank_no = rank_no
            existing.generated_by = user.user_id
            saved.append(existing)
        else:
            rr = RoundResult(
                round_id=round_id,
                entry_id=entry_id,
                total_score=total,
                average_score=avg,
                rank_no=rank_no,
                generated_by=user.user_id,
            )
            db.add(rr)
            saved.append(rr)

    await db.commit()
    for r in saved:
        await db.refresh(r)
    return sorted(saved, key=lambda r: r.rank_no or 999999)


async def list_round_results(db: AsyncSession, round_id: int) -> list[RoundResult]:
    stmt = (
        select(RoundResult)
        .where(RoundResult.round_id == round_id)
        .order_by(RoundResult.rank_no.nulls_last())
    )
    return list((await db.execute(stmt)).scalars().all())
