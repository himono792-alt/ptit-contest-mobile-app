"""faculty_cert_templates — Sprint 25 P2-C1 (2026-05-09)

Bảng template chứng nhận faculty-level cho BCN quản lý (khác `certificate_templates`
hiện tại gắn `contest_id` per-contest). BCN duyệt mẫu để các GV trong khoa
sử dụng chung khi cấp chứng nhận.

Revision ID: 0002_faculty_cert_templates
Revises: 0001_baseline_v04
Create Date: 2026-05-09
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers
revision = "0002_faculty_cert_templates"
down_revision = "0001_baseline_v04"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE IF NOT EXISTS ptit_contest.faculty_cert_templates (
            template_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            faculty_id BIGINT NOT NULL REFERENCES ptit_contest.faculties(faculty_id) ON DELETE CASCADE,
            name VARCHAR(150) NOT NULL,
            layout_description TEXT NOT NULL,
            signers TEXT NOT NULL,
            is_active BOOLEAN NOT NULL DEFAULT FALSE,
            created_by BIGINT REFERENCES ptit_contest.app_users(user_id) ON DELETE SET NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_faculty_cert_templates_faculty
        ON ptit_contest.faculty_cert_templates(faculty_id)
    """)
    # Trigger updated_at
    op.execute("""
        CREATE OR REPLACE FUNCTION ptit_contest.set_faculty_cert_template_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql
    """)
    op.execute("""
        DROP TRIGGER IF EXISTS trg_faculty_cert_templates_updated_at
        ON ptit_contest.faculty_cert_templates
    """)
    op.execute("""
        CREATE TRIGGER trg_faculty_cert_templates_updated_at
        BEFORE UPDATE ON ptit_contest.faculty_cert_templates
        FOR EACH ROW EXECUTE FUNCTION ptit_contest.set_faculty_cert_template_updated_at()
    """)


def downgrade() -> None:
    op.execute("""
        DROP TRIGGER IF EXISTS trg_faculty_cert_templates_updated_at
        ON ptit_contest.faculty_cert_templates
    """)
    op.execute("DROP FUNCTION IF EXISTS ptit_contest.set_faculty_cert_template_updated_at()")
    op.execute("DROP INDEX IF EXISTS ptit_contest.idx_faculty_cert_templates_faculty")
    op.execute("DROP TABLE IF EXISTS ptit_contest.faculty_cert_templates")
