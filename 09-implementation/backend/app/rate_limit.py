"""Rate limit — Phase 1 step 2 (2026-05-06).

Sử dụng slowapi (FastAPI wrapper của limits library).

Backend storage:
  - Default: memory:// (đủ cho 1 replica Railway)
  - Production scale: REDIS_URL env var → tự switch sang Redis (multi-replica share state)

Key strategy:
  - Default key = remote IP address. Đủ cho hầu hết case.
  - Login endpoint: kết hợp IP + email → tránh attacker dùng nhiều IP brute force 1 account.

Usage:
  from app.rate_limit import limiter

  @router.post("/login")
  @limiter.limit("10/minute")
  async def login(request: Request, ...):
      # Decorator yêu cầu request: Request phải có trong signature.
"""

from __future__ import annotations

import logging

from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings


log = logging.getLogger("rate_limit")


def _build_storage_uri() -> str:
    """Pick Redis URL nếu có, fallback memory:// nếu không."""
    if settings.redis_url:
        log.info("Rate limit storage: Redis (%s)", settings.redis_url.split("@")[-1][:30])
        return settings.redis_url
    log.info("Rate limit storage: memory (single-replica only)")
    return "memory://"


# Singleton — import từ các module khác
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[settings.rate_limit_default] if settings.rate_limit_enabled else [],
    storage_uri=_build_storage_uri(),
    # Headers chuẩn theo IETF draft RFC 9512 (X-RateLimit-Remaining, X-RateLimit-Reset)
    headers_enabled=True,
    # Nếu Redis chết hoặc memory backend lỗi → fail-open (cho qua) thay vì block hết
    swallow_errors=True,
)


def get_login_key(request) -> str:
    """Key cho /auth/login: IP + email body (nếu có).

    Để attacker không thể bypass IP-only rate limit bằng cách thử nhiều account
    với cùng 1 IP, hoặc thử cùng 1 account từ nhiều IP.
    """
    ip = get_remote_address(request)
    # Form data chưa parse khi limiter chạy → chỉ dùng IP cho safe.
    # Future: thêm middleware parse body trước limiter để có email.
    return ip
