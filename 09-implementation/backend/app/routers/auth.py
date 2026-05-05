"""Auth endpoints: register, login, refresh, me."""

from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, Response, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import settings
from app.database import get_db
from app.deps import CurrentUser
from app.models.identity import AppUser, UserRole
from app.rate_limit import limiter
from app.schemas.auth import (
    LoginIn,
    MeOut,
    OTPRequestIn,
    OTPVerifyIn,
    RefreshIn,
    RegisterIn,
    TokenOut,
)
from app.security import create_access_token, create_refresh_token, decode_refresh_token
from app.services import auth_service, email_service, otp_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=MeOut, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(
    request: Request,
    response: Response,
    data: RegisterIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MeOut:
    # SV-01c: sinh vien tu dang ky, rate limit 5/phut chong spam
    user = await auth_service.register_student(db, data)
    return _to_me_out(user)


@router.post("/login", response_model=TokenOut)
@limiter.limit("10/minute")
async def login(
    request: Request,
    response: Response,
    data: LoginIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenOut:
    # Rate limit 10/phut chong brute force password
    user = await auth_service.authenticate(db, data)
    role_codes = sorted(user.role_codes)
    access_token = create_access_token(
        subject=user.user_id,
        extra={"email": str(user.email), "roles": role_codes},
    )
    refresh_token = create_refresh_token(subject=user.user_id)
    return TokenOut(
        access_token=access_token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
        refresh_token=refresh_token,
        refresh_expires_in=settings.jwt_refresh_token_expire_days * 86400,
    )


@router.post("/refresh", response_model=TokenOut)
@limiter.limit("20/minute")
async def refresh(
    request: Request,
    response: Response,
    data: RefreshIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenOut:
    # Phase 1 step 3: doi refresh token lay access token moi (sliding window).
    # Flutter biometric: luu refresh_token trong flutter_secure_storage,
    # khi biometric unlock thi goi endpoint nay thay vi nhap lai password.
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Refresh token khong hop le hoac da het han",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_refresh_token(data.refresh_token)
        user_id_str: str | None = payload.get("sub")
        if not user_id_str:
            raise credentials_exception
        user_id = int(user_id_str)
    except (JWTError, ValueError):
        raise credentials_exception

    stmt = (
        select(AppUser)
        .where(AppUser.user_id == user_id)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    user = (await db.execute(stmt)).scalar_one_or_none()
    if user is None or user.status != "ACTIVE":
        raise credentials_exception

    role_codes = sorted(user.role_codes)
    new_access = create_access_token(
        subject=user.user_id,
        extra={"email": str(user.email), "roles": role_codes},
    )
    # Rotate: cap refresh token moi (sliding window)
    new_refresh = create_refresh_token(subject=user.user_id)
    return TokenOut(
        access_token=new_access,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
        refresh_token=new_refresh,
        refresh_expires_in=settings.jwt_refresh_token_expire_days * 86400,
    )


@router.post("/otp/request", status_code=status.HTTP_200_OK)
@limiter.limit("3/minute")
async def request_otp(
    request: Request,
    response: Response,
    data: OTPRequestIn,
    bg: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Phase 1 step 4 (2026-05-06): OTP login alternative.

    Bước 1: User nhập email -> backend sinh OTP 6 số -> gửi email -> trả 200.
    Rate limit 3/phút/email để chống spam OTP.

    Luôn trả 200 dù email tồn tại hay không (chống enumeration). Chỉ user thật
    sự có email mới nhận được OTP.
    """
    stmt = select(AppUser).where(AppUser.email == data.email)
    user = (await db.execute(stmt)).scalar_one_or_none()
    if user is not None and user.status == "ACTIVE":
        otp_code = otp_service.generate_otp(data.email)
        bg.add_task(
            email_service.send_otp,
            to_email=str(user.email),
            full_name=user.full_name,
            otp_code=otp_code,
        )
    return {"message": "Nếu email tồn tại, mã OTP đã được gửi (TTL 5 phút)."}


@router.post("/otp/verify", response_model=TokenOut)
@limiter.limit("10/minute")
async def verify_otp(
    request: Request,
    response: Response,
    data: OTPVerifyIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenOut:
    """Phase 1 step 4: bước 2 OTP login — verify OTP + cấp JWT (giống /login).

    Sai 5 lần -> lock 30p (server-side trong otp_service).
    Rate limit endpoint 10/phút (defense-in-depth chống brute force phía network).
    """
    if not otp_service.verify_otp(data.email, data.otp_code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Mã OTP không hợp lệ, đã hết hạn, hoặc tài khoản bị khóa tạm thời.",
        )

    stmt = (
        select(AppUser)
        .where(AppUser.email == data.email)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    user = (await db.execute(stmt)).scalar_one_or_none()
    if user is None or user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tài khoản không tồn tại hoặc đã bị khóa.",
        )

    role_codes = sorted(user.role_codes)
    access_token = create_access_token(
        subject=user.user_id,
        extra={"email": str(user.email), "roles": role_codes},
    )
    refresh_token = create_refresh_token(subject=user.user_id)
    return TokenOut(
        access_token=access_token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
        refresh_token=refresh_token,
        refresh_expires_in=settings.jwt_refresh_token_expire_days * 86400,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(_user: CurrentUser) -> None:
    return None


@router.get("/me", response_model=MeOut)
async def get_me(user: CurrentUser) -> MeOut:
    return _to_me_out(user)


# ---------- Helper ----------

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
