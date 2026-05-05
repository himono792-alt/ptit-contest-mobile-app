#!/bin/sh
# Entry point cho container backend.
# - Đợi DB ready
# - Init schema từ raw SQL nếu chưa có bảng
# - Seed users (Admin/GV/BCN/SV) lần đầu
# - Start uvicorn

set -e

PORT="${PORT:-8000}"

echo "PTIT Contest Backend starting..."
echo "  PORT=$PORT"
echo "  DATABASE_URL=${DATABASE_URL:0:40}..."

# Parse DATABASE_URL để psql có thể connect
# DATABASE_URL: postgresql+asyncpg://user:pass@host:port/db
# Convert sang psql format: postgresql://user:pass@host:port/db
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

# Check schema đã init chưa (kiểm tra bảng app_users tồn tại trong schema ptit_contest)
SCHEMA_EXISTS=$(psql "$PSQL_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='ptit_contest' AND table_name='app_users' LIMIT 1;" 2>/dev/null || echo "")

if [ -z "$SCHEMA_EXISTS" ]; then
  echo "Schema chưa tồn tại — init từ raw SQL..."
  if [ -f "/app/init-schema.sql" ]; then
    psql "$PSQL_URL" -f /app/init-schema.sql
    echo "Schema init done"
  else
    echo "WARN: /app/init-schema.sql không tồn tại — skip init"
  fi
else
  echo "Schema đã tồn tại — skip init"
fi

# Optional seed users (chỉ chạy nếu chưa có user nào)
USER_COUNT=$(psql "$PSQL_URL" -tAc "SELECT COUNT(*) FROM ptit_contest.app_users;" 2>/dev/null || echo "0")
if [ "$USER_COUNT" = "0" ] && [ -f "/app/scripts/seed-users.sh" ]; then
  echo "DB trống — seed users..."
  cd /app && sh scripts/seed-users.sh || echo "Seed failed (non-fatal)"
fi

echo "Starting uvicorn on 0.0.0.0:$PORT"
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
