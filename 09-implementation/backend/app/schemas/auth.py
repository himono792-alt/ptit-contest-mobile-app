"""Pydantic v2 schemas cho auth endpoints (SV-01, GV-01, BCN-01, AD-01)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ---------- Input ----------

class RegisterIn(BaseModel):
    """SV-01c: Sinh viên đăng ký tài khoản (chỉ STUDENT, các role khác do Admin tạo)."""

    student_code: str = Field(..., min_length=3, max_length=30, description="MSSV PTIT")
    email: EmailStr = Field(..., description="Phải là @ptit.edu.vn")
    full_name: str = Field(..., min_length=2, max_length=150)
    password: str = Field(..., min_length=6, max_length=128)


class LoginIn(BaseModel):
    """SV-01a / GV-01 / BCN-01 / AD-01: login bằng email + password."""

    email: EmailStr
    password: str


# ---------- Output ----------

class TokenOut(BaseModel):
    """JWT trả về sau khi login."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Seconds until expiry")


class RoleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    role_code: str
    role_name: str


class MeOut(BaseModel):
    """SV-02 / GV-01 / BCN-01 GET /api/me — info user hiện tại + roles."""

    model_config = ConfigDict(from_attributes=True)

    user_id: int
    email: str
    full_name: str
    phone: str | None = None
    avatar_url: str | None = None
    status: str
    roles: list[str] = Field(default_factory=list, description="role_code list, vd: ['STUDENT']")
    last_login_at: datetime | None = None
    created_at: datetime
