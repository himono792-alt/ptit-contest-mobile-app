#!/bin/sh
# Entry point cho container backend (Sprint 0 P0-4 audit 2026-05-06).
# Workflow:
#   1. Đợi DB ready
#   2. Nếu schema CHƯA tồn tại → chạy init-schema.sql v04 + alembic stamp head
#   3. Nếu schema ĐÃ tồn tại nhưng KHÔNG có alembic_version → stamp head (legacy)
#   4. Nếu có alembic_version → alembic upgrade head (apply pending migrations)
#   5. Optional seed users
#   6. Start uvicorn

set -e

PORT="${PORT:-8000}"

echo "PTIT Contest Backend starting..."
echo "  PORT=$PORT"

# Railway/Render thường set DATABASE_URL=postgresql://... (cho Django/SQLAlchemy sync)
# SQLAlchemy async cần postgresql+asyncpg:// → tự convert ngược lại
if echo "$DATABASE_URL" | grep -q "^postgresql://"; then
  export DATABASE_URL=$(echo "$DATABASE_URL" | sed 's|^postgresql://|postgresql+asyncpg://|')
  echo "  Converted DATABASE_URL → asyncpg dialect"
fi
echo "  DATABASE_URL=$(echo "$DATABASE_URL" | cut -c1-50)..."

# psql cần postgresql:// (sync), strip +asyncpg
PSQL_URL=$(echo "$DATABASE_URL" | sed 's|postgresql+asyncpg://|postgresql://|')

# Wait for DB ready (max 30s)
echo "Waiting for PostgreSQL..."
for i in $(seq 1 30); do
  if psql "$PSQL_URL" -c '\q' 2>/dev/null; then
    echo "PostgreSQL ready"
    break
  fi
  sleep 1
done

# ----- Schema state detection -----
SCHEMA_EXISTS=$(psql "$PSQL_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='ptit_contest' AND table_name='app_users' LIMIT 1;" 2>/dev/null || echo "")
ALEMBIC_EXISTS=$(psql "$PSQL_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='ptit_contest' AND table_name='alembic_version' LIMIT 1;" 2>/dev/null || echo "")

cd /app

if [ -z "$SCHEMA_EXISTS" ]; then
  # ----- Trường hợp 1: DB trống → init từ raw SQL + stamp baseline -----
  echo "Schema chưa tồn tại — init từ raw SQL v04..."
  if [ -f "/app/init-schema.sql" ]; then
    psql "$PSQL_URL" -f /app/init-schema.sql
    echo "Schema init done"
    # init-schema.sql = trạng thái của baseline 0001. Stamp 0001 RỒI upgrade head để
    # các migration sau baseline (vd 0002_faculty_cert_templates — KHÔNG nằm trong
    # init-schema.sql) thực sự được apply. Trước đây stamp thẳng head → bỏ qua 0002
    # → DB mới thiếu bảng faculty_cert_templates (màn BCN mẫu chứng nhận lỗi).
    echo "Alembic stamp baseline (0001) + upgrade head..."
    alembic stamp 0001_baseline_v04
    alembic upgrade head
    echo "Alembic baseline stamped + migrations applied"
  else
    echo "WARN: /app/init-schema.sql không tồn tại — skip init"
  fi
elif [ -z "$ALEMBIC_EXISTS" ]; then
  # ----- Trường hợp 2: DB cũ có schema nhưng chưa có alembic_version → stamp -----
  echo "Schema tồn tại nhưng chưa track Alembic — stamp baseline..."
  alembic stamp head
  echo "Legacy DB đã được stamp baseline"
else
  # ----- Trường hợp 3: DB đã track Alembic → upgrade head -----
  echo "Alembic upgrade head..."
  alembic upgrade head
  echo "Migrations up-to-date"
fi

# Seed demo data — idempotent, an toàn chạy mỗi lần boot.
# Tạo 4 vai trò (SV/GV/BCN/Admin) + 2 cuộc thi mẫu để bản clone-and-run có sẵn
# dữ liệu demo (không phải tự tạo gì). Mật khẩu = env DEMO_PASSWORD (fallback abc123).
# Reset sạch: `docker compose down -v` rồi `up` lại.
if [ -f "/app/scripts/seed-demo.py" ]; then
  echo "Seeding demo data (idempotent)..."
  python /app/scripts/seed-demo.py || echo "Seed demo failed (non-fatal)"
fi

# Seed RICH — làm giàu dữ liệu trên nền seed-demo (3 khoa thêm, 14 SV, 3 cuộc thi
# FINISHED có cert + leaderboard, 1 cuộc thi sắp mở, reviews/Q&A/articles/audit).
# PHẢI chạy SAU seed-demo vì phụ thuộc base users (gv@/bcn@/admin@/B22DCCN001..).
# Cũng idempotent (guard theo slug/email/unique key) + non-fatal để demo không kẹt.
if [ -f "/app/scripts/seed-rich.py" ]; then
  echo "Seeding RICH demo data (idempotent)..."
  python /app/scripts/seed-rich.py || echo "Seed rich failed (non-fatal)"
fi

# File nộp mẫu (BYTEA) cho các SubmissionVersion chưa có file — để bản clone-and-run
# hiện được file trong màn Chấm bài của GV. Idempotent: chỉ thêm cho version chưa có
# file nào, chạy lại không nhân đôi. PHẢI sau seed-rich (cần submissions đã tồn tại).
if [ -f "/app/scripts/patch_add_submission_files.py" ]; then
  echo "Seeding submission files (idempotent)..."
  python /app/scripts/patch_add_submission_files.py || echo "Seed submission files failed (non-fatal)"
fi

echo "Starting uvicorn on 0.0.0.0:$PORT"
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
