"""Audit middleware — pure ASGI, fire-and-forget enqueue (Fix P0-3 audit 2026-05-06).

Ghi mọi mutation request (POST/PATCH/PUT/DELETE) vào audit_logs.
Skip endpoints không cần log (auth/login, /health, /docs, /openapi).

Architecture:
- Middleware enqueue payload non-blocking (asyncio.Queue.put_nowait).
- 1 background worker async drain queue, write từng record.
- Worker đời = lifespan của app, start ở startup_audit_worker(), cancel ở shutdown.

Trade-off: nếu queue đầy (>1000 record chưa flush), audit bị drop. Đây là
acceptable degradation — request không nên fail vì audit log.
"""

from __future__ import annotations

import asyncio
import logging
import re
from typing import Iterable

from jose import jwt, JWTError
from sqlalchemy import insert
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.config import settings
from app.models.system import AuditLog


_TRACKED_METHODS = {"POST", "PATCH", "PUT", "DELETE"}

_SKIP_PATTERNS: Iterable[re.Pattern[str]] = [
    re.compile(r"^/api/auth/login$"),
    re.compile(r"^/api/auth/refresh$"),
    re.compile(r"^/api/auth/logout$"),
    re.compile(r"^/api/me/notifications/.+/read$"),
    re.compile(r"^/health$"),
    re.compile(r"^/api/docs"),
    re.compile(r"^/api/openapi"),
    re.compile(r"^/api/redoc"),
]

_ENTITY_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"^/api/contests/(\d+)/submit-for-approval"), "contest_proposal"),
    (re.compile(r"^/api/approvals/(\d+)/decide"), "approval_decision"),
    (re.compile(r"^/api/contests/(\d+)/publish"), "contest_publish"),
    (re.compile(r"^/api/contests/(\d+)/rounds"), "round"),
    (re.compile(r"^/api/contests/(\d+)/entries"), "entry"),
    (re.compile(r"^/api/contests/(\d+)/reviews"), "review"),
    (re.compile(r"^/api/contests/(\d+)/certificates"), "certificate"),
    (re.compile(r"^/api/contests/(\d+)$"), "contest"),
    (re.compile(r"^/api/contests/?$"), "contest"),
    (re.compile(r"^/api/admin/users/(\d+)/lock"), "user_lock"),
    (re.compile(r"^/api/admin/users/(\d+)/unlock"), "user_unlock"),
    (re.compile(r"^/api/admin/users/(\d+)/roles"), "user_roles"),
    (re.compile(r"^/api/admin/users/(\d+)$"), "app_user"),
    (re.compile(r"^/api/admin/users"), "app_user"),
    (re.compile(r"^/api/admin/faculties/(\d+)$"), "faculty"),
    (re.compile(r"^/api/admin/faculties"), "faculty"),
    (re.compile(r"^/api/admin/majors/(\d+)$"), "major"),
    (re.compile(r"^/api/admin/majors"), "major"),
    (re.compile(r"^/api/admin/classes/(\d+)$"), "academic_class"),
    (re.compile(r"^/api/admin/classes"), "academic_class"),
    (re.compile(r"^/api/admin/configs/(.+)$"), "system_config"),
    (re.compile(r"^/api/admin/reviews/(\d+)/moderate"), "review_moderate"),
    (re.compile(r"^/api/assignments/(\d+)/scores"), "score"),
    (re.compile(r"^/api/rounds/(\d+)/criteria"), "criterion"),
    (re.compile(r"^/api/rounds/(\d+)/judge-assignments"), "judge_assignment"),
    (re.compile(r"^/api/rounds/(\d+)/compute-results"), "round_result"),
]


# Engine + queue — lazy init
_audit_engine = None
_audit_session_maker = None
_audit_queue: asyncio.Queue | None = None
_audit_worker_task: asyncio.Task | None = None
_AUDIT_QUEUE_MAX = 1000

log = logging.getLogger("audit")


def _get_audit_session():
    global _audit_engine, _audit_session_maker
    if _audit_session_maker is None:
        _audit_engine = create_async_engine(
            settings.database_url,
            pool_size=2,
            max_overflow=2,
            pool_pre_ping=True,
            connect_args={"server_settings": {"search_path": "ptit_contest,public"}},
        )
        _audit_session_maker = async_sessionmaker(
            bind=_audit_engine, expire_on_commit=False, autoflush=False
        )
    return _audit_session_maker()


def _classify(path: str) -> tuple[str, str | None]:
    for pat, name in _ENTITY_PATTERNS:
        m = pat.match(path)
        if m:
            entity_id = m.group(1) if m.groups() else None
            return name, entity_id
    return "other", None


