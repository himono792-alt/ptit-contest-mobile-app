"""Pydantic schemas cho user management (SV-02, SV-03)."""

from datetime import date

from pydantic import BaseModel, EmailStr, Field


class UpdateMeIn(BaseModel):
    """SV-02 PATCH /api/me — update các field tự sửa được.

    Mở rộng 2026-05-05: thêm DOB, gender, address, citizen_id, ethnicity,
    religion, nationality, place_of_birth, secondary_email theo mẫu PTIT.
    """

    full_name: str | None = Field(None, min_length=2, max_length=150)
    phone: str | None = Field(None, max_length=20)
    avatar_url: str | None = None
    bio: str | None = Field(None, description="Chỉ student có bio")
    # Profile mở rộng
    dob: date | None = None
    gender: str | None = Field(None, max_length=10, description="Nam / Nữ / Khác")
    citizen_id: str | None = Field(None, max_length=20, description="Số CMND/CCCD")
    place_of_birth: str | None = Field(None, max_length=150)
    address: str | None = Field(None, max_length=500)
    ethnicity: str | None = Field(None, max_length=50)
    religion: str | None = Field(None, max_length=50)
    nationality: str | None = Field(None, max_length=50)
    secondary_email: EmailStr | None = None


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
