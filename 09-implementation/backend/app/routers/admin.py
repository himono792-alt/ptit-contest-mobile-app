"""Admin router — gộp 4 sub-router (users, master, configs, audit).

Endpoints:
  Users:        /api/admin/users/*  (AD-02)
  Master data:  /api/admin/faculties, /majors, /classes  (AD-03)
  Configs:      /api/admin/configs/*  (AD-04)
  Audit:        /api/admin/audit-logs, /reviews/*  (AD-06)
"""

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Body, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.models.enums import RoleCode, UserStatus
from app.schemas.admin import (
    AcademicClassIn,
    AcademicClassOut,
    AdminUserCreateIn,
    AdminUserListItem,
    AdminUserListOut,
    AdminUserUpdateIn,
    AssignRolesIn,
    AuditLogListOut,
    AuditLogOut,
    BulkImportIn,
    BulkImportOut,
    ConfigOut,
    ConfigUpdateIn,
    FacultyIn,
    FacultyOut,
    MajorIn,
    MajorOut,
)
from app.schemas.review import ReviewModerateIn, ReviewOut
from app.services import (
    admin_audit_service,
    admin_config_service,
    admin_master_service,
    admin_user_service,
)

router = APIRouter(prefix="/admin", tags=["admin"])


# ============================================================
# AD-02 USERS
# ============================================================

def _user_to_item(u) -> AdminUserListItem:
    item = AdminUserListItem.model_validate(u)
    item.roles = sorted(u.role_codes)
    return item


@router.get("/users", response_model=AdminUserListOut)
async def list_users(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    role: RoleCode | None = None,
    status_filter: UserStatus | None = Query(None, alias="status"),
    q: str | None = None,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=200),
) -> AdminUserListOut:
    rows, total = await admin_user_service.list_users(
        db, user, role=role, status_filter=status_filter, q=q,
        offset=(page - 1) * size, limit=size,
    )
    return AdminUserListOut(
        items=[_user_to_item(u) for u in rows],
        total=total, page=page, size=size,
    )


