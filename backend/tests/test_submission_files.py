"""Test luồng upload + download file bài nộp (2026-06-16).

Backend đã có endpoint upload (R2 + BYTEA fallback). Test khoá hành vi end-to-end
ở chế độ BYTEA (R2 tắt trong test): SV upload file vào version → download lại đúng bytes.
"""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.models.contest import Contest, ContestRound
from app.models.entry import ContestEntry
from app.models.enums import (
    ContestStatus,
    DeliveryMode,
    EntryType,
    RegistrationStatus,
    RoundType,
    SubmissionStatus,
)
from app.models.identity import AppUser
from app.models.master_data import Student
from app.models.submission import Submission, SubmissionVersion
from tests.conftest import auth_header, login_token

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)
SV = "b22dccn001@ptit.edu.vn"


async def _build_version(db):
    user = (await db.execute(select(AppUser).where(AppUser.email == SV))).scalar_one()
    st = (await db.execute(select(Student).where(Student.user_id == user.user_id))).scalar_one()
    contest = Contest(
        slug="upload-flow-test",
        title="Contest upload file",
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        requires_submission=True,
        start_at=NOW - timedelta(days=1),
        end_at=NOW + timedelta(days=5),
        status=ContestStatus.ONGOING,
        created_by=user.user_id,
    )
    db.add(contest)
    await db.flush()
    rnd = ContestRound(
        contest_id=contest.contest_id, round_no=1, round_name="Vòng 1",
        round_type=RoundType.FINAL, start_at=NOW - timedelta(days=1),
        end_at=NOW + timedelta(days=5),
    )
    db.add(rnd)
    await db.flush()
    entry = ContestEntry(
        contest_id=contest.contest_id, entry_type=EntryType.INDIVIDUAL,
        student_id=st.student_id, registration_status=RegistrationStatus.APPROVED,
    )
    db.add(entry)
    await db.flush()
    sub = Submission(round_id=rnd.round_id, entry_id=entry.entry_id,
                     status=SubmissionStatus.SUBMITTED, current_version_no=1)
    db.add(sub)
    await db.flush()
    ver = SubmissionVersion(submission_id=sub.submission_id, version_no=1,
                            submitted_by=user.user_id, text_answer="bài làm")
    db.add(ver)
    await db.flush()
    await db.commit()
    return ver.submission_version_id


async def test_upload_then_download_roundtrip(client, db):
    version_id = await _build_version(db)
    token = await login_token(client, SV)
    payload = b"Day la noi dung file bao cao PDF gia lap.\n"

    up = await client.post(
        f"/api/submissions/versions/{version_id}/files",
        headers=auth_header(token),
        files={"file": ("baocao.txt", payload, "text/plain")},
    )
    assert up.status_code == 201, up.text
    meta = up.json()
    assert meta["file_name"] == "baocao.txt"
    assert meta["file_size_bytes"] == len(payload)
    file_id = meta["submission_file_id"]

    down = await client.get(
        f"/api/submissions/files/{file_id}/download", headers=auth_header(token)
    )
    assert down.status_code == 200
    assert down.content == payload


async def test_upload_rejects_non_owner(client, db):
    version_id = await _build_version_other(db)
    token = await login_token(client, SV)  # SV không phải owner
    up = await client.post(
        f"/api/submissions/versions/{version_id}/files",
        headers=auth_header(token),
        files={"file": ("x.txt", b"abc", "text/plain")},
    )
    assert up.status_code == 403


async def _build_version_other(db):
    """Version do SV khác (b22dccn003) sở hữu — để test chặn non-owner."""
    other = (await db.execute(
        select(AppUser).where(AppUser.email == "b22dccn003@ptit.edu.vn"))).scalar_one()
    st = (await db.execute(select(Student).where(Student.user_id == other.user_id))).scalar_one()
    contest = Contest(
        slug="upload-flow-other", title="Contest upload other",
        delivery_mode=DeliveryMode.ONLINE, participation_mode=EntryType.INDIVIDUAL,
        start_at=NOW - timedelta(days=1), end_at=NOW + timedelta(days=5),
        status=ContestStatus.ONGOING, created_by=other.user_id,
    )
    db.add(contest)
    await db.flush()
    rnd = ContestRound(contest_id=contest.contest_id, round_no=1, round_name="V1",
                       round_type=RoundType.FINAL, start_at=NOW, end_at=NOW + timedelta(days=5))
    db.add(rnd)
    await db.flush()
    entry = ContestEntry(contest_id=contest.contest_id, entry_type=EntryType.INDIVIDUAL,
                         student_id=st.student_id, registration_status=RegistrationStatus.APPROVED)
    db.add(entry)
    await db.flush()
    sub = Submission(round_id=rnd.round_id, entry_id=entry.entry_id,
                     status=SubmissionStatus.SUBMITTED, current_version_no=1)
    db.add(sub)
    await db.flush()
    ver = SubmissionVersion(submission_id=sub.submission_id, version_no=1,
                            submitted_by=other.user_id, text_answer="x")
    db.add(ver)
    await db.flush()
    await db.commit()
    return ver.submission_version_id
