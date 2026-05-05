"""Contest review business logic (SV-11)."""

from collections import Counter

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest
from app.models.entry import ContestEntry, TeamMember
from app.models.enums import ContestStatus, EntryType
from app.models.identity import AppUser
from app.models.judging import ContestResult
from app.models.master_data import Student
from app.models.review import ContestReview


async def _get_my_student(db: AsyncSession, user: AppUser) -> Student:
    s = (await db.execute(select(Student).where(Student.user_id == user.user_id))).scalar_one_or_none()
    if s is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User không phải sinh viên")
    return s


async def _student_has_published_result(
    db: AsyncSession, contest_id: int, student_id: int
) -> bool:
    """SV chỉ review được nếu đã có contest_results published cho contest này."""
    indiv_stmt = (
        select(ContestEntry.entry_id)
        .where(
            ContestEntry.contest_id == contest_id,
            ContestEntry.student_id == student_id,
            ContestEntry.entry_type == EntryType.INDIVIDUAL,
        )
    )
    team_stmt = (
        select(ContestEntry.entry_id)
        .join(TeamMember, TeamMember.team_id == ContestEntry.team_id)
        .where(
            ContestEntry.contest_id == contest_id,
            ContestEntry.entry_type == EntryType.TEAM,
            TeamMember.student_id == student_id,
        )
    )
    entry_ids = (await db.execute(indiv_stmt.union(team_stmt))).scalars().all()
    if not entry_ids:
        return False

    result_stmt = (
        select(func.count())
        .select_from(ContestResult)
        .where(
            ContestResult.contest_id == contest_id,
            ContestResult.entry_id.in_(entry_ids),
            ContestResult.published_at.is_not(None),
        )
    )
    return (await db.execute(result_stmt)).scalar_one() > 0


async def create_review(
    db: AsyncSession, user: AppUser, contest_id: int, rating: int, comment: str | None
) -> ContestReview:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if contest.status != ContestStatus.FINISHED:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ review được khi contest FINISHED. Hiện: {contest.status.value}",
        )

    student = await _get_my_student(db, user)
    if not await _student_has_published_result(db, contest_id, student.student_id):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Bạn chưa có kết quả published trong contest này",
        )

    review = ContestReview(
        contest_id=contest_id,
        student_id=student.student_id,
        rating=rating,
        comment_text=comment,
    )
    db.add(review)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Bạn đã review contest này rồi (mỗi SV review 1 lần). Dùng PATCH để sửa.",
        ) from e
    await db.refresh(review)
    return review


async def update_my_review(
    db: AsyncSession,
    user: AppUser,
    contest_id: int,
    rating: int | None,
    comment: str | None,
) -> ContestReview:
    student = await _get_my_student(db, user)
    stmt = select(ContestReview).where(
        ContestReview.contest_id == contest_id,
        ContestReview.student_id == student.student_id,
    )
    review = (await db.execute(stmt)).scalar_one_or_none()
    if review is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bạn chưa review contest này")
    if rating is not None:
        review.rating = rating
    if comment is not None:
        review.comment_text = comment
    await db.commit()
    await db.refresh(review)
    return review


async def list_visible_reviews(db: AsyncSession, contest_id: int) -> list[ContestReview]:
    """Public — chỉ lấy reviews is_visible=TRUE."""
    stmt = (
        select(ContestReview)
        .where(
            ContestReview.contest_id == contest_id,
            ContestReview.is_visible.is_(True),
        )
        .order_by(ContestReview.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def get_summary(db: AsyncSession, contest_id: int) -> dict:
    """Aggregate stats — total + average + distribution."""
    stmt = select(ContestReview.rating).where(
        ContestReview.contest_id == contest_id,
        ContestReview.is_visible.is_(True),
    )
    ratings = list((await db.execute(stmt)).scalars().all())
    if not ratings:
        return {"total": 0, "average_rating": 0.0, "distribution": {}}
    counter = Counter(ratings)
    return {
        "total": len(ratings),
        "average_rating": round(sum(ratings) / len(ratings), 2),
        "distribution": {i: counter.get(i, 0) for i in range(1, 6)},
    }
