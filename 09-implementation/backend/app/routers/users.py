"""User profile router (SV-02 quản lý profile, SV-03 xóa tài khoản).

Endpoints:
  PATCH /api/me                    — update profile
  PATCH /api/me/password           — đổi mật khẩu
  DELETE /api/me                   — soft delete (status=DELETED)
  POST /api/auth/forgot-password   — request reset token
  POST /api/auth/reset-password    — submit token + password mới
"""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.deps import CurrentUser
from app.routers.auth import _to_me_out
from app.schemas.auth import MeOut
from app.schemas.user import (
    ChangePasswordIn,
    ForgotPasswordIn,
    ResetPasswordIn,
    UpdateMeIn,
)
from app.services import user_service

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
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """SV-02 — Request reset token. Stub dev mode: trả token trong response.

    Production: gửi link qua email + chỉ trả 202 Accepted.
    Luôn trả 200 dù email tồn tại hay không (chống enumerate).
    """
    token = await user_service.request_password_reset(db, data.email)
    response: dict = {"message": "Nếu email tồn tại, link reset đã được gửi."}
    if settings.app_env == "development" and token is not None:
        # Dev mode only: expose token để dễ test
        response["dev_reset_token"] = token
    return response


@auth_router.post("/reset-password", status_code=status.HTTP_204_NO_CONTENT)
async def reset_password(
    data: ResetPasswordIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """SV-02 — Verify token + đổi mật khẩu."""
    await user_service.reset_password_with_token(db, data.reset_token, data.new_password)
