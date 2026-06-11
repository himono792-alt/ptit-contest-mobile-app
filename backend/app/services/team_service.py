"""Team management business logic (SV-06 phụ flow)."""

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.contest import Contest
from app.models.entry import Team, TeamMember
from app.models.enums import EntryType
from app.models.identity import AppUser
from app.models.master_data import Student, StudentDirectory


async def _get_student_or_403(db: AsyncSession, user: AppUser) -> Student:
    stmt = select(Student).where(Student.user_id == user.user_id)
    student = (await db.execute(stmt)).scalar_one_or_none()
    if student is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User không phải sinh viên")
    return student


async def create_team(
    db: AsyncSession, user: AppUser, contest_id: int, team_name: str
) -> Team:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if contest.participation_mode != EntryType.TEAM:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Contest này cá nhân, không cần team")

    student = await _get_student_or_403(db, user)

    team = Team(
        contest_id=contest_id,
        team_name=team_name,
        leader_student_id=student.student_id,
    )
    db.add(team)
    await db.flush()  # cần team_id

    # Auto add leader vào team_members
    db.add(TeamMember(
        team_id=team.team_id,
        student_id=student.student_id,
        is_leader=True,
    ))

    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Team name '{team_name}' đã tồn tại trong contest",
        ) from e

    # Reload với members
    stmt = (
        select(Team)
        .where(Team.team_id == team.team_id)
        .options(selectinload(Team.members))
    )
    return (await db.execute(stmt)).scalar_one()


async def add_member(
    db: AsyncSession, user: AppUser, team_id: int, student_code: str
) -> TeamMember:
    team = await db.get(Team, team_id)
    if team is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Team not found")

    leader = await _get_student_or_403(db, user)
    if team.leader_student_id != leader.student_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ leader mới thêm member")

    # Lookup student by MSSV (qua student_directory)
    stmt = (
        select(Student)
        .join(StudentDirectory, StudentDirectory.directory_id == Student.directory_id)
        .where(StudentDirectory.student_code == student_code)
    )
    member_student = (await db.execute(stmt)).scalar_one_or_none()
    if member_student is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            f"Không tìm thấy SV với MSSV '{student_code}' (chưa đăng ký tài khoản hoặc sai MSSV)",
        )

    member = TeamMember(
        team_id=team_id,
        student_id=member_student.student_id,
        is_leader=False,
    )
    db.add(member)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Member đã có trong team",
        ) from e
    await db.refresh(member)
    return member


async def get_team(db: AsyncSession, team_id: int) -> Team:
    stmt = (
        select(Team)
        .where(Team.team_id == team_id)
        .options(selectinload(Team.members))
    )
    team = (await db.execute(stmt)).scalar_one_or_none()
    if team is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Team not found")
    return team


async def list_my_teams(db: AsyncSession, user: AppUser) -> list[Team]:
    """SV-06 — List tất cả team mà SV đang là leader hoặc member."""
    student = await _get_student_or_403(db, user)
    stmt = (
        select(Team)
        .join(TeamMember, TeamMember.team_id == Team.team_id)
        .where(TeamMember.student_id == student.student_id)
        .options(selectinload(Team.members))
        .order_by(Team.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())
