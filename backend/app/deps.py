"""Common FastAPI dependencies: auth (current_user), RBAC, pagination."""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.identity import AppUser, UserRole
from app.security import decode_token

# OAuth2 scheme — token URL trỏ tới endpoint login (form-data password flow)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


# ---------- Auth ----------

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppUser:
    """Decode JWT → load AppUser từ DB (with roles eager-loaded).

    Raises 401 nếu token invalid hoặc user không tồn tại / bị khóa.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        user_id_str: str | None = payload.get("sub")
        if not user_id_str:
            raise credentials_exception
        user_id = int(user_id_str)
    except (JWTError, ValueError) as e:
        raise credentials_exception from e

    stmt = (
        select(AppUser)
        .where(AppUser.user_id == user_id)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    if user.status != "ACTIVE":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"User is {user.status}")
    return user


CurrentUser = Annotated[AppUser, Depends(get_current_user)]


# ---------- RBAC ----------

def require_roles(*allowed_roles: str):
    """Dependency factory: check user có ≥1 role trong allowed_roles.

    Usage:
        @router.post("/contests", dependencies=[Depends(require_roles("ORGANIZER", "ADMIN"))])
        async def create_contest(...): ...

    Hoặc inject để dùng user inside:
        @router.post("/contests")
        async def create_contest(user: CurrentUser = Depends(require_roles("ORGANIZER"))):
            ...
    """
    async def _check(user: CurrentUser) -> AppUser:
        user_role_codes = {ur.role.role_code for ur in user.user_roles}
        if not user_role_codes.intersection(allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires one of roles: {', '.join(allowed_roles)}",
            )
        return user

    return _check


# ---------- Common pagination ----------

class Pagination:
    """Query params cho pagination: ?page=1&size=20"""

    def __init__(self, page: int = 1, size: int = 20):
        if page < 1:
            page = 1
        if size < 1 or size > 200:
            size = 20
        self.page = page
        self.size = size
        self.offset = (page - 1) * size
        self.limit = size
