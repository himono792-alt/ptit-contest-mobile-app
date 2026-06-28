"""Submission router (SV-08 nộp bài, GV-04 quản lý).

Endpoints:
  GET  /api/rounds/{round_id}                              — Round detail (Sprint 16 countdown)
  POST /api/rounds/{round_id}/submissions/me/versions      — SV nộp version mới
  POST /api/submissions/versions/{id}/files                — SV upload file (multipart)
  GET  /api/submissions/files/{file_id}/download           — Download file (BYTEA stream)
  GET  /api/rounds/{round_id}/submissions/me               — SV xem submission của mình
  GET  /api/rounds/{round_id}/submissions                  — GV list (BTC contest only)
  GET  /api/submissions/{id}                               — Detail (perm check)
  POST /api/submissions/{id}/lock                          — GV lock
"""

from typing import Annotated
from urllib.parse import quote

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import r2_client
from app.database import get_db
from app.deps import CurrentUser
from app.models.contest import ContestRound
from app.models.submission import SubmissionFile, SubmissionVersion
from app.schemas.contest import ContestRoundOut
from app.schemas.submission import (
    SubmissionDetail,
    SubmissionOut,
    SubmissionVersionCreateIn,
    SubmissionVersionOut,
)
from app.services import submission_service

rounds_router = APIRouter(prefix="/rounds", tags=["submissions"])
submissions_router = APIRouter(prefix="/submissions", tags=["submissions"])

# Demo: lưu file BYTEA trong DB. Limit 10MB.
_MAX_FILE_SIZE = 10 * 1024 * 1024
_ALLOWED_MIME_TYPES = {
    "application/pdf",
    "application/zip",
    "application/x-zip-compressed",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "image/png",
    "image/jpeg",
    "image/gif",
    "text/plain",
    "text/csv",
}


# ---------- ROUND DETAIL (Sprint 16 2026-05-08 — countdown card SV submission) ----------

