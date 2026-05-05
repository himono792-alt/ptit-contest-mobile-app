"""Auth endpoints: register, login, me (matrix: SV-01, GV-01, BCN-01, AD-01)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.deps import CurrentUser
from app.rate_limit import limiter
from app.schemas.auth import LoginIn, MeOut, RegisterIn, TokenOut
from app.security import create_access_token
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=MeOut, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(
    request: Request,
    data: RegisterIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MeOut:
    """SV-01c — Sinh viên tự đăng ký (matched với student_directory).

    Các role khác (ORGANIZER/JUDGE/HOD/ADMIN) chỉ Admin tạo qua AD-02.

    Rate limit (Phase 1.2): 5 req/phút per IP — chống spam tạo account.
    """
    user = await auth_service.register_student(db, data)
    return _to_me_out(user)


@router.post("/login", response_model=TokenOut)
@limiter.limit("10/minute")
async def login(
    request: Request,
    data: LoginIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenOut:
    """Endpoint login chung cho mọi role. Trả JWT bearer token.

    Rate limit (Phase 1.2): 10 req/phút per IP — chống brute force password.
    Sau 10 lần sai, attacker phải đợi 1 phút → giảm tốc độ brute force ~6000x.
    """
    user = await auth_service.authenticate(db, data)
    role_codes = sorted(user.role_codes)
    token = create_access_token(
        subject=user.user_id,
        extra={"email": user.email, "roles": role_codes},
    )
    return TokenOut(
        access_token=token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(_user: CurrentUser) -> None:
    """JWT là stateless nên logout chỉ cần FE xóa token. Backend log vào audit_logs."""
    # TODO (team): insert audit_log row khi implement audit middleware
    return None


@router.get("/me", response_model=MeOut)
async def get_me(user: CurrentUser) -> MeOut:
    """Trả về thông tin user đang login (SV-02, GV-01, BCN-01)."""
    return _to_me_out(user)


# ---------- Helpers ----------

def _to_me_out(user) -> MeOut:
    return MeOut(
        user_id=user.user_id,
        email=str(user.email),
        full_name=user.full_name,
        phone=user.phone,
        avatar_url=user.avatar_url,
        status=user.status.value if hasattr(user.status, "value") else str(user.status),
        roles=sorted(user.role_codes),
        last_login_at=user.last_login_at,
        created_at=user.created_at,
        # Profile mở rộng (đọc trực tiếp từ AppUser model)
        dob=getattr(user, "dob", None),
        gender=getattr(user, "gender", None),
        citizen_id=getattr(user, "citizen_id", None),
        place_of_birth=getattr(user, "place_of_birth", None),
        address=getattr(user, "address", None),
        ethnicity=getattr(user, "ethnicity", None),
        religion=getattr(user, "religion", None),
        nationality=getattr(user, "nationality", None),
        secondary_email=getattr(user, "secondary_email", None),
    )
