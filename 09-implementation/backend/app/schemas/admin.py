"""Admin schemas (AD-02 users, AD-03 master, AD-04 configs, AD-06 audit)."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.enums import ConfigValueType, RoleCode, UserStatus


# ============================================================
# AD-02 USERS
# ============================================================

class AdminUserListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: int
    email: str
    full_name: str
    phone: str | None = None
    status: UserStatus
    last_login_at: datetime | None = None
    created_at: datetime
    roles: list[str] = Field(default_factory=list)


class AdminUserListOut(BaseModel):
    items: list[AdminUserListItem]
    total: int
    page: int
    size: int


class AdminUserCreateIn(BaseModel):
    """Tạo user (Admin only). role_codes chọn 1+ trong list.

    Profile fields theo role:
      - STUDENT: cần directory_id (link tới student_directory)
      - ORGANIZER: optional faculty_id, organization_name
      - JUDGE: optional expertise
      - HOD: cần faculty_id + title (Trưởng/Phó)
      - ADMIN: không cần profile
    """

    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2, max_length=150)
    phone: str | None = None
    role_codes: list[RoleCode] = Field(..., min_length=1)

    # Profile (optional, dùng theo role)
    directory_id: int | None = None
    organization_name: str | None = None
    faculty_id: int | None = None
    expertise: str | None = None
    title: str | None = None
    is_primary_approver: bool = False


class AdminUserUpdateIn(BaseModel):
    """PATCH user — partial update."""

    full_name: str | None = Field(None, min_length=2, max_length=150)
    phone: str | None = None
    avatar_url: str | None = None
    status: UserStatus | None = None


class AssignRolesIn(BaseModel):
    role_codes: list[RoleCode] = Field(..., description="Replace toàn bộ role hiện tại")


class StudentDirectoryImportRow(BaseModel):
    student_code: str = Field(..., max_length=30)
    ptit_email: EmailStr
    full_name: str = Field(..., max_length=150)
    faculty_code: str | None = None
    major_code: str | None = None
    class_code: str | None = None


class BulkImportIn(BaseModel):
    rows: list[StudentDirectoryImportRow]


class BulkImportOut(BaseModel):
    inserted: int
    skipped: int
    errors: list[str] = []


# ============================================================
# AD-03 MASTER DATA
# ============================================================

class FacultyIn(BaseModel):
    faculty_code: str = Field(..., min_length=2, max_length=30)
    faculty_name: str = Field(..., min_length=2, max_length=150)


class FacultyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    faculty_id: int
    faculty_code: str
    faculty_name: str


class MajorIn(BaseModel):
    major_code: str = Field(..., max_length=30)
    major_name: str = Field(..., max_length=150)
    faculty_id: int | None = None


class MajorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    major_id: int
    major_code: str
    major_name: str
    faculty_id: int | None = None
    created_at: datetime


class AcademicClassIn(BaseModel):
    class_code: str = Field(..., max_length=30)
    class_name: str = Field(..., max_length=150)
    faculty_id: int | None = None
    major_id: int | None = None


class AcademicClassOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    class_id: int
    class_code: str
    class_name: str
    faculty_id: int | None = None
    major_id: int | None = None


# ============================================================
# AD-04 SYSTEM CONFIGS
# ============================================================

class ConfigOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    config_key: str
    config_value: str  # masked nếu is_sensitive
    value_type: ConfigValueType
    description: str | None = None
    is_sensitive: bool
    updated_by: int | None = None
    updated_at: datetime


class ConfigUpdateIn(BaseModel):
    config_value: str = Field(..., description="Phải parse được theo value_type hiện tại")


# ============================================================
# AD-06 AUDIT LOGS
# ============================================================

class AuditLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    log_id: int
    user_id: int | None = None
    action_type: str
    entity_name: str
    entity_id: str | None = None
    ip_address: str | None = None
    details_json: dict[str, Any] | None = None
    created_at: datetime


class AuditLogListOut(BaseModel):
    items: list[AuditLogOut]
    total: int
    page: int
    size: int
