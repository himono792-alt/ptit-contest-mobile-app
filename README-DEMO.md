# Chạy demo PTIT Contest trên máy (clone-and-run)

Hướng dẫn này dành cho người chấm/giáo viên: chỉ cần **Docker Desktop**, clone repo về là chạy được toàn bộ hệ thống (Frontend + Backend + Database) ngay trên máy, **không phụ thuộc server online**. Dữ liệu mẫu (4 vai trò + 2 cuộc thi + workflow phê duyệt) được tạo sẵn — không phải tự nhập gì.

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
| PostgreSQL | localhost:5432 (user/pass: `ptit_contest` / `dev_password`) |

## 4. Tài khoản đăng nhập

Tất cả tài khoản dùng chung mật khẩu **`abc123`**.

| Vai trò | Email | Thấy được gì |
|---|---|---|
| Sinh viên | `b22dccn001@ptit.edu.vn` (và `002`, `003`) | Cuộc thi đang diễn ra, đăng ký, bài nộp, thông báo |
| Giảng viên / BTC | `gv@ptit.edu.vn` | Quản lý cuộc thi, có 1 bài nộp đã khoá để chấm |
| BCN khoa (Trưởng khoa) | `bcn@ptit.edu.vn` | Hàng đợi phê duyệt — có 1 đề xuất chờ duyệt QĐ1 |
| Quản trị (Admin) | `admin@ptit.edu.vn` | Quản trị tài khoản + cấu hình hệ thống |

## 5. Dữ liệu mẫu có sẵn

- **2 khoa:** Công nghệ thông tin (CNTT), An toàn thông tin (ATTT).
- **Cuộc thi A — "Lập trình thuật toán 2026"** (cá nhân, đang diễn ra): 2 lượt đăng ký đã duyệt + 1 bài nộp đã khoá → đăng nhập GV để chấm.
- **Cuộc thi B — "Hackathon Sáng tạo 2026"** (đội, đang đề xuất): 1 đề nghị phê duyệt QĐ1 đang chờ → đăng nhập BCN để duyệt, demo trọn **workflow phê duyệt 2 cấp BTC ↔ BCN**.
- Thông báo mẫu cho sinh viên và BCN.

> Dữ liệu được seed tự động mỗi lần khởi động và **idempotent** (chạy lại không nhân đôi). Mật khẩu lấy từ biến môi trường `DEMO_PASSWORD` trong `docker-compose.yml` (mặc định `abc123`).

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
- **Không đăng nhập được / dữ liệu trống:** chạy `docker compose logs backend` xem dòng `Seeding demo data...`. Nếu cần làm sạch: `docker compose down -v` rồi `docker compose up -d`.
- **Backend chưa sẵn sàng:** backend đợi PostgreSQL khoẻ rồi mới khởi tạo schema + seed; chờ ~10–20 giây sau khi container backend start.
