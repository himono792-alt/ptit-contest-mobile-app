"""contest_entries.schedule_conflict_ack (2026-06-29)

Option B chống trùng lịch: SV được cảnh báo khi đăng ký cuộc thi trùng ngày với
cuộc thi khác đã đăng ký. Nếu vẫn cố tình đăng ký → cột này = TRUE để GV nhìn
danh sách thí sinh biết SV đã đăng ký dù trùng lịch.

IDEMPOTENT: cột đã có sẵn trong init-schema.sql (DB trống). Migration dùng
ADD COLUMN IF NOT EXISTS để DB cũ cũng có cột mà không vỡ khi đã tồn tại.

Revision ID: 0006_entry_schedule_conflict_ack
Revises: 0005_result_appeals_table
Create Date: 2026-06-29
"""

from alembic import op

# revision identifiers
revision = "0006_entry_schedule_conflict_ack"
down_revision = "0005_result_appeals_table"
branch_labels = None
depends_on = None

SCHEMA = "ptit_contest"


def upgrade() -> None:
    op.execute(
        f"ALTER TABLE {SCHEMA}.contest_entries "
        "ADD COLUMN IF NOT EXISTS schedule_conflict_ack BOOLEAN NOT NULL DEFAULT FALSE"
    )


def downgrade() -> None:
    op.execute(
        f"ALTER TABLE {SCHEMA}.contest_entries DROP COLUMN IF EXISTS schedule_conflict_ack"
    )
