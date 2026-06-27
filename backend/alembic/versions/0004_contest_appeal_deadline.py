"""contest appeal_deadline (2026-06-27)

Q3=C: BTC tự đặt hạn phúc khảo theo từng contest → thêm cột
contests.appeal_deadline.

IDEMPOTENT có chủ đích: cột này đã được thêm sẵn trong init-schema.sql
(baseline cho DB trống). Entrypoint Docker với DB trống chạy init-schema.sql
RỒI `alembic upgrade head`, nên migration phải dùng `ADD COLUMN IF NOT EXISTS`
để không vỡ khi cột đã tồn tại. Với DB cũ (chưa có cột) thì migration tạo mới.

Revision ID: 0004_contest_appeal_deadline
Revises: 0003_contest_fts_index
Create Date: 2026-06-27
"""

from alembic import op

# revision identifiers
revision = "0004_contest_appeal_deadline"
down_revision = "0003_contest_fts_index"
branch_labels = None
depends_on = None

SCHEMA = "ptit_contest"


def upgrade() -> None:
    op.execute(
        f"ALTER TABLE {SCHEMA}.contests "
        "ADD COLUMN IF NOT EXISTS appeal_deadline TIMESTAMPTZ"
    )


def downgrade() -> None:
    op.execute(
        f"ALTER TABLE {SCHEMA}.contests DROP COLUMN IF EXISTS appeal_deadline"
    )
