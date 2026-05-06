"""Notification business logic (SV-07).

Helper notify_users() có thể gọi từ các phase khác (vd: SV-06 register confirm).

Phase 1 step 4 (2026-05-06): hỗ trợ `mirror_email=True` để gửi email kèm in-app
notification cho event critical (entry approved, cert issued, contest published).
"""

import asyncio
import logging
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import NotificationScope
from app.models.identity import AppUser
from app.models.notification import Notification, NotificationRecipient
from app.services import email_service

log = logging.getLogger("notification")


def _fire_and_forget(coro) -> asyncio.Task:
    """Schedule async coroutine không block caller, log nếu task fail.

    Pattern này dùng cho email mirror — nếu SMTP timeout/fail không được làm
    fail action chính (approve entry, publish result, etc.).
    """
    task = asyncio.create_task(coro)

    def _on_done(t: asyncio.Task) -> None:
        exc = t.exception()
        if exc is not None:
            log.warning("Email mirror fail (fire-and-forget): %s", exc)

    task.add_done_callback(_on_done)
    return task


async def list_my_notifications(
    db: AsyncSession, user: AppUser, only_unread: bool = False, limit: int = 50
) -> tuple[list[tuple[Notification, NotificationRecipient]], int, int]:
    """Trả (items, total, unread_count)."""
    base_stmt = (
        select(Notification, NotificationRecipient)
        .join(
            NotificationRecipient,
            NotificationRecipient.notification_id == Notification.notification_id,
        )
        .where(NotificationRecipient.user_id == user.user_id)
        .order_by(desc(Notification.created_at))
    )
    if only_unread:
        base_stmt = base_stmt.where(NotificationRecipient.is_read.is_(False))

    items_stmt = base_stmt.limit(limit)
    rows = [(r[0], r[1]) for r in (await db.execute(items_stmt)).all()]

    total_stmt = select(func.count()).select_from(
        select(NotificationRecipient.notification_id)
        .where(NotificationRecipient.user_id == user.user_id)
        .subquery()
    )
    total = (await db.execute(total_stmt)).scalar_one()

    unread_stmt = (
        select(func.count())
        .select_from(NotificationRecipient)
        .where(
            NotificationRecipient.user_id == user.user_id,
            NotificationRecipient.is_read.is_(False),
        )
    )
    unread = (await db.execute(unread_stmt)).scalar_one()

    return rows, total, unread


async def mark_read(
    db: AsyncSession, user: AppUser, notification_id: int
) -> NotificationRecipient:
    stmt = select(NotificationRecipient).where(
        NotificationRecipient.notification_id == notification_id,
        NotificationRecipient.user_id == user.user_id,
    )
    rec = (await db.execute(stmt)).scalar_one_or_none()
    if rec is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Notification không có hoặc không thuộc bạn",
        )
    if not rec.is_read:
        rec.is_read = True
        rec.read_at = datetime.now(timezone.utc)
        await db.commit()
    return rec


async def mark_all_read(db: AsyncSession, user: AppUser) -> int:
    """Mark tất cả unread của user thành read. Trả count đã update."""
    stmt = select(NotificationRecipient).where(
        NotificationRecipient.user_id == user.user_id,
        NotificationRecipient.is_read.is_(False),
    )
    recs = (await db.execute(stmt)).scalars().all()
    now = datetime.now(timezone.utc)
    for r in recs:
        r.is_read = True
        r.read_at = now
    await db.commit()
    return len(recs)


# ---------- Helper for other modules ----------

async def notify_users(
    db: AsyncSession,
    *,
    title: str,
    message: str,
    user_ids: list[int],
    scope: NotificationScope = NotificationScope.SYSTEM,
    contest_id: int | None = None,
    created_by: int | None = None,
    mirror_email: bool = False,
    target_route: str | None = None,
) -> Notification:
    """Tạo 1 notification + bulk recipients. Gọi từ phase khác (vd: BCN approve → notify GV).

    Phase 1 step 4 (2026-05-06):
    - mirror_email=True: gửi email cho mỗi user (fire-and-forget, không block).
      Dùng cho event critical: entry approved, cert issued, contest published.
      Default False vì in-app đủ cho các thông báo thường xuyên (chống spam inbox).
    - target_route: nếu có sẽ thêm "Xem chi tiết" link trong email (vd "/contests/123").
    """
    if not user_ids:
        return None  # type: ignore[return-value]

    notif = Notification(
        scope=scope,
        contest_id=contest_id,
        title=title,
        message=message,
        is_global=False,
        target_route=target_route,  # Phase 2 step 1: deep-link FE navigate
        created_by=created_by,
        published_at=datetime.now(timezone.utc),
    )
    db.add(notif)
    await db.flush()

    for uid in set(user_ids):
        db.add(NotificationRecipient(notification_id=notif.notification_id, user_id=uid))

    await db.commit()
    await db.refresh(notif)

    # Phase 1 step 4: mirror sang email cho event critical
    if mirror_email:
        # Lookup email + full_name của các recipient
        emails_stmt = (
            select(AppUser.user_id, AppUser.email, AppUser.full_name)
            .where(AppUser.user_id.in_(set(user_ids)))
            .where(AppUser.status == "ACTIVE")  # Skip user đã bị lock/delete
        )
        rows = (await db.execute(emails_stmt)).all()
        for row in rows:
            _fire_and_forget(
                email_service.send_notification(
                    to_email=str(row.email),
                    full_name=row.full_name,
                    title=title,
                    body=message,
                    target_route=target_route,
                )
            )
        log.info(
            "Notification mirror email scheduled: count=%d title=%r",
            len(rows), title[:50],
        )

    return notif
