"""Pydantic v2 schemas cho auth endpoints (SV-01, GV-01, BCN-01, AD-01)."""

from datetime import date, datetime

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
    """JWT trả về sau khi login — gồm access token + refresh token.

    Phase 1 step 3: refresh token stateless JWT TTL 7 ngày.
    Flutter biometric login: lưu refresh_token trong flutter_secure_storage,
    khi biometric unlock thì POST /api/auth/refresh để lấy access token mới.
    """

    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Seconds cho đến khi access token hết hạn")
    refresh_token: str = Field(..., description="Dùng để lấy access token mới (POST /auth/refresh)")
    refresh_expires_in: int = Field(..., description="Seconds cho đến khi refresh token hết hạn")


class RefreshIn(BaseModel):
    """Body cho POST /auth/refresh."""

    refresh_token: str


# ---------- OTP login (Phase 1 step 4 — 2026-05-06) ----------

class OTPRequestIn(BaseModel):
    """Body cho POST /auth/otp/request — bước 1: nhập email, hệ thống gửi OTP qua email."""

    email: EmailStr


class OTPVerifyIn(BaseModel):
    """Body cho POST /auth/otp/verify — bước 2: nhập OTP, trả access+refresh token nếu đúng."""

    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class RoleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    role_code: str
    role_name: str


class MeOut(BaseModel):
    """SV-02 / GV-01 / BCN-01 GET /api/me — info user hiện tại + roles.

    Mở rộng 2026-05-05: trả thêm DOB, gender, address, citizen_id, ethnicity,
    religion, nationality, place_of_birth, secondary_email.
    """

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
    # Profile mở rộng
    dob: date | None = None
    gender: str | None = None
    citizen_id: str | None = None
    place_of_birth: str | None = None
    address: str | None = None
    ethnicity: str | None = None
    religion: str | None = None
    nationality: str | None = None
    secondary_email: str | None = None
