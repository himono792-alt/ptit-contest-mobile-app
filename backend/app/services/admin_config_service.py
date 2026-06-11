"""System config CRUD (AD-04)."""

import json
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import ConfigValueType
from app.models.identity import AppUser
from app.models.system import SystemConfig

_MASKED = "********"


def _ensure_admin(user: AppUser) -> None:
    if "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ADMIN")


def _mask_if_sensitive(cfg: SystemConfig, dump_value: bool = True) -> dict:
    """Return dict for output, masking sensitive value."""
    return {
        "config_key": cfg.config_key,
        "config_value": _MASKED if cfg.is_sensitive else cfg.config_value,
        "value_type": cfg.value_type,
        "description": cfg.description,
        "is_sensitive": cfg.is_sensitive,
        "updated_by": cfg.updated_by,
        "updated_at": cfg.updated_at,
    }


def _validate_value_type(value: str, vtype: ConfigValueType) -> None:
    """Raise 400 nếu value không parse được theo vtype."""
    try:
        if vtype == ConfigValueType.INT:
            int(value)
        elif vtype == ConfigValueType.BOOL:
            if value.lower() not in ("true", "false", "1", "0"):
                raise ValueError(f"BOOL phải là true/false, got '{value}'")
        elif vtype == ConfigValueType.JSON:
            json.loads(value)
        # STRING không cần validate
    except ValueError as e:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Value '{value}' không hợp lệ cho type {vtype.value}: {e}",
        ) from e


async def list_configs(db: AsyncSession, user: AppUser) -> list[dict]:
    _ensure_admin(user)
    stmt = select(SystemConfig).order_by(SystemConfig.config_key)
    return [_mask_if_sensitive(c) for c in (await db.execute(stmt)).scalars().all()]


async def get_config(db: AsyncSession, user: AppUser, key: str) -> dict:
    _ensure_admin(user)
    cfg = await db.get(SystemConfig, key)
    if cfg is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"Config '{key}' not found")
    return _mask_if_sensitive(cfg)


async def update_config(
    db: AsyncSession, user: AppUser, key: str, value: str
) -> dict:
    _ensure_admin(user)
    cfg = await db.get(SystemConfig, key)
    if cfg is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"Config '{key}' not found")

    _validate_value_type(value, cfg.value_type)

    cfg.config_value = value
    cfg.updated_by = user.user_id
    cfg.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(cfg)
    return _mask_if_sensitive(cfg)
