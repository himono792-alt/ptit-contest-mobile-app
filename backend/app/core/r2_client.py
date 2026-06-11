"""Cloudflare R2 client wrapper — Sprint 3 (2026-05-07).

R2 là S3-compatible object storage của Cloudflare (free 10GB + 1M Class A ops/mo).
Ưu điểm so với BYTEA in-DB:
- Storage tách khỏi DB → giảm DB size + faster query
- 10GB free vs ~10MB per BYTEA limit
- Egress free (Cloudflare không charge bandwidth)
- Production grade

Wrapper này:
- Lazy init client (chỉ tạo khi gọi function đầu tiên).
- Skip nếu env vars rỗng (R2_BUCKET_NAME, R2_ACCESS_KEY_ID...) → fallback BYTEA legacy.
- Async qua aiobotocore (kế thừa async pattern của FastAPI + asyncpg).

Usage:
    >>> from app.core.r2_client import get_r2_client, is_r2_enabled
    >>> if is_r2_enabled():
    ...     client = get_r2_client()
    ...     await client.put_object(Bucket="...", Key="...", Body=b"...")

Setup env vars (Railway):
- R2_ENDPOINT_URL=https://{account_id}.r2.cloudflarestorage.com
- R2_ACCESS_KEY_ID=...
- R2_SECRET_ACCESS_KEY=...
- R2_BUCKET_NAME=ptit-contest-submissions
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

from app.config import settings

log = logging.getLogger(__name__)


def is_r2_enabled() -> bool:
    """True nếu đủ env vars để init R2 client."""
    return bool(
        settings.r2_endpoint_url
        and settings.r2_access_key_id
        and settings.r2_secret_access_key
        and settings.r2_bucket_name
    )


@asynccontextmanager
async def get_r2_client() -> AsyncIterator:
    """Async context manager trả về aiobotocore S3 client config cho R2.

    Lazy import aiobotocore để tránh hard-fail nếu package chưa install
    (khi anh deploy với R2 disabled).
    """
    if not is_r2_enabled():
        raise RuntimeError(
            "R2 client gọi mà R2 chưa enabled. Check env vars R2_*."
        )
    try:
        from aiobotocore.session import get_session  # type: ignore
    except ImportError as e:
        raise RuntimeError(
            "aiobotocore chưa install. Add `aiobotocore` vào pyproject.toml."
        ) from e

    session = get_session()
    async with session.create_client(
        "s3",
        endpoint_url=settings.r2_endpoint_url,
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
        # R2 dùng region "auto" (Cloudflare global anycast).
        region_name="auto",
    ) as client:
        yield client


async def put_object(
    object_key: str,
    body: bytes,
    content_type: str | None = None,
) -> None:
    """Upload bytes lên R2 với object key cho trước.

    Raises RuntimeError nếu R2 chưa enabled.
    """
    async with get_r2_client() as client:
        kwargs: dict = {
            "Bucket": settings.r2_bucket_name,
            "Key": object_key,
            "Body": body,
        }
        if content_type:
            kwargs["ContentType"] = content_type
        await client.put_object(**kwargs)
        log.info("R2 PUT %s/%s (%d bytes)",
                 settings.r2_bucket_name, object_key, len(body))


async def get_object_stream(object_key: str) -> tuple[bytes, dict]:
    """Download object từ R2 → (bytes, metadata).

    Returns:
        (body bytes, response metadata dict với keys: ContentType, ContentLength, ...)

    Raises:
        Cloudflare ClientError nếu key không tồn tại.
    """
    async with get_r2_client() as client:
        resp = await client.get_object(
            Bucket=settings.r2_bucket_name,
            Key=object_key,
        )
        async with resp["Body"] as stream:
            body = await stream.read()
        meta = {
            "ContentType": resp.get("ContentType"),
            "ContentLength": resp.get("ContentLength"),
        }
        return body, meta


async def generate_presigned_get_url(
    object_key: str,
    expires_in: int = 900,
) -> str:
    """Generate presigned URL cho GET object (default TTL 15 phút).

    User có thể download trực tiếp từ R2 mà không qua BE proxy.
    Useful cho large files (giảm BE bandwidth).

    Args:
        object_key: Path object trong bucket.
        expires_in: TTL seconds (default 900s = 15 phút).

    Returns:
        Presigned HTTPS URL.
    """
    async with get_r2_client() as client:
        url = await client.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": settings.r2_bucket_name,
                "Key": object_key,
            },
            ExpiresIn=expires_in,
        )
        return url


async def delete_object(object_key: str) -> None:
    """Xóa object khỏi R2. Idempotent — không raise nếu key không tồn tại."""
    async with get_r2_client() as client:
        await client.delete_object(
            Bucket=settings.r2_bucket_name,
            Key=object_key,
        )
        log.info("R2 DELETE %s/%s", settings.r2_bucket_name, object_key)


def build_object_key(
    contest_id: int,
    round_id: int,
    entry_id: int,
    version_no: int,
    file_name: str,
) -> str:
    """Tạo object key có hierarchy rõ rệt cho dễ debug + cleanup.

    Format: contests/{cid}/rounds/{rid}/entries/{eid}/v{version}/{filename}

    Sanitize filename — chỉ giữ ASCII safe chars (R2 hỗ trợ nhiều ký tự
    nhưng để URL clean + curl-friendly, normalize trước).
    """
    # Sanitize: keep alphanumeric + dash + underscore + dot. Replace others với _.
    safe_name = "".join(
        c if c.isalnum() or c in "-_." else "_" for c in file_name
    )
    return (
        f"contests/{contest_id}/rounds/{round_id}/entries/{entry_id}"
        f"/v{version_no}/{safe_name}"
    )