def _extract_user_id(headers: list[tuple[bytes, bytes]]) -> int | None:
    for k, v in headers:
        if k.lower() == b"authorization":
            try:
                token = v.decode().split(" ", 1)[1]
                payload = jwt.decode(
                    token,
                    settings.jwt_secret_key,
                    algorithms=[settings.jwt_algorithm],
                    options={"verify_aud": False},
                )
                sub = payload.get("sub")
                return int(sub) if sub is not None else None
            except (JWTError, ValueError, IndexError, UnicodeDecodeError):
                return None
    return None


async def _write_audit(payload: dict) -> None:
    """Worker thực hiện INSERT thật. Lỗi chỉ log warning, không re-raise."""
    try:
        details: dict = {
            "method": payload["method"],
            "path": payload["path"],
            "status": payload["status_code"],
        }
        if payload.get("query"):
            details["query"] = payload["query"][:500]
        async with _get_audit_session() as db:
            await db.execute(insert(AuditLog).values(
                user_id=payload.get("user_id"),
                action_type=payload["method"],
                entity_name=payload["entity_name"],
                entity_id=payload.get("entity_id"),
                ip_address=payload.get("ip"),
                details_json=details,
            ))
            await db.commit()
    except Exception as e:
        log.warning("audit write failed: %s", e)


async def _audit_worker_loop():
    """Background drain queue, write audit_log từng record."""
    assert _audit_queue is not None
    while True:
        try:
            payload = await _audit_queue.get()
            await _write_audit(payload)
        except asyncio.CancelledError:
            # Drain phần còn lại trước khi exit (best effort)
            while _audit_queue is not None and not _audit_queue.empty():
                try:
                    payload = _audit_queue.get_nowait()
                    await _write_audit(payload)
                except asyncio.QueueEmpty:
                    break
            raise
        except Exception as e:
            log.warning("audit worker exception: %s", e)


async def start_audit_worker() -> None:
    """Gọi từ FastAPI lifespan startup. Idempotent."""
    global _audit_queue, _audit_worker_task
    if _audit_worker_task is not None and not _audit_worker_task.done():
        return
    _audit_queue = asyncio.Queue(maxsize=_AUDIT_QUEUE_MAX)
    _audit_worker_task = asyncio.create_task(_audit_worker_loop(), name="audit-worker")
    log.info("audit worker started (queue maxsize=%d)", _AUDIT_QUEUE_MAX)


async def stop_audit_worker() -> None:
    """Gọi từ FastAPI lifespan shutdown."""
    global _audit_worker_task, _audit_engine, _audit_session_maker
    if _audit_worker_task is not None:
        _audit_worker_task.cancel()
        try:
            await _audit_worker_task
        except asyncio.CancelledError:
            pass
        _audit_worker_task = None
    if _audit_engine is not None:
        await _audit_engine.dispose()
        _audit_engine = None
        _audit_session_maker = None
    log.info("audit worker stopped")


class AuditASGIMiddleware:
    """Pure ASGI middleware — enqueue audit non-blocking sau khi response đã gửi."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        method = scope.get("method", "")
        path = scope.get("path", "")

        will_audit = (
            method in _TRACKED_METHODS
            and not any(p.match(path) for p in _SKIP_PATTERNS)
        )
        if not will_audit:
            await self.app(scope, receive, send)
            return

        captured_status = {"code": 0}

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                captured_status["code"] = message["status"]
            await send(message)

        await self.app(scope, receive, send_wrapper)

        # Sau khi response xong → enqueue NON-BLOCKING. Drop nếu queue full.
        try:
            status_code = captured_status["code"]
            if not (200 <= status_code < 300):
                return
            if _audit_queue is None:
                # Worker chưa start (startup race) — skip thay vì block
                return
            user_id = _extract_user_id(scope.get("headers", []))
            entity_name, entity_id = _classify(path)
            client = scope.get("client")
            ip = client[0] if client else None
            query = scope.get("query_string", b"").decode("latin-1", errors="ignore")

            payload = {
                "user_id": user_id,
                "method": method,
                "path": path,
                "entity_name": entity_name,
                "entity_id": entity_id,
                "ip": ip,
                "status_code": status_code,
                "query": query,
            }
            try:
                _audit_queue.put_nowait(payload)
            except asyncio.QueueFull:
                log.warning("audit queue full — dropping log for %s %s", method, path)
        except Exception as e:
            log.warning("audit enqueue failed: %s", e)