@rounds_router.get("/{round_id}", response_model=ContestRoundOut)
async def get_round_detail(
    round_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestRoundOut:
    """Sprint 16 — trả round detail kèm submission_close_at + end_at để FE
    render countdown timer. Public endpoint (không cần auth) vì info contest
    đã public qua list-rounds, chỉ thêm tiện shortcut khi FE chỉ có round_id."""
    rnd = (
        await db.execute(select(ContestRound).where(ContestRound.round_id == round_id))
    ).scalar_one_or_none()
    if rnd is None:
        raise HTTPException(404, f"Round {round_id} không tồn tại")
    return ContestRoundOut.model_validate(rnd)


# ---------- SV ----------

@rounds_router.post(
    "/{round_id}/submissions/me/versions",
    response_model=SubmissionVersionOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_my_version(
    round_id: int,
    data: SubmissionVersionCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionVersionOut:
    """SV-08 — Nộp version mới cho submission. Tự tạo submission nếu chưa."""
    _, version = await submission_service.add_my_version(db, user, round_id, data)
    return SubmissionVersionOut.model_validate(version)


@rounds_router.get(
    "/{round_id}/submissions/me",
    response_model=SubmissionDetail | None,
)
async def get_my_submission(
    round_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionDetail | None:
    """SV-08 — Xem submission của mình trong round (kèm versions). Trả null nếu chưa nộp."""
    submission = await submission_service.get_my_submission_in_round(db, user, round_id)
    if submission is None:
        return None
    return SubmissionDetail.model_validate(submission)


# ---------- GV-04 ----------

@rounds_router.get(
    "/{round_id}/submissions",
    response_model=list[SubmissionOut],
)
async def list_round_submissions(
    round_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[SubmissionOut]:
    """GV-04 — Danh sách submissions trong round (BTC + JUDGE assigned only)."""
    subs = await submission_service.list_round_submissions(db, user, round_id)
    return [SubmissionOut.model_validate(s) for s in subs]


@submissions_router.get("/{submission_id}", response_model=SubmissionDetail)
async def get_submission_detail(
    submission_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionDetail:
    submission = await submission_service.get_submission_detail(db, user, submission_id)
    return SubmissionDetail.model_validate(submission)


@submissions_router.post("/{submission_id}/lock", response_model=SubmissionOut)
async def lock_submission(
    submission_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SubmissionOut:
    """GV-04 — Lock submission (SV không nộp tiếp được)."""
    submission = await submission_service.lock_submission(db, user, submission_id)
    return SubmissionOut.model_validate(submission)


# ---------- File upload / download ----------

@submissions_router.post(
    "/versions/{version_id}/files",
    status_code=status.HTTP_201_CREATED,
)
async def upload_file_to_version(
    version_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(...),
) -> dict:
    """SV-08 — Upload file đính kèm vào 1 submission version.

    Limit 10MB, lưu BYTEA trong DB (demo mode).
    Production nên dùng S3/R2 + signed URL.
    """
    # Validate version thuộc về SV
    version = await db.get(SubmissionVersion, version_id)
    if version is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Version not found")
    if version.submitted_by != user.user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Chỉ owner mới upload file vào version của mình"
        )

    # Read file bytes
    content = await file.read()
    if len(content) > _MAX_FILE_SIZE:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            f"File quá lớn ({len(content) // 1024} KB). Tối đa {_MAX_FILE_SIZE // 1024 // 1024} MB.",
        )
    if file.content_type and file.content_type not in _ALLOWED_MIME_TYPES:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            f"MIME type không hỗ trợ: {file.content_type}. "
            f"Cho phép: PDF, Word, Excel, PowerPoint, ảnh, ZIP, text.",
        )

    # Sprint 3 (2026-05-07): R2 mode khi env vars có. Fallback BYTEA legacy nếu chưa enable.
    file_name = file.filename or "untitled"
    r2_object_key: str | None = None
    file_data_for_db: bytes | None = content

    if r2_client.is_r2_enabled():
        # Build R2 key có hierarchy: contests/{cid}/rounds/{rid}/entries/{eid}/v{n}/{filename}.
        # Cần lookup contest_id + entry_id + round_id từ version_id qua join 3 tables.
        from app.models.submission import Submission as _Sub  # avoid circular at module top
        join_stmt = (
            select(_Sub.round_id, _Sub.entry_id)
            .join(SubmissionVersion, SubmissionVersion.submission_id == _Sub.submission_id)
            .where(SubmissionVersion.submission_version_id == version_id)
        )
        row = (await db.execute(join_stmt)).first()
        if row is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Submission hierarchy not found")
        round_id, entry_id = row
        # Lookup contest_id qua entry → contest hoặc round → contest. Dùng entry vì có index.
        from app.models.entry import ContestEntry as _Entry
        contest_id_stmt = select(_Entry.contest_id).where(_Entry.entry_id == entry_id)
        contest_id = (await db.execute(contest_id_stmt)).scalar_one_or_none()
        if contest_id is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
        r2_object_key = r2_client.build_object_key(
            contest_id=contest_id,
            round_id=round_id,
            entry_id=entry_id,
            version_no=version.version_no,
            file_name=file_name,
        )
        # Upload R2
        await r2_client.put_object(
            object_key=r2_object_key,
            body=content,
            content_type=file.content_type,
        )
        # Khi R2 OK, KHÔNG lưu BYTEA in-DB → tiết kiệm space.
        file_data_for_db = None

    # Save to DB
    sub_file = SubmissionFile(
        submission_version_id=version_id,
        file_name=file_name,
        file_url=f"/api/submissions/files/{version_id}",  # Placeholder, sẽ update sau
        mime_type=file.content_type,
        file_size_bytes=len(content),
        file_data=file_data_for_db,
        r2_object_key=r2_object_key,
    )
    db.add(sub_file)
    await db.flush()
    # Update file_url với file_id thật
    sub_file.file_url = f"/api/submissions/files/{sub_file.submission_file_id}/download"
    await db.commit()
    await db.refresh(sub_file)

    return {
        "submission_file_id": sub_file.submission_file_id,
        "file_name": sub_file.file_name,
        "file_url": sub_file.file_url,
        "mime_type": sub_file.mime_type,
        "file_size_bytes": sub_file.file_size_bytes,
    }


@submissions_router.get("/files/{file_id}/download")
async def download_file(
    file_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Stream file BYTEA xuống client.

    Auth required (fix P1-2 2026-05-06): chỉ owner SV / member team / BTC contest /
    JUDGE assigned / ADMIN xem được. Trước đây public bypass — giờ đã siết.
    """
    stmt = select(SubmissionFile).where(
        SubmissionFile.submission_file_id == file_id
    )
    sub_file = (await db.execute(stmt)).scalar_one_or_none()
    if sub_file is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "File not found")
    # Sprint 3 (2026-05-07): R2 mode khi r2_object_key NOT NULL.
    # Fallback legacy BYTEA nếu r2_object_key NULL + file_data NOT NULL.
    if sub_file.r2_object_key is None and sub_file.file_data is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "File data trống (legacy file chưa migrate)",
        )

    # Lookup submission qua version → submission → reuse perm check sẵn có
    version = await db.get(SubmissionVersion, sub_file.submission_version_id)
    if version is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Version not found")
    submission = await submission_service.get_submission_detail(
        db, user, version.submission_id,
    )
    # get_submission_detail đã raise 403 nếu không có quyền → tới đây là OK
    _ = submission  # silence unused var warning

    # RFC 6266: HTTP header chỉ encode được latin-1. file_name có dấu tiếng Việt
    # (vd "bài_nộp_của_nguyễn_văn_an.pdf") sẽ khiến uvicorn raise UnicodeEncodeError
    # → response fail → FE báo "Có lỗi xảy ra". Fix: filename ASCII fallback +
    # filename*=UTF-8'' percent-encoded cho tên gốc có dấu.
    raw_name = sub_file.file_name or "download"
    ascii_name = raw_name.encode("ascii", "ignore").decode("ascii").strip() or "download"
    utf8_name = quote(raw_name)
    headers = {
        "Content-Disposition": (
            f'inline; filename="{ascii_name}"; filename*=UTF-8\'\'{utf8_name}'
        ),
    }
    if sub_file.file_size_bytes:
        headers["Content-Length"] = str(sub_file.file_size_bytes)

    if sub_file.r2_object_key is not None:
        # R2 mode: stream từ R2 qua BE proxy.
        body, meta = await r2_client.get_object_stream(sub_file.r2_object_key)

        def _iter_r2():
            yield body

        return StreamingResponse(
            _iter_r2(),
            media_type=meta.get("ContentType") or sub_file.mime_type or "application/octet-stream",
            headers=headers,
        )

    # Legacy BYTEA fallback
    def _iter_bytea():
        yield bytes(sub_file.file_data)

    return StreamingResponse(
        _iter_bytea(),
        media_type=sub_file.mime_type or "application/octet-stream",
        headers=headers,
    )
