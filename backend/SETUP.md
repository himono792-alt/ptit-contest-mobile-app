# SETUP Guide — Backend Local Dev (WSL2 + Ubuntu)

Hướng dẫn 1 mình bạn setup từ A-Z, **không cần đến hàng giờ**. Chia 3 phần:

- **Phần A** (~10 phút): Setup PostgreSQL trong WSL2 Ubuntu
- **Phần B** (~5 phút): Setup Python venv + cài backend
- **Phần C** (~2 phút): Test thử /docs

---

## Phần A. PostgreSQL trong WSL2 Ubuntu

### A.1. Mở WSL2 Ubuntu

Trong PowerShell hoặc Windows Terminal:

```powershell
wsl -d Ubuntu
```

Nếu chưa có Ubuntu, cài bằng lệnh:
```powershell
wsl --install -d Ubuntu-24.04
```

(Setup user + password lần đầu nếu được hỏi.)

### A.2. Enable systemd trong WSL (1 lần duy nhất, để Postgres tự khởi động)

Trong WSL Ubuntu shell:

```bash
# Check systemd đã enable chưa
[ "$(systemctl is-system-running 2>/dev/null || echo no)" = "running" ] && echo "Systemd OK" || echo "Cần enable"
```

Nếu in ra "Cần enable":

```bash
sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true
EOF
exit
```

Sau đó về PowerShell chạy `wsl --shutdown`, mở lại WSL.

### A.3. Cài PostgreSQL

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Verify:
```bash
sudo -u postgres psql -c "SELECT version();"
```

Nếu output có "PostgreSQL 16.x" hoặc tương tự → OK.

### A.4. Tạo DB + user

```bash
sudo -u postgres psql <<EOF
CREATE USER ptit_contest WITH PASSWORD 'dev_password';
CREATE DATABASE ptit_contest_db OWNER ptit_contest;
GRANT ALL PRIVILEGES ON DATABASE ptit_contest_db TO ptit_contest;
EOF
```

### A.5. Cho phép user `ptit_contest` connect bằng password qua TCP

Postgres mặc định trên Ubuntu chỉ trust local Unix socket. Cần chỉnh để asyncpg (driver Python) connect được qua `localhost:5432` với password.

```bash
# Tìm version Postgres
PG_VER=$(ls /etc/postgresql/ | head -1)
sudo nano /etc/postgresql/$PG_VER/main/pg_hba.conf
```

Trong file, tìm dòng:
```
host    all             all             127.0.0.1/32            scram-sha-256
```

Đảm bảo có dòng này (thường mặc định đã có). Nếu thấy `peer` hoặc `ident`, đổi thành `scram-sha-256` hoặc `md5`.

Save (Ctrl+O, Enter, Ctrl+X), restart Postgres:

```bash
sudo systemctl restart postgresql
```

Verify connect được:
```bash
PGPASSWORD=dev_password psql -h localhost -U ptit_contest -d ptit_contest_db -c "SELECT current_user;"
```

Output phải là `ptit_contest` → OK.

### A.6. Apply schema v03

File schema nằm trong workspace Windows, WSL truy cập qua `/mnt/e/...`:

```bash
cd /mnt/e/PARA/10-projects/12-cnpm-project
PGPASSWORD=dev_password psql -h localhost -U ptit_contest -d ptit_contest_db \
  -f database/2026-05-06_sqlapp_v04.sql
```

Bạn sẽ thấy nhiều dòng `CREATE TYPE`, `CREATE TABLE`, `CREATE INDEX`. Cuối cùng nếu không có `ERROR` đỏ → OK.

Verify:
```bash
PGPASSWORD=dev_password psql -h localhost -U ptit_contest -d ptit_contest_db \
  -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='ptit_contest';"
```

Phải ra `43`.

---

## Phần B. Python venv + Backend

### B.1. Verify Python 3.11+

```bash
python3 --version
```

Nếu Python 3.10 hoặc cũ hơn:
```bash
sudo apt install -y python3.12 python3.12-venv python3.12-dev
alias python3=python3.12
```

### B.2. Tạo venv + cài deps

```bash
cd /mnt/e/PARA/10-projects/12-cnpm-project/backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -e ".[dev]"
```

(Cài hết deps mất ~2-3 phút. Nếu báo lỗi `psycopg2`, không cần lo — dự án dùng `asyncpg` không cần `psycopg2`.)

### B.3. Cấu hình `.env`

```bash
cp .env.example .env

# Generate JWT secret random
python -c "import secrets; print('JWT_SECRET_KEY='+secrets.token_urlsafe(32))" >> .env

# Mở .env và verify
nano .env
```

Đảm bảo `DATABASE_URL` đúng:
```
DATABASE_URL=postgresql+asyncpg://ptit_contest:dev_password@localhost:5432/ptit_contest_db
```

### B.4. Stamp Alembic baseline

Vì schema đã apply trực tiếp từ SQL file (Phần A.6), cần đánh dấu Alembic biết là DB đã ở "head" rồi (không cần migration nào):

```bash
alembic stamp head
```

Output:
```
INFO  [alembic.runtime.migration] Stamping version XXX → head
```

