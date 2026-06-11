"""Audit log query + review moderation (AD-06)."""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.identity import AppUser
from app.models.review import ContestReview
from app.models.system import AuditLog


def _ensure_admin(user: AppUser) -> None:
    if "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ADMIN")


# ---------- Audit log query ----------

async def list_audit_logs(
    db: AsyncSession,
    user: AppUser,
    *,
    user_id: int | None,
    action_type: str | None,
    entity_name: str | None,
    date_from: datetime | None,
    date_to: datetime | None,
    offset: int,
    limit: int,
) -> tuple[list[AuditLog], int]:
    _ensure_admin(user)

    base = select(AuditLog)
    if user_id is not None:
        base = base.where(AuditLog.user_id == user_id)
    if action_type:
        base = base.where(AuditLog.action_type.ilike(f"%{action_type}%"))
    if entity_name:
        base = base.where(AuditLog.entity_name == entity_name)
    if date_from:
        base = base.where(AuditLog.created_at >= date_from)
    if date_to:
        base = base.where(AuditLog.created_at <= date_to)

    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    rows = (await db.execute(
        base.order_by(desc(AuditLog.created_at)).offset(offset).limit(limit)
    )).scalars().all()
    return list(rows), total


# ---------- Review moderation ----------

async def moderate_review(
    db: AsyncSession,
    user: AppUser,
    review_id: int,
    is_visible: bool,
    note: str | None,
) -> ContestReview:
    _ensure_admin(user)
    review = await db.get(ContestReview, review_id)
    if review is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Review not found")

    review.is_visible = is_visible
    review.moderated_by = user.user_id
    review.moderated_at = datetime.now(timezone.utc)
    review.moderation_note = note
    await db.commit()
    await db.refresh(review)
    return review


async def list_all_reviews(
    db: AsyncSession,
    user: AppUser,
    contest_id: int | None,
    only_hidden: bool,
    offset: int,
    limit: int,
) -> tuple[list[ContestReview], int]:
    """AD-06 — list ALL reviews (kể cả hidden) cho admin."""
    _ensure_admin(user)
    base = select(ContestReview)
    if contest_id is not None:
        base = base.where(ContestReview.contest_id == contest_id)
    if only_hidden:
        base = base.where(ContestReview.is_visible.is_(False))

    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    rows = (await db.execute(
        base.order_by(desc(ContestReview.created_at)).offset(offset).limit(limit)
    )).scalars().all()
    return list(rows), total
