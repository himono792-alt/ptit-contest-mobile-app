#!/usr/bin/env bash
# =========================================================
# PTIT Contest Backend — One-shot dev setup script
# Usage: bash scripts/setup-dev.sh
# Chạy từ thư mục backend/ bên trong WSL2 Ubuntu.
# =========================================================

set -e  # exit on error

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Config (override bằng env var nếu cần)
DB_NAME="${DB_NAME:-ptit_contest_db}"
DB_USER="${DB_USER:-ptit_contest}"
DB_PASS="${DB_PASS:-dev_password}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Đường dẫn schema (giả định chạy từ backend/)
SCHEMA_FILE="../database/2026-05-06_sqlapp_v04.sql"

# =====================
# 1. Check prereqs
# =====================
log "Checking prerequisites..."

command -v python3 >/dev/null || error "Python 3 chưa cài. sudo apt install python3 python3-venv"
command -v sudo    >/dev/null || error "Cần sudo để cài Postgres"
# psql sẽ tự cài kèm postgresql-contrib ở bước 2, không check trước

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
log "Python version: $PY_VER"

# =====================
# 2. Install Postgres (idempotent)
# =====================
if ! command -v postgres >/dev/null; then
    log "Installing PostgreSQL..."
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
else
    log "PostgreSQL đã cài"
fi

# Start postgres
if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
    log "PostgreSQL đang chạy"
else
    log "Starting PostgreSQL..."
    sudo systemctl start postgresql 2>/dev/null || sudo service postgresql start
fi

# =====================
# 3. Create DB + user (idempotent)
# =====================
log "Setting up DB user '$DB_USER' + database '$DB_NAME'..."

sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename='$DB_USER'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" >/dev/null

log "DB user + database OK"

# =====================
# 4. Verify TCP password connect
# =====================
log "Testing TCP connection..."
if ! PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" >/dev/null 2>&1; then
    warn "TCP connect failed. Có thể pg_hba.conf cần đổi sang scram-sha-256."
    warn "Mở: sudo nano /etc/postgresql/\$(ls /etc/postgresql)/main/pg_hba.conf"
    warn "Đảm bảo dòng 'host all all 127.0.0.1/32 scram-sha-256' tồn tại."
    warn "Sau đó: sudo systemctl restart postgresql"
    exit 1
fi
log "TCP connect OK"

# =====================
# 5. Apply schema v03
# =====================
if [ ! -f "$SCHEMA_FILE" ]; then
    error "Không tìm thấy $SCHEMA_FILE. Chạy script từ thư mục backend/?"
fi

log "Applying schema v03 (drop + recreate ptit_contest)..."
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -q -f "$SCHEMA_FILE" >/dev/null

TABLE_COUNT=$(PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tAc \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema='ptit_contest';")
[ "$TABLE_COUNT" = "43" ] || error "Schema apply lỗi. Mong đợi 43 bảng, có $TABLE_COUNT."
log "Schema applied: $TABLE_COUNT tables"

# =====================
# 6. Setup Python venv
# =====================
if [ ! -d ".venv" ]; then
    log "Creating Python venv..."
    python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

log "Installing backend dependencies (mất ~2 phút)..."
pip install --upgrade pip --quiet
pip install -e ".[dev]" --quiet

# =====================
# 7. Configure .env
# =====================
if [ ! -f ".env" ]; then
    log "Creating .env from template..."
    cp .env.example .env
    JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    sed -i "s|JWT_SECRET_KEY=.*|JWT_SECRET_KEY=$JWT_SECRET|" .env
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql+asyncpg://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME|" .env
    log ".env created with random JWT secret"
else
    warn ".env đã tồn tại — không ghi đè"
fi

# =====================
# 8. Stamp Alembic baseline (skip nếu chưa có version)
# =====================
if [ "$(ls alembic/versions/*.py 2>/dev/null | wc -l)" -gt 0 ]; then
    log "Stamping Alembic head..."
    alembic stamp head
else
    warn "Bỏ qua alembic stamp (chưa có migration trong alembic/versions/)"
    warn "Sau này khi tạo migration đầu tiên: alembic revision --autogenerate -m 'initial'"
fi

# =====================
# 9. Optional: seed minimal data
# =====================
log "Seeding minimal sample data (1 faculty + 1 student in directory)..."
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -q <<SEEDEOF
SET search_path TO ptit_contest, public;
INSERT INTO faculties (faculty_code, faculty_name) VALUES ('CNTT', 'Công nghệ thông tin')
  ON CONFLICT (faculty_code) DO NOTHING;
INSERT INTO student_directory (student_code, ptit_email, full_name, faculty_id, is_active)
  VALUES ('B22DCCN001', 'b22dccn001@ptit.edu.vn', 'Nguyễn Văn A',
          (SELECT faculty_id FROM faculties WHERE faculty_code='CNTT'), TRUE)
  ON CONFLICT (student_code) DO NOTHING;
SEEDEOF
log "Seed data OK (B22DCCN001 trong directory)"

# =====================
# Done
# =====================
echo ""
echo "================================================================"
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo "================================================================"
echo ""
echo "Chạy server:"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo "Mở browser: http://localhost:8000/api/docs"
echo ""
echo "Test register sample user:"
echo "  curl -X POST http://localhost:8000/api/auth/register \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"student_code\":\"B22DCCN001\",\"email\":\"b22dccn001@ptit.edu.vn\",\"full_name\":\"Nguyen Van A\",\"password\":\"<your-demo-password>\"}'"
echo ""
