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
    echo "Alembic stamp baseline..."
    alembic stamp head
    echo "Alembic baseline stamped"
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

# Optional seed users (chỉ chạy nếu chưa có user nào)
USER_COUNT=$(psql "$PSQL_URL" -tAc "SELECT COUNT(*) FROM ptit_contest.app_users;" 2>/dev/null || echo "0")
if [ "$USER_COUNT" = "0" ] && [ -f "/app/scripts/seed-users.sh" ]; then
  echo "DB trống — seed users..."
  sh scripts/seed-users.sh || echo "Seed failed (non-fatal)"
fi

echo "Starting uvicorn on 0.0.0.0:$PORT"
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
