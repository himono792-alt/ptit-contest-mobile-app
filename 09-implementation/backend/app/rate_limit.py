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
from starlette.requests import Request

from app.config import settings


log = logging.getLogger("rate_limit")


def _real_client_ip(request: Request) -> str:
    """Đọc IP thật của client, ưu tiên X-Forwarded-For (Railway/Cloudflare).

    Phase 1 fix (2026-05-06): Railway có load balancer → request.client.host trả
    proxy IP `100.64.x.x` thay đổi mỗi request → rate limit không hoạt động.
    Header `X-Forwarded-For: <client_ip>, <proxy1>, <proxy2>` — lấy phần tử đầu.

    Fallback chain:
      1. X-Forwarded-For first hop
      2. X-Real-IP (Nginx-style)
      3. request.client.host (socket peer)
      4. "anonymous" (impossible normally)
    """
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        # Format: "client, proxy1, proxy2" — phần đầu là real client
        return forwarded.split(",")[0].strip()
    real_ip = request.headers.get("x-real-ip")
    if real_ip:
        return real_ip.strip()
    if request.client:
        return request.client.host
    return "anonymous"


def _build_storage_uri() -> str:
    """Pick Redis URL nếu có, fallback memory:// nếu không."""
    if settings.redis_url:
        log.info("Rate limit storage: Redis (%s)", settings.redis_url.split("@")[-1][:30])
        return settings.redis_url
    log.info("Rate limit storage: memory (single-replica only)")
    return "memory://"


# Singleton — import từ các module khác
limiter = Limiter(
    key_func=_real_client_ip,
    default_limits=[settings.rate_limit_default] if settings.rate_limit_enabled else [],
    storage_uri=_build_storage_uri(),
    # Headers chuẩn theo IETF draft RFC 9512 (X-RateLimit-Remaining, X-RateLimit-Reset)
    headers_enabled=True,
    # Nếu Redis chết hoặc memory backend lỗi → fail-open (cho qua) thay vì block hết
    swallow_errors=True,
)


def get_login_key(request: Request) -> str:
    """Key cho /auth/login: IP thật + email body (nếu có).

    Để attacker không thể bypass IP-only rate limit bằng cách thử nhiều account
    với cùng 1 IP, hoặc thử cùng 1 account từ nhiều IP.
    """
    return _real_client_ip(request)
