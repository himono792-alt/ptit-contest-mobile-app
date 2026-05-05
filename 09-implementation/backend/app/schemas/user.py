"""Pydantic schemas cho user management (SV-02, SV-03)."""

from pydantic import BaseModel, EmailStr, Field


class UpdateMeIn(BaseModel):
    """SV-02 PATCH /api/me — update các field tự sửa được."""

    full_name: str | None = Field(None, min_length=2, max_length=150)
    phone: str | None = Field(None, max_length=20)
    avatar_url: str | None = None
    bio: str | None = Field(None, description="Chỉ student có bio")


class ChangePasswordIn(BaseModel):
    """SV-02 PATCH /api/me/password."""

    current_password: str
    new_password: str = Field(..., min_length=6, max_length=128)


class ForgotPasswordIn(BaseModel):
    """SV-02 POST /api/auth/forgot-password — chỉ cần email."""

    email: EmailStr


class ResetPasswordIn(BaseModel):
    """SV-02 POST /api/auth/reset-password (sau khi nhận token qua email)."""

    reset_token: str
    new_password: str = Field(..., min_length=6, max_length=128)
