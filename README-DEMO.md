# Chạy demo PTIT Contest trên máy (clone-and-run)

Hướng dẫn này dành cho người chấm/giáo viên: chỉ cần **Docker Desktop**, clone repo về là chạy được toàn bộ hệ thống (Frontend + Backend + Database) ngay trên máy, **không phụ thuộc server online**. Một lệnh `docker compose up` dựng cả 3 lớp — **PostgreSQL chạy chung trong cùng dự án**, tự khởi tạo schema và nạp dữ liệu, không cần cài đặt DB riêng. Dữ liệu mẫu phong phú (4 vai trò + 5 khoa + 6 cuộc thi gồm cả cuộc thi đã kết thúc có chứng nhận & bảng xếp hạng + workflow phê duyệt) được tạo sẵn — không phải tự nhập gì.

## 1. Yêu cầu

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS/Linux), đang chạy.
- Có mạng Internet **trong lúc build lần đầu** (Docker tải image PostgreSQL + Flutter SDK). Sau khi build xong thì chạy không cần mạng.

## 2. Chạy

```bash
cd 09-implementation
docker compose up -d --build
```

Lần đầu build mất khoảng **10–20 phút** (chủ yếu tải Flutter SDK để build web). Các lần sau khởi động chỉ vài giây.

Theo dõi tiến trình:

```bash
docker compose logs -f
```

## 3. Truy cập

| Thành phần | Địa chỉ |
|---|---|
| Giao diện web (Frontend) | http://localhost:8080 |
| API + tài liệu Swagger (Backend) | http://localhost:8000/api/docs |
| Health check Backend | http://localhost:8000/health |
| **DBGate — xem DB trên trình duyệt (dbgate)** | http://localhost:4224 (vào thẳng, connection "PTIT Contest DB" có sẵn) |
| **DBX — xem DB trên trình duyệt (dbx)** | http://localhost:4225 (access password `abc123`, tạo connection 1 lần) |
| PostgreSQL (kết nối bằng client) | localhost:5432 (user/pass: `ptit_contest` / `dev_password`) |

## 4. Tài khoản đăng nhập

Tất cả tài khoản dùng chung mật khẩu **`abc123`**.

| Vai trò | Email | Thấy được gì |
|---|---|---|
| Sinh viên | `b22dccn001@ptit.edu.vn` (và `002`, `003`) | Cuộc thi đang diễn ra, đăng ký, bài nộp, thông báo |
| Giảng viên / BTC | `gv@ptit.edu.vn` | Quản lý cuộc thi, có 1 bài nộp đã khoá để chấm |
| BCN khoa (Trưởng khoa) | `bcn@ptit.edu.vn` | Hàng đợi phê duyệt — có 1 đề xuất chờ duyệt QĐ1 |
| Quản trị (Admin) | `admin@ptit.edu.vn` | Quản trị tài khoản + cấu hình hệ thống |

## 5. Dữ liệu mẫu có sẵn

Dữ liệu được nạp qua **2 lớp seed chạy nối tiếp** (xem mục 5a). Sau khi `up`, hệ thống có sẵn:

**Master data**
- **5 khoa:** Công nghệ thông tin (CNTT), An toàn thông tin (ATTT) + Điện tử viễn thông (DTVT), Quản lý kỹ thuật (QLKT), Kỹ thuật điện tử (KTDT).
- **6 ngành + 8 lớp**, **~17 sinh viên** rải khắp các khoa, **3 giám khảo** (`gv@`, `gv2@`, `gv3@`).

