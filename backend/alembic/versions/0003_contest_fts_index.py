"""contest full-text search GIN index (2026-06-16)

Thêm GIN index phục vụ full-text search cuộc thi trên
title + description + rules_text + award_text (cấu hình 'simple').
Khớp đúng biểu thức query trong app/routers/contests.py để planner dùng index.

Revision ID: 0003_contest_fts_index
Revises: 0002_faculty_cert_templates
Create Date: 2026-06-16
"""

from alembic import op


# revision identifiers
revision = "0003_contest_fts_index"
down_revision = "0002_faculty_cert_templates"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_contests_fts
        ON ptit_contest.contests USING GIN (
            to_tsvector('simple',
                coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
                coalesce(rules_text, '') || ' ' || coalesce(award_text, '')))
    """)


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ptit_contest.idx_contests_fts")
