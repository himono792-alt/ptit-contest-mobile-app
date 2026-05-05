"""Team router (SV-06 phụ flow đăng ký team)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.team import TeamCreateIn, TeamMemberAddIn, TeamMemberOut, TeamOut
from app.services import team_service

contest_teams_router = APIRouter(prefix="/contests", tags=["teams"])
teams_router = APIRouter(prefix="/teams", tags=["teams"])
me_teams_router = APIRouter(prefix="/me", tags=["teams"])


@me_teams_router.get("/teams", response_model=list[TeamOut])
async def list_my_teams(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[TeamOut]:
    """SV — List tất cả team mà SV đang là leader hoặc member (kèm members)."""
    teams = await team_service.list_my_teams(db, user)
    return [TeamOut.model_validate(t) for t in teams]


@contest_teams_router.post(
    "/{contest_id}/teams",
    response_model=TeamOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_team(
    contest_id: int,
    data: TeamCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TeamOut:
    """SV-06 — Tạo team. SV gọi sẽ tự động là leader + member đầu tiên."""
    team = await team_service.create_team(db, user, contest_id, data.team_name)
    return TeamOut.model_validate(team)


@teams_router.get("/{team_id}", response_model=TeamOut)
async def get_team(
    team_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TeamOut:
    team = await team_service.get_team(db, team_id)
    return TeamOut.model_validate(team)


@teams_router.post(
    "/{team_id}/members",
    response_model=TeamMemberOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_team_member(
    team_id: int,
    data: TeamMemberAddIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TeamMemberOut:
    """SV-06 — Leader thêm member vào team (theo MSSV)."""
    member = await team_service.add_member(db, user, team_id, data.student_code)
    return TeamMemberOut.model_validate(member)
