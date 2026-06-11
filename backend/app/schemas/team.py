"""Pydantic schemas cho team management (SV-06 phụ flow đăng ký team)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class TeamCreateIn(BaseModel):
    """SV-06 POST /api/contests/{id}/teams — tạo team (SV gọi sẽ là leader)."""

    team_name: str = Field(..., min_length=2, max_length=150)


class TeamMemberAddIn(BaseModel):
    """SV-06 POST /api/teams/{id}/members — thêm member."""

    student_code: str = Field(..., description="MSSV của member muốn thêm")


class TeamMemberOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    student_id: int
    is_leader: bool
    joined_at: datetime


class TeamOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    team_id: int
    contest_id: int
    team_name: str
    leader_student_id: int
    status: str
    created_at: datetime
    members: list[TeamMemberOut] = []