**6 cuộc thi đủ trạng thái** (đủ cho mọi màn hình của 4 vai trò):
- **A — "Lập trình thuật toán 2026"** (cá nhân, *đang diễn ra*): 2 lượt đăng ký đã duyệt + 1 bài nộp đã khoá → đăng nhập GV để chấm; có sẵn **Q&A** trên cuộc thi.
- **B — "Hackathon Sáng tạo 2026"** (đội, *đang đề xuất*): 1 đề nghị phê duyệt QĐ1 đang chờ → đăng nhập BCN để duyệt, demo trọn **workflow phê duyệt 2 cấp BTC ↔ BCN**.
- **"Lập trình Web 2025"** (cá nhân, *đã kết thúc*): 8 thí sinh, đầy đủ điểm → kết quả → **chứng nhận top 3** + **bảng xếp hạng**.
- **"Olympic Toán Tin 2024"** (cá nhân, *đã kết thúc*): 6 thí sinh, có kết quả + chứng nhận.
- **"Hackathon IoT Kết Nối"** (đội — 4 đội × 3 SV, *đã kết thúc*): chứng nhận cấp theo đội.
- **1 cuộc thi sắp tới** (đã publish / *đang mở đăng ký*) để SV thấy danh sách phong phú.

**Dữ liệu phụ trợ:** chuỗi chấm điểm đầy đủ (tiêu chí → phân công giám khảo → điểm → kết quả vòng → kết quả cuộc thi → cấp chứng nhận), **3 mẫu chứng nhận cấp khoa** (màn BCN), **10 đánh giá sao** từ SV, **4 bài viết/tin tức**, **6 cấu hình hệ thống**, **20 dòng nhật ký kiểm toán (audit log)**, và thông báo mẫu cho SV + BCN.

### 5a. Cơ chế seed (2 lớp, idempotent)

`docker-entrypoint.sh` tự gọi lần lượt mỗi lần boot:

1. **`seed-demo.py`** — bộ dữ liệu nền tối thiểu (4 vai trò + cuộc thi A & B + thông báo).
2. **`seed-rich.py`** — *làm giàu* trên nền seed-demo (3 khoa thêm, 14 SV, 3 cuộc thi đã kết thúc có chứng nhận/bảng xếp hạng, cuộc thi sắp mở, đánh giá/Q&A/bài viết/audit). **Phải chạy sau** vì phụ thuộc các tài khoản nền (`gv@`/`bcn@`/`admin@`/`B22DCCN001`).

> Cả hai script **idempotent** (guard theo slug/email/unique key) → chạy lại mỗi lần khởi động không nhân đôi dữ liệu, và **non-fatal** → nếu một bước seed lỗi, backend vẫn khởi động. Mật khẩu lấy từ biến môi trường `DEMO_PASSWORD` trong `docker-compose.yml` (mặc định `abc123`). Muốn nạp lại từ đầu: `docker compose down -v` rồi `up`.

### 5b. PostgreSQL chạy chung trong Docker (không cần cài DB riêng)

Database **nằm trong cùng `docker-compose.yml` của dự án** — không phải cài PostgreSQL hay tạo schema thủ công. Một lệnh `docker compose up` là có cả DB:

- **Service `postgres`** dùng image `postgres:16-alpine`, dữ liệu lưu ở volume `pg_data` (giữ qua các lần `down`). Tài khoản DB: `ptit_contest` / `dev_password`, database `ptit_contest_db`, cổng `5432`. Kết nối bằng client ngoài (DBeaver/psql/pgAdmin): `postgresql://ptit_contest:dev_password@localhost:5432/ptit_contest_db`.
Có **2 phương án xem DB trên trình duyệt** (chạy song song, chọn cái nào tùy thích):

- **Service `dbgate` (DBGate — `dbgate/dbgate`) — cổng 4224, khuyên dùng** — mở http://localhost:4224 là **vào thẳng** (đã `SKIP_ALL_AUTH`, không hỏi đăng nhập). Connection **"PTIT Contest DB"** khai báo sẵn qua env trong `docker-compose.yml` (`SERVER_pg1=postgres` · `USER_pg1=ptit_contest` · `PASSWORD_pg1=dev_password` · `PORT_pg1=5432`) nên **tự có sẵn trên mọi máy**, không cần tạo tay. Lịch sử query lưu ở volume `dbgate_data`.

