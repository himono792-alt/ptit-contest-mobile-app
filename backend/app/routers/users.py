"""User profile router (SV-02 quản lý profile, SV-03 xóa tài khoản).

Endpoints:
  PATCH /api/me                    — update profile
  PATCH /api/me/password           — đổi mật khẩu
  DELETE /api/me                   — soft delete (status=DELETED)
  POST /api/auth/forgot-password   — request reset token
  POST /api/auth/reset-password    — submit token + password mới
"""

from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.deps import CurrentUser
from app.models.identity import AppUser
from app.routers.auth import _to_me_out
from app.schemas.auth import MeOut
from app.schemas.user import (
    ChangePasswordIn,
    ForgotPasswordIn,
    ResetPasswordIn,
    UpdateMeIn,
)
from app.services import email_service, user_service

# 2 router: 1 cho /me (cần auth), 1 cho /auth (forgot/reset password — không auth)
me_router = APIRouter(prefix="/me", tags=["users"])
auth_router = APIRouter(prefix="/auth", tags=["auth"])


# ---------- /me endpoints ----------

@me_router.patch("", response_model=MeOut)
async def update_me(
    data: UpdateMeIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MeOut:
    """SV-02 — Cập nhật full_name, phone, avatar_url, bio (nếu là SV)."""
    updated = await user_service.update_me(db, user, data)
    reloaded = await user_service.reload_user_with_roles(db, updated.user_id)
    return _to_me_out(reloaded)


@me_router.patch("/password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    data: ChangePasswordIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """SV-02 — Đổi mật khẩu."""
    await user_service.change_password(db, user, data)


@me_router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """SV-03 — Soft delete tài khoản (set status=DELETED)."""
    await user_service.soft_delete_me(db, user)


# ---------- /auth password reset ----------

@auth_router.post("/forgot-password")
async def forgot_password(
    data: ForgotPasswordIn,
    bg: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """SV-02 — Request reset link qua email.

    Phase 1 step 4 (2026-05-06): refactor gửi email production.
    - Token tạo + log Sentry kèm email gửi BackgroundTask (không block response).
    - Luôn trả 200 dù email tồn tại hay không (chống enumeration attack).
    - Dev mode (APP_ENV=development) vẫn expose dev_reset_token cho dễ test.
    """
    token = await user_service.request_password_reset(db, data.email)
    response: dict = {"message": "Nếu email tồn tại, link reset đã được gửi."}

    if token is not None:
        # Lookup user lại để lấy full_name cho template (request_password_reset đã verify exists)
        stmt = select(AppUser).where(AppUser.email == data.email)
        user = (await db.execute(stmt)).scalar_one_or_none()
        if user is not None:
            # Fire-and-forget — KHÔNG await, không block response
            bg.add_task(
                email_service.send_password_reset,
                to_email=str(user.email),
                full_name=user.full_name,
                reset_token=token,
            )

        if settings.app_env == "development":
            # Dev mode only: expose token để dễ test (production không leak)
            response["dev_reset_token"] = token

    return response


@auth_router.post("/reset-password", status_code=status.HTTP_204_NO_CONTENT)
async def reset_password(
    data: ResetPasswordIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """SV-02 — Verify token + đổi mật khẩu."""
    await user_service.reset_password_with_token(db, data.reset_token, data.new_password)
