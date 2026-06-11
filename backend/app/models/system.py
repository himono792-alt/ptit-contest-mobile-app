"""System config + audit log."""

from datetime import datetime

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, String, Text, func,
)
from sqlalchemy.dialects.postgresql import INET, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.enums import ConfigValueType


class SystemConfig(Base):
    __tablename__ = "system_configs"

    config_key: Mapped[str] = mapped_column(String(100), primary_key=True)
    config_value: Mapped[str] = mapped_column(Text, nullable=False)
    value_type: Mapped[ConfigValueType] = mapped_column(
        SAEnum(ConfigValueType, name="config_value_type_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    description: Mapped[str | None] = mapped_column(Text)
    is_sensitive: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    updated_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    action_type: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_name: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_id: Mapped[str | None] = mapped_column(String(100))
    ip_address: Mapped[str | None] = mapped_column(INET)
    details_json: Mapped[dict | None] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
