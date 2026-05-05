"""Pydantic schemas cho notifications (SV-07)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.enums import NotificationScope


class NotificationOut(BaseModel):
    """Notification + read state của user hiện tại."""

    model_config = ConfigDict(from_attributes=True)

    notification_id: int
    scope: NotificationScope
    contest_id: int | None = None
    title: str
    message: str
    is_global: bool
    published_at: datetime | None = None
    created_at: datetime
    is_read: bool = False
    read_at: datetime | None = None


class NotificationListOut(BaseModel):
    items: list[NotificationOut]
    total: int
    unread_count: int
