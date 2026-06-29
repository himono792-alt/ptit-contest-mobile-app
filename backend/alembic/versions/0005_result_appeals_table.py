"""result_appeals table — vá hở migration phúc khảo (2026-06-29)

VẤN ĐỀ: bảng `result_appeals` + type `appeal_status_enum` chỉ được tạo trong
`init-schema.sql` (đường chạy khi DB TRỐNG). Migration 0004 chỉ thêm cột
`contests.appeal_deadline`, KHÔNG tạo bảng. Hệ quả: bản clone có volume Postgres
CŨ → entrypoint chạy `alembic upgrade head` → không bao giờ có bảng `result_appeals`
→ API phúc khảo 500 → FE không hiện gì (F5 vô ích).

FIX: migration này tạo idempotent enum + bảng + trigger ĐÚNG theo init-schema.sql.
IDEMPOTENT có chủ đích: với DB trống (init-schema.sql đã tạo sẵn) thì
`IF NOT EXISTS` / DO-block bỏ qua; với DB cũ thì tạo mới → đồng bộ hai đường.

Revision ID: 0005_result_appeals_table
Revises: 0004_contest_appeal_deadline
Create Date: 2026-06-29
"""

from alembic import op

# revision identifiers
revision = "0005_result_appeals_table"
down_revision = "0004_contest_appeal_deadline"
branch_labels = None
depends_on = None

SCHEMA = "ptit_contest"


def upgrade() -> None:
    # 1) Enum type — CREATE TYPE không có IF NOT EXISTS → dùng DO-block kiểm tra pg_type.
    op.execute(f"""
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_type t
                JOIN pg_namespace n ON n.oid = t.typnamespace
                WHERE t.typname = 'appeal_status_enum' AND n.nspname = '{SCHEMA}'
            ) THEN
                CREATE TYPE {SCHEMA}.appeal_status_enum AS ENUM (
                    'PENDING', 'IN_REVIEW', 'ACCEPTED', 'REJECTED', 'CLOSED'
                );
            END IF;
        END $$;
    """)

    # 2) Bảng result_appeals — khớp 100% init-schema.sql.
    op.execute(f"""
        CREATE TABLE IF NOT EXISTS {SCHEMA}.result_appeals (
            appeal_id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            contest_id               BIGINT NOT NULL REFERENCES {SCHEMA}.contests(contest_id) ON DELETE CASCADE,
            round_id                 BIGINT REFERENCES {SCHEMA}.contest_rounds(round_id) ON DELETE SET NULL,
            entry_id                 BIGINT NOT NULL REFERENCES {SCHEMA}.contest_entries(entry_id) ON DELETE CASCADE,
            submitted_by_student_id  BIGINT NOT NULL REFERENCES {SCHEMA}.students(student_id) ON DELETE RESTRICT,
            title                    VARCHAR(255) NOT NULL,
            content_text             TEXT NOT NULL,
            status                   {SCHEMA}.appeal_status_enum NOT NULL DEFAULT 'PENDING',
            response_text            TEXT,
            handled_by               BIGINT REFERENCES {SCHEMA}.app_users(user_id) ON DELETE SET NULL,
            handled_at               TIMESTAMPTZ,
            created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
    """)

    # 3) Trigger updated_at — dùng lại function set_updated_at() có sẵn từ baseline.
    op.execute(f"""
        DROP TRIGGER IF EXISTS trg_result_appeals_updated_at ON {SCHEMA}.result_appeals
    """)
    op.execute(f"""
        CREATE TRIGGER trg_result_appeals_updated_at
        BEFORE UPDATE ON {SCHEMA}.result_appeals
        FOR EACH ROW EXECUTE FUNCTION {SCHEMA}.set_updated_at()
    """)


def downgrade() -> None:
    op.execute(f"DROP TRIGGER IF EXISTS trg_result_appeals_updated_at ON {SCHEMA}.result_appeals")
    op.execute(f"DROP TABLE IF EXISTS {SCHEMA}.result_appeals")
    op.execute(f"DROP TYPE IF EXISTS {SCHEMA}.appeal_status_enum")
