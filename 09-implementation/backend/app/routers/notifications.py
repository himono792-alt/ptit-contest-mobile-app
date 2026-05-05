"""Notifications router (SV-07)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.notification import NotificationListOut, NotificationOut
from app.services import notification_service

me_notifications_router = APIRouter(prefix="/me", tags=["notifications"])


@me_notifications_router.get("/notifications", response_model=NotificationListOut)
async def list_my_notifications(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    only_unread: bool = Query(False),
    limit: int = Query(50, ge=1, le=200),
) -> NotificationListOut:
    """SV-07 — List notifications của user. Sort theo created_at desc."""
    rows, total, unread = await notification_service.list_my_notifications(
        db, user, only_unread=only_unread, limit=limit
    )
    items = []
    for notif, recipient in rows:
        item = NotificationOut.model_validate(notif)
        item.is_read = recipient.is_read
        item.read_at = recipient.read_at
        items.append(item)
    return NotificationListOut(items=items, total=total, unread_count=unread)


@me_notifications_router.patch(
    "/notifications/{notification_id}/read",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def mark_read(
    notification_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await notification_service.mark_read(db, user, notification_id)


@me_notifications_router.post("/notifications/mark-all-read")
async def mark_all_read(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    count = await notification_service.mark_all_read(db, user)
    return {"marked_read": count}
