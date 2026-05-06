"""Security Headers middleware — Phase 1 step 5 (2026-05-06).

Pure ASGI middleware add 5 security headers vào mọi HTTP response:

- Strict-Transport-Security (HSTS) — force HTTPS, chống SSL stripping
- X-Content-Type-Options — chống MIME sniffing exploit
- X-Frame-Options — chống clickjacking (DENY iframe)
- Referrer-Policy — không leak URL referrer cross-origin
- Permissions-Policy — disable browser API mà BE không dùng

Pure ASGI thay vì BaseHTTPMiddleware để KHÔNG buffer response body
(performance tốt hơn, ít memory). Pattern giống AuditASGIMiddleware.

Risk HSTS: Một khi browser cache HSTS max-age, KHÔNG dễ revert. Default
1 năm (31536000s) - chuẩn cho HSTS preload (https://hstspreload.org/).
Nếu muốn ngắn hơn / dài hơn → set HSTS_MAX_AGE env var.

Skip HSTS cho:
- HTTP request (chưa HTTPS thì add HSTS vô nghĩa)
- Localhost / dev mode (HSTS_ENABLED=false hoặc APP_ENV=development)
"""

from __future__ import annotations

import logging
from typing import Awaitable, Callable

from app.config import settings

log = logging.getLogger("security_headers")

# Async ASGI app type
_ASGIApp = Callable[[dict, Callable[[], Awaitable[dict]], Callable[[dict], Awaitable[None]]], Awaitable[None]]


class SecurityHeadersMiddleware:
    """ASGI middleware inject security headers vào response start event.

    KHÔNG buffer body — chỉ intercept event `http.response.start` để mod
    headers list, body stream qua bình thường. Zero-copy, zero-overhead.
    """

    def __init__(self, app: _ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: dict, receive, send) -> None:
        # Chỉ áp dụng cho HTTP (skip websocket/lifespan)
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Wrap send để intercept response start
        async def send_with_headers(message: dict) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                _inject_security_headers(headers, scope)
                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, send_with_headers)


def _inject_security_headers(headers: list[tuple[bytes, bytes]], scope: dict) -> None:
    """Mutate headers list in-place. ASGI headers là list[tuple[bytes, bytes]]."""

    # 1. Strict-Transport-Security (HSTS)
    # Phải check scheme HTTPS — KHÔNG add HSTS cho HTTP (vô nghĩa + có thể harmful).
    # Railway/Heroku/Vercel proxy terminate TLS ở edge → backend nhận scheme="http".
    # Cách đúng: đọc X-Forwarded-Proto header từ proxy. Pattern giống rate_limit
    # đọc X-Forwarded-For thay socket peer IP (Phase 1.2 fix 2026-05-06).
    if settings.hsts_enabled and _is_https_request(scope):
        # Format: "max-age=31536000; includeSubDomains; preload"
        # - max-age: thời gian browser nhớ HSTS (giây). Default 1 năm.
        # - includeSubDomains: áp dụng cho mọi subdomain (vd api.x.com → mọi *.x.com)
        # - preload: cho phép submit lên hstspreload.org list (Chrome built-in HSTS)
        hsts_value = f"max-age={settings.hsts_max_age}; includeSubDomains; preload"
        headers.append((b"strict-transport-security", hsts_value.encode("ascii")))

    # 2. X-Content-Type-Options: chống browser auto-detect Content-Type
    # khác với header server gửi → tránh exploit MIME sniffing
    headers.append((b"x-content-type-options", b"nosniff"))

    # 3. X-Frame-Options: chống clickjacking
    # DENY = không ai embed iframe được (kể cả cùng origin).
    # API backend không cần được embed → DENY là chuẩn nhất.
    headers.append((b"x-frame-options", b"DENY"))

    # 4. Referrer-Policy: kiểm soát info `Referer` header gửi sang request khác
    # strict-origin-when-cross-origin = same-origin gửi full URL, cross-origin
    # chỉ gửi origin (https://example.com), HTTP→HTTPS không gửi gì cả.
    # Đây là default Chrome 85+, set explicit để tương thích old browser.
    headers.append((b"referrer-policy", b"strict-origin-when-cross-origin"))

    # 5. Permissions-Policy: disable browser API mà BE KHÔNG dùng
    # Chống malicious code (vd XSS) gọi getUserMedia/Geolocation từ context page.
    # Backend là API, KHÔNG cần geolocation/microphone/camera/payment.
    permissions_policy = (
        "geolocation=(), microphone=(), camera=(), payment=(), "
        "usb=(), magnetometer=(), gyroscope=(), accelerometer=()"
    )
    headers.append((b"permissions-policy", permissions_policy.encode("ascii")))


def _is_https_request(scope: dict) -> bool:
    """Detect HTTPS từ scope ASGI hoặc X-Forwarded-Proto header.

    Railway/Heroku/Vercel/Render proxy terminate TLS ở edge → ASGI scope nhận
    scheme="http" dù client request HTTPS. Trust X-Forwarded-Proto (proxy set).
    """
    if scope.get("scheme") == "https":
        return True
    # ASGI raw headers = list[tuple[bytes, bytes]] lowercase keys
    for k, v in scope.get("headers", []):
        if k == b"x-forwarded-proto" and v.lower() == b"https":
            return True
    return False
