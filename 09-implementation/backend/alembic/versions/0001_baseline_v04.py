"""baseline_v04 — schema đã được apply qua init-schema.sql v04

Migration này KHÔNG thực sự thay đổi schema (no-op).
Mục đích: stamp Alembic version table để các migration tiếp theo có baseline.

Workflow áp dụng:
  - DB mới: chạy init-schema.sql v04 → alembic stamp head (đánh dấu = migration này)
  - DB production hiện tại: chạy alembic stamp head (vì DB đã ở v04 state qua
    idempotent ALTER cũ trong main.py lifespan)

Sau migration này, mọi schema change phải qua:
  alembic revision --autogenerate -m "feature_xxx"
  → review file generated
  → alembic upgrade head

Revision ID: 0001_baseline_v04
Revises: (none — initial)
Create Date: 2026-05-06
"""

from alembic import op  # noqa: F401  -- needed cho Alembic discovery


# revision identifiers
revision = "0001_baseline_v04"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """No-op — schema được apply qua init-schema.sql v04 trước khi stamp."""
    pass


def downgrade() -> None:
    """No-op — không thể downgrade từ baseline."""
    pass