(Lúc này `alembic/versions/` đang rỗng nên stamp head = stamp về null. Sau này khi sửa model + autogenerate migration đầu tiên, alembic sẽ track từ đây.)

---

## Phần C. Run server + test

### C.1. Start uvicorn

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Output:
```
🚀 PTIT Contest API starting in development mode
   DB: localhost:5432/ptit_contest_db
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### C.2. Mở Swagger UI

Trong browser Windows (WSL2 forwards localhost tự động):

→ **http://localhost:8000/api/docs**

Bạn sẽ thấy 6 endpoint đã implement:
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `GET /api/contests`
- `GET /api/contests/{slug}`

### C.3. Test nhanh

**Test health:**
```bash
curl http://localhost:8000/health
# {"status":"ok","app":"PTIT Contest API","env":"development"}
```

**Test list contests (rỗng vì DB chưa có data):**
```bash
curl http://localhost:8000/api/contests
# {"items":[],"total":0,"page":1,"size":20}
```

**Test register sẽ fail** vì `student_directory` chưa có data:
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"student_code":"B22DCCN001","email":"b22dccn001@ptit.edu.vn","full_name":"Test","password":"<your-demo-password>"}'
# {"detail":"MSSV 'B22DCCN001' không tồn tại trong danh mục SV PTIT"}
```

→ Đây là **expected behavior**. Cần seed data trước (xem section D bên dưới).

---

## D. Seed sample data (recommend làm tiếp)

Để test register/login thật, cần insert ít nhất 1 row vào `faculties` + `student_directory`:

```bash
PGPASSWORD=dev_password psql -h localhost -U ptit_contest -d ptit_contest_db <<EOF
SET search_path TO ptit_contest, public;

INSERT INTO faculties (faculty_code, faculty_name) VALUES
('CNTT', 'Công nghệ thông tin');

INSERT INTO student_directory (student_code, ptit_email, full_name, faculty_id, is_active) VALUES
('B22DCCN001', 'b22dccn001@ptit.edu.vn', 'Nguyễn Văn A',
 (SELECT faculty_id FROM faculties WHERE faculty_code='CNTT'), TRUE);
EOF
```

Giờ test register thành công:
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"student_code":"B22DCCN001","email":"b22dccn001@ptit.edu.vn","full_name":"Nguyễn Văn A","password":"<your-demo-password>"}' | python -m json.tool
```

Output có `user_id`, `email`, `roles: ["STUDENT"]` → OK.

Login để lấy token:
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"b22dccn001@ptit.edu.vn","password":"<your-demo-password>"}'
```

Lấy `access_token` từ response, thử endpoint `/me`:
```bash
TOKEN="<paste access_token>"
curl http://localhost:8000/api/auth/me -H "Authorization: Bearer $TOKEN"
```

---

## Troubleshoot common issues

### "could not connect to server: Connection refused"
- Postgres chưa start: `sudo systemctl start postgresql`
- Port 5432 bị app khác dùng: `sudo ss -tlnp | grep 5432`

### "FATAL: password authentication failed for user 'ptit_contest'"
- Sai password trong `.env` → check lại
- pg_hba.conf chưa đổi từ `peer`/`ident` sang `scram-sha-256` → xem A.5

### "pydantic_core._pydantic_core.ValidationError: ... DATABASE_URL"
- File `.env` chưa có hoặc đặt sai chỗ → phải ở `backend/.env`
- venv chưa activate: `source .venv/bin/activate`

### Swagger UI không mở được từ Windows browser
- WSL2 mặc định forward localhost. Nếu vẫn không mở, check IP WSL:
  ```bash
  hostname -I
  ```
  Mở `http://<WSL-IP>:8000/api/docs` thay vì localhost.

### Schema apply báo lỗi "schema ptit_contest already exists"
- Script v03 có `DROP SCHEMA IF EXISTS ptit_contest CASCADE` ở đầu, nên chạy lại được. Nếu vẫn lỗi, drop manual:
  ```bash
  PGPASSWORD=dev_password psql -h localhost -U ptit_contest -d ptit_contest_db \
    -c "DROP SCHEMA IF EXISTS ptit_contest CASCADE;"
  ```
  Rồi chạy lại schema.

### Alembic báo "Can't locate revision identified by 'head'"
- `alembic/versions/` đang rỗng nên không có "head". Bỏ qua `alembic stamp head` cho đến khi tạo migration đầu tiên bằng `alembic revision --autogenerate -m "initial"`.

---

## Tổng kết

Sau khi hoàn tất:
- ✅ Postgres chạy trong WSL2 Ubuntu
- ✅ Schema 43 bảng đã apply
- ✅ Python venv với backend deps
- ✅ FastAPI server chạy port 8000
- ✅ Swagger UI mở được tại http://localhost:8000/api/docs

Bước tiếp theo (do mình tự đi):
- Thêm sample data đầy đủ hơn (xem section D + có thể request tôi gen `seed_data.sql`)
- Implement nốt 24 endpoint còn lại theo roadmap trong README.md (mỗi lần làm 1 phase)