- **Service `dbx` (DBX — `t8y2/dbx`) — cổng 4225** — mở http://localhost:4225, đăng nhập bằng access password **`abc123`** (env `DBX_PASSWORD`). DBX không nhận connection qua env nên **tạo connection 1 lần** trong UI (lưu vĩnh viễn ở volume `dbx_data`): chọn **PostgreSQL**, `Host=postgres` · `Port=5432` · `User=ptit_contest` · `Password=dev_password` · `Database=ptit_contest_db` → Test → Save.

> Cả hai đều dùng `Host=postgres` (tên service, qua mạng nội bộ Docker — **không** phải `localhost`). Không cần dùng cả hai; nếu chỉ muốn 1 cái, có thể bỏ service kia trong `docker-compose.yml`.
- **Backend tự khởi tạo schema** — `docker-compose.yml` **không mount file SQL** vào postgres (tránh 2 nguồn schema lệch nhau). Thay vào đó `docker-entrypoint.sh` của backend lo toàn bộ, theo thứ tự:
  1. Đợi `postgres` *healthy* (qua `depends_on: condition: service_healthy` + `pg_isready`) rồi mới chạy.
  2. **DB trống** → nạp `init-schema.sql` (**v04**) → `alembic stamp 0001_baseline_v04` → `alembic upgrade head`. Stamp baseline **rồi** upgrade để các migration sau baseline (vd `0002_faculty_cert_templates`, **không** nằm trong init-schema) thực sự được apply — trước đây stamp thẳng `head` làm DB mới thiếu bảng `faculty_cert_templates` (màn BCN "Mẫu chứng nhận" lỗi).
  3. **DB cũ có schema nhưng chưa track Alembic** → `alembic stamp head`.
  4. **DB đã track Alembic** → `alembic upgrade head` (apply migration còn thiếu).
  5. Chạy seed 2 lớp (mục 5a) rồi `uvicorn`.
- **Cấu hình DB qua env** trong service `backend` của compose: `DATABASE_URL` (trỏ tới service `postgres` qua mạng nội bộ Docker), `DEMO_PASSWORD`, `JWT_SECRET_KEY`, `CORS_ORIGINS`. Entrypoint tự đổi `postgresql://` → `postgresql+asyncpg://` cho SQLAlchemy async.

> Tóm lại: cài Docker xong, DB lên **cùng dự án** trong một lệnh — schema + migration + dữ liệu đều tự động, không thao tác tay.

## 6. Dừng / Khởi động lại / Reset

```bash
docker compose stop           # tạm dừng
docker compose up -d          # chạy lại (không build lại)
docker compose down           # dừng + xoá container (giữ dữ liệu)
docker compose down -v        # dừng + xoá luôn dữ liệu → lần up sau seed lại từ đầu
```

## 7. Xem trên điện thoại cùng WiFi (tuỳ chọn)

```bash
# Lấy IP máy (Windows): ipconfig | findstr IPv4
docker compose build --build-arg API_BASE=http://<IP-máy>:8000 frontend
docker compose up -d
# Điện thoại mở: http://<IP-máy>:8080
```

## 8. Khắc phục sự cố

- **Build lâu / treo ở bước Flutter:** bình thường ở lần đầu (tải SDK vài GB). Cứ chờ; xem `docker compose logs -f frontend`.
- **Cổng 8080/8000/5432 đang bận:** đổi cổng bên trái dấu `:` trong mục `ports` của `docker-compose.yml` (ví dụ `8081:80`).
- **Không đăng nhập được / dữ liệu trống:** chạy `docker compose logs backend` xem 2 dòng `Seeding demo data...` và `Seeding RICH demo data...`. Seed là *non-fatal* nên nếu một bước lỗi log sẽ in `Seed ... failed (non-fatal)` mà backend vẫn chạy — đọc log để biết bước nào lỗi. Cần làm sạch: `docker compose down -v` rồi `docker compose up -d`.
- **Backend chưa sẵn sàng:** backend đợi PostgreSQL khoẻ rồi mới khởi tạo schema + seed; chờ ~10–20 giây sau khi container backend start.