@router.post("/users", response_model=AdminUserListItem, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: AdminUserCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AdminUserListItem:
    new_user = await admin_user_service.create_user(db, user, data)
    return _user_to_item(new_user)


@router.patch("/users/{user_id}", response_model=AdminUserListItem)
async def update_user(
    user_id: int,
    data: AdminUserUpdateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AdminUserListItem:
    return _user_to_item(await admin_user_service.update_user(db, user, user_id, data))


@router.post("/users/{user_id}/lock", response_model=AdminUserListItem)
async def lock_user(
    user_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AdminUserListItem:
    return _user_to_item(await admin_user_service.lock_user(db, user, user_id))


@router.post("/users/{user_id}/unlock", response_model=AdminUserListItem)
async def unlock_user(
    user_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AdminUserListItem:
    return _user_to_item(await admin_user_service.unlock_user(db, user, user_id))


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def soft_delete_user(
    user_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await admin_user_service.soft_delete_user(db, user, user_id)


@router.patch("/users/{user_id}/roles", response_model=AdminUserListItem)
async def replace_roles(
    user_id: int,
    data: AssignRolesIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AdminUserListItem:
    return _user_to_item(
        await admin_user_service.replace_roles(db, user, user_id, data.role_codes)
    )


@router.post("/students/import", response_model=BulkImportOut)
async def import_student_directory(
    data: BulkImportIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> BulkImportOut:
    return BulkImportOut(**await admin_user_service.import_student_directory(db, user, data))


# ============================================================
# AD-03 MASTER DATA
# ============================================================

@router.get("/faculties", response_model=list[FacultyOut])
async def list_faculties(db: Annotated[AsyncSession, Depends(get_db)]) -> list[FacultyOut]:
    return [FacultyOut.model_validate(f) for f in await admin_master_service.list_faculties(db)]


@router.post("/faculties", response_model=FacultyOut, status_code=status.HTTP_201_CREATED)
async def create_faculty(
    data: FacultyIn, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> FacultyOut:
    return FacultyOut.model_validate(
        await admin_master_service.create_faculty(db, user, data.faculty_code, data.faculty_name)
    )


@router.patch("/faculties/{faculty_id}", response_model=FacultyOut)
async def update_faculty(
    faculty_id: int, data: FacultyIn,
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> FacultyOut:
    return FacultyOut.model_validate(
        await admin_master_service.update_faculty(db, user, faculty_id, data.faculty_code, data.faculty_name)
    )


@router.delete("/faculties/{faculty_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_faculty(
    faculty_id: int, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await admin_master_service.delete_faculty(db, user, faculty_id)


@router.get("/majors", response_model=list[MajorOut])
async def list_majors(
    db: Annotated[AsyncSession, Depends(get_db)],
    faculty_id: int | None = None,
) -> list[MajorOut]:
    return [MajorOut.model_validate(m) for m in await admin_master_service.list_majors(db, faculty_id)]


@router.post("/majors", response_model=MajorOut, status_code=status.HTTP_201_CREATED)
async def create_major(
    data: MajorIn, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> MajorOut:
    return MajorOut.model_validate(
        await admin_master_service.create_major(db, user, data.major_code, data.major_name, data.faculty_id)
    )


@router.patch("/majors/{major_id}", response_model=MajorOut)
async def update_major(
    major_id: int, data: MajorIn,
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> MajorOut:
    return MajorOut.model_validate(
        await admin_master_service.update_major(db, user, major_id, data.major_code, data.major_name, data.faculty_id)
    )


@router.delete("/majors/{major_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_major(
    major_id: int, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await admin_master_service.delete_major(db, user, major_id)


@router.get("/classes", response_model=list[AcademicClassOut])
async def list_classes(
    db: Annotated[AsyncSession, Depends(get_db)],
    faculty_id: int | None = None, major_id: int | None = None,
) -> list[AcademicClassOut]:
    items = await admin_master_service.list_classes(db, faculty_id, major_id)
    return [AcademicClassOut.model_validate(c) for c in items]


@router.post("/classes", response_model=AcademicClassOut, status_code=status.HTTP_201_CREATED)
async def create_class(
    data: AcademicClassIn, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> AcademicClassOut:
    return AcademicClassOut.model_validate(
        await admin_master_service.create_class(
            db, user, data.class_code, data.class_name, data.faculty_id, data.major_id
        )
    )


@router.patch("/classes/{class_id}", response_model=AcademicClassOut)
async def update_class(
    class_id: int, data: AcademicClassIn,
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> AcademicClassOut:
    return AcademicClassOut.model_validate(
        await admin_master_service.update_class(
            db, user, class_id, data.class_code, data.class_name, data.faculty_id, data.major_id
        )
    )


@router.delete("/classes/{class_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_class(
    class_id: int, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await admin_master_service.delete_class(db, user, class_id)


# ============================================================
# AD-04 SYSTEM CONFIGS
# ============================================================

@router.get("/configs", response_model=list[ConfigOut])
async def list_configs(
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ConfigOut]:
    return [ConfigOut(**c) for c in await admin_config_service.list_configs(db, user)]


@router.get("/configs/{key}", response_model=ConfigOut)
async def get_config(
    key: str, user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> ConfigOut:
    return ConfigOut(**await admin_config_service.get_config(db, user, key))


@router.patch("/configs/{key}", response_model=ConfigOut)
async def update_config(
    key: str, data: ConfigUpdateIn,
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> ConfigOut:
    return ConfigOut(**await admin_config_service.update_config(db, user, key, data.config_value))


# ============================================================
# AD-06 AUDIT LOGS + REVIEW MODERATION
# ============================================================

@router.get("/audit-logs", response_model=AuditLogListOut)
async def list_audit_logs(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    user_id: int | None = None,
    action_type: str | None = None,
    entity_name: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=500),
) -> AuditLogListOut:
    rows, total = await admin_audit_service.list_audit_logs(
        db, user,
        user_id=user_id, action_type=action_type, entity_name=entity_name,
        date_from=date_from, date_to=date_to,
        offset=(page - 1) * size, limit=size,
    )
    items = []
    for r in rows:
        # Build dict thủ công vì IPv4Address từ asyncpg INET không cast tự động
        # khi dùng model_validate(from_attributes=True) — Pydantic v2 strict.
        items.append(AuditLogOut(
            log_id=r.log_id,
            user_id=r.user_id,
            action_type=r.action_type,
            entity_name=r.entity_name,
            entity_id=r.entity_id,
            ip_address=str(r.ip_address) if r.ip_address is not None else None,
            details_json=r.details_json,
            created_at=r.created_at,
        ))
    return AuditLogListOut(items=items, total=total, page=page, size=size)


@router.get("/reviews", response_model=list[ReviewOut])
async def list_all_reviews(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    contest_id: int | None = None,
    only_hidden: bool = False,
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
) -> list[ReviewOut]:
    rows, _ = await admin_audit_service.list_all_reviews(
        db, user, contest_id, only_hidden, (page - 1) * size, size
    )
    return [ReviewOut.model_validate(r) for r in rows]


@router.patch("/reviews/{review_id}/moderate", response_model=ReviewOut)
async def moderate_review(
    review_id: int, data: ReviewModerateIn,
    user: CurrentUser, db: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewOut:
    review = await admin_audit_service.moderate_review(
        db, user, review_id, data.is_visible, data.moderation_note
    )
    return ReviewOut.model_validate(review)
