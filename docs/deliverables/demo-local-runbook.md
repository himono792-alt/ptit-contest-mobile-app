# Runbook demo local Docker — buổi bảo vệ

> In 1 trang. Toàn bộ hệ thống chạy offline trên máy, không phụ thuộc mạng/server.

## 1. Trước buổi demo (làm 1 lần, ~5 phút)

```powershell
# Docker Desktop đang chạy (icon cá voi xanh), rồi:
cd E:\PARA\10-projects\12-cnpm-project
docker compose up -d          # lần đầu build ~5-10 phút, các lần sau ~30s
docker compose ps             # đợi 5 container đều (healthy) / running
```

Mở thử **http://localhost:8080** → thấy màn login là sẵn sàng. Demo xong: `docker compose down` (giữ data) .

## 2. Địa chỉ

| Gì | URL |
|---|---|
| **Web app** | http://localhost:8080 |
| API Swagger | http://localhost:8000/api/docs |
| Xem DB — DBGate (vào thẳng) | http://localhost:4224 |
| Xem DB — DBX (password `abc123`) | http://localhost:4225 |
| Postgres client | `localhost:5432` — `ptit_contest` / `dev_password` |

## 3. Tài khoản — mật khẩu chung `abc123` (click tab role ở màn login là tự điền)

| Vai trò | Email | Demo gì |
|---|---|---|
| Sinh viên | `b22dccn001@ptit.edu.vn` (cả `002`, `003`) | Đăng ký thi, nộp bài, cert, leaderboard |
| GV / BTC | `gv@ptit.edu.vn` | Tạo + quản lý cuộc thi, chấm bài (có 1 bài đã khóa chờ chấm) |
| BCN khoa | `bcn@ptit.edu.vn` | Hàng đợi phê duyệt (có sẵn 1 đề xuất chờ QĐ1) |
| Admin | `admin@ptit.edu.vn` | Tài khoản, cấu hình, audit log |

## 4. Kịch bản 5 phút (theo workflow phê duyệt 2 cấp BTC↔BCN)

1. **SV** login → Home dashboard → cuộc thi *"Lập trình thuật toán 2026"* đang diễn ra → xem Chứng nhận + Leaderboard cuộc thi đã kết thúc (🥇 podium).
2. **GV/BTC** → dashboard hero "hôm nay chấm" → vào bài nộp đã khóa → chấm điểm → tạo/sửa cuộc thi → gửi đề xuất lên BCN.
3. **BCN** → dashboard queue SLA → duyệt đề xuất QĐ1 đang chờ → Giám sát + thống kê khoa (donut hiệu suất).
4. **Admin** → quản lý tài khoản → System Health + Audit log → cấu hình.
5. Chốt: mở **DBGate :4224** cho thầy xem data thật trong Postgres (bảng `contests`, `submissions`).

## 5. Lệnh nhanh khi đang demo

```powershell
docker compose logs -f backend    # xem log API; OTP email hiện Ở ĐÂY (mode console)
docker compose restart backend    # backend đơ
docker compose down -v && docker compose up -d   # RESET data về mẫu ban đầu
```

## 6. Sự cố thường gặp

| Triệu chứng | Xử lý |
|---|---|
| Port 8080/8000/5432 bận | Tắt app chiếm port hoặc sửa port trái trong `docker-compose.yml` rồi `up -d` lại |
| Container `(unhealthy)` lúc mới up | Đợi 30–60s (backend chờ Postgres + seed); xem `logs -f backend` |
| Login sai dù `abc123` | Seed chưa chạy xong — xem logs có dòng `Seeding demo data` |
| Cần OTP email | Không gửi thật — đọc trong `logs -f backend` |
| Demo trên iPhone cùng WiFi | `ipconfig` lấy IP → `docker compose build --build-arg API_BASE=http://<IP>:8000 frontend` → `up -d` → iPhone mở `http://<IP>:8080` |

## 7. Nếu thầy hỏi "khác production chỗ nào?"

Code **không đổi** — chỉ env: DB là container Postgres; file nộp lưu BYTEA trong DB (từng dùng Cloudflare R2); email mode console (từng dùng Brevo API); Sentry tắt. Hệ thống **từng deploy production thật** (Railway + Cloudflare Pages, 05–06/2026, HSTS A+, Sentry, R2) — đã chủ động ngừng sau khi hoàn thành để chuyển sang bản Docker tự chứa, bằng chứng deploy trong báo cáo chương 4 + CHANGELOG.
