"""Patch: thêm SubmissionFile mẫu cho các SubmissionVersion chưa có file."""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select, text
from app.database import AsyncSessionLocal
from app.models.submission import SubmissionFile, SubmissionVersion


async def main():
    _pdf = b"%PDF-1.4 demo submission - ptit contest"
    _zip = b"PK\x03\x04" + b"\x00" * 60

    async with AsyncSessionLocal() as db:
        # Tìm tất cả version chưa có file
        stmt = (
            select(SubmissionVersion)
            .outerjoin(
                SubmissionFile,
                SubmissionFile.submission_version_id == SubmissionVersion.submission_version_id,
            )
            .where(SubmissionFile.submission_file_id.is_(None))
        )
        versions = list((await db.execute(stmt)).scalars().all())
        print(f"Versions chưa có file: {len(versions)}")

        for ver in versions:
            safe = (ver.title or f"version_{ver.submission_version_id}") \
                .replace(" ", "_").replace("—", "").strip("_").lower()[:30]
            db.add(SubmissionFile(
                submission_version_id=ver.submission_version_id,
                file_name=f"bai_lam_{safe}.pdf",
                file_url="",
                mime_type="application/pdf",
                file_size_bytes=len(_pdf),
                file_data=_pdf,
            ))
            db.add(SubmissionFile(
                submission_version_id=ver.submission_version_id,
                file_name=f"source_{safe}.zip",
                file_url="",
                mime_type="application/zip",
                file_size_bytes=len(_zip),
                file_data=_zip,
            ))

        await db.flush()

        # Cập nhật file_url với ID thật
        await db.execute(text(
            "UPDATE submission_files "
            "SET file_url = '/api/submissions/files/' || submission_file_id || '/download' "
            "WHERE file_url = ''"
        ))
        await db.commit()
        print(f"✅ Đã thêm {len(versions) * 2} file cho {len(versions)} versions.")


asyncio.run(main())
