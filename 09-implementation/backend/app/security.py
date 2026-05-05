"""Password hashing + JWT helpers.

Note:
- bcrypt trực tiếp (không qua passlib — passlib unmaintained và crash với bcrypt 4.x).
- python-jose cho JWT HS256 (đối xứng, đơn giản — đủ cho 1 service).
- bcrypt có giới hạn 72 bytes input. Truncate explicit để consistent giữa hash + verify.
"""

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt

from app.config import settings

# bcrypt cost factor (12 = ~250ms hash trên CPU 2024, đủ chậm để chống brute force)
_BCRYPT_ROUNDS = 12
_BCRYPT_MAX_BYTES = 72  # bcrypt hard limit


# ---------- Password ----------

def _to_bytes(plain: str) -> bytes:
    """Encode UTF-8 + truncate về <=72 bytes (giới hạn bcrypt)."""
    return plain.encode("utf-8")[:_BCRYPT_MAX_BYTES]


def hash_password(plain: str) -> str:
    """Hash password bằng bcrypt. Returns string format $2b$12$..."""
    salt = bcrypt.gensalt(rounds=_BCRYPT_ROUNDS)
    return bcrypt.hashpw(_to_bytes(plain), salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Verify password vs stored hash. Constant-time comparison."""
    try:
        return bcrypt.checkpw(_to_bytes(plain), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        # Hash format invalid → coi như sai password
        return False


# ---------- JWT ----------

def create_access_token(
    subject: str | int,
    extra: dict[str, Any] | None = None,
    expires_delta: timedelta | None = None,
) -> str:
    """Tạo JWT access token.

    Args:
        subject: user_id (số) hoặc email (str). Sẽ là claim 'sub'.
        extra: thêm claim tùy ý (vd: roles, faculty_id) — KHÔNG bỏ password vào.
        expires_delta: override default expire time.
    """
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


def decode_token(token: str) -> dict[str, Any]:
    """Decode + validate JWT. Raises JWTError nếu invalid/expired."""
    return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])


__all__ = ["hash_password", "verify_password", "create_access_token", "decode_token", "JWTError"]
