"""Password hashing + JWT helpers."""

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt

from app.config import settings

_BCRYPT_ROUNDS = 12
_BCRYPT_MAX_BYTES = 72


# ---------- Password ----------

def _to_bytes(plain: str) -> bytes:
    return plain.encode("utf-8")[:_BCRYPT_MAX_BYTES]


def hash_password(plain: str) -> str:
    salt = bcrypt.gensalt(rounds=_BCRYPT_ROUNDS)
    return bcrypt.hashpw(_to_bytes(plain), salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(_to_bytes(plain), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False


# ---------- JWT ----------

def create_access_token(
    subject: str | int,
    extra: dict[str, Any] | None = None,
    expires_delta: timedelta | None = None,
) -> str:
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes))
    payload: dict[str, Any] = {
        "sub": str(subject),
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def create_refresh_token(
    subject: str | int,
    extra: dict[str, Any] | None = None,
    expires_delta: timedelta | None = None,
) -> str:
    # Phase 1 step 3: stateless JWT refresh token
    # claim type=refresh de phan biet voi access token
    # Flutter: luu trong flutter_secure_storage, goi POST /auth/refresh khi can
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(days=settings.jwt_refresh_token_expire_days))
    payload: dict[str, Any] = {
        "sub": str(subject),
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
        "type": "refresh",
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict[str, Any]:
    return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])


def decode_refresh_token(token: str) -> dict[str, Any]:
    payload = decode_token(token)
    if payload.get("type") != "refresh":
        raise JWTError("Token khong phai refresh token")
    return payload


__all__ = [
    "hash_password", "verify_password",
    "create_access_token", "create_refresh_token",
    "decode_token", "decode_refresh_token",
    "JWTError",
]
