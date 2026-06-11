# Checklist tắt production cloud — 2026-06-11

> Làm đúng thứ tự: **backup trước, xóa sau**. Repo đã dọn xong (CHANGELOG v1.1) — chỉ còn các bước dashboard dưới đây. Ước tính 20 phút.

## Bước 1 — Backup DB Railway (5 phút) ⚠️ LÀM ĐẦU TIÊN

1. Railway dashboard → project → service **Postgres** → tab **Connect** → copy **Public URL** (dạng `postgresql://postgres:...@...railway.app:.../railway`)
2. PowerShell tại root repo (dùng Docker, không cần cài pg_dump):

```powershell
docker run --rm -v ${PWD}\archive:/backup postgres:16-alpine `
  pg_dump "<DATABASE_PUBLIC_URL>" -f /backup/prod-final-dump-2026-06-11.sql
# Verify: file phải vài trăm KB+
Get-Item archive\prod-final-dump-2026-06-11.sql | Select-Object Length
Get-Content archive\prod-final-dump-2026-06-11.sql -Head 5
```

## Bước 2 — Backup R2 (nếu cần file bài nộp thật)

Cloudflare dashboard → **R2** → bucket `ptit-contest-submissions` → xem danh sách object. Ít file: tải tay từng cái về `archive\r2-files\`. Nếu bucket chỉ có file test (61B) → bỏ qua.

## Bước 3 — Tắt Railway (thứ duy nhất tốn tiền)

- [ ] Service **backend** → Settings → **Delete Service**
- [ ] Service **Postgres** → Settings → **Delete Service** (⚠️ chỉ sau khi Bước 1 verify OK)
- [ ] Hoặc xóa cả **Project** một phát → Settings → Danger → Delete Project
- [ ] Check tab **Usage/Billing** xác nhận không còn service chạy

## Bước 4 — Xóa Cloudflare Pages

- [ ] Dashboard → **Workers & Pages** → `ptit-contest-app` → Settings → **Delete project**

## Bước 5 — Xóa R2 bucket

- [ ] Bucket → xóa hết objects (bucket phải rỗng) → Settings → **Delete bucket**
- [ ] R2 → Manage API tokens → revoke token của backend

## Bước 6 — Sentry + Brevo (free, làm cho sạch)

- [ ] Sentry → Settings → Projects → `ptit-contest-flutter` (FE) → Delete; project BE tương tự
- [ ] Brevo → Settings → **SMTP & API** → API Keys → delete key

## Bước 7 — Rebuild Docker với code mới (bắt buộc)

Repo vừa đổi `config.py` + `main.py` + compose (FRONTEND_BASE_URL, QR verify URL) → image cũ chưa có:

```powershell
# (chạy tại root repo)
docker compose down -v        # reset volume để seed lại config QR mới
docker compose up -d --build
# Verify QR config đã trỏ local (qua DBGate http://localhost:4224):
#   SELECT config_value FROM ptit_contest.system_configs WHERE config_key='certificate.qr_verify_url_base';
#   → kỳ vọng: http://localhost:8080/verify/
```

## (Option) Restore data production vào Docker

Muốn demo bằng data thật thay seed: sau `down -v` + `up -d` đợi postgres healthy rồi:

```powershell
docker compose stop backend   # tránh seed đè
Get-Content archive\prod-final-dump-2026-06-11.sql -Raw |
  docker exec -i ptit-contest-postgres-1 psql -U ptit_contest -d ptit_contest_db
docker compose start backend
```

> Lưu ý: dump prod có user password thật (bcrypt) — login bằng tài khoản thật, không phải `abc123`.

## Bước 8 — Commit

```powershell
git add -A
git commit -m "chore(v1.1): ngung production cloud - chuyen Docker local (FRONTEND_BASE_URL, QR verify, docs)"
git push origin main
```
