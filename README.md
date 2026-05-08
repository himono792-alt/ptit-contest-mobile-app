# PTIT Contest — Hệ thống quản lý cuộc thi sinh viên

[![Backend](https://img.shields.io/badge/backend-FastAPI-009688?logo=fastapi&logoColor=white)](https://ptit-contest-mobile-app-production.up.railway.app/api/docs)
[![Frontend](https://img.shields.io/badge/frontend-Flutter%203.27-02569B?logo=flutter&logoColor=white)](https://ptit-contest-app.pages.dev)
[![Database](https://img.shields.io/badge/database-PostgreSQL-336791?logo=postgresql&logoColor=white)](08-database/)
[![Status](https://img.shields.io/badge/status-v1.0%20production-success)](#trạng-thái)

Đề tài Công nghệ phần mềm (CNPM) HK2 2026 — Học viện Công nghệ Bưu chính Viễn thông (PTIT). Hệ thống full-stack quản lý cuộc thi sinh viên với 4 vai trò: Sinh viên / GV BTC / BCN khoa / Quản trị, workflow phê duyệt 3 cấp, deploy production thực tế (Railway BE + Cloudflare Pages FE + APK Android).

---

## Truy cập nhanh

| Resource | URL |
|----------|-----|
| **Web app (production)** | https://ptit-contest-app.pages.dev |
| **API (Swagger UI)** | https://ptit-contest-mobile-app-production.up.railway.app/api/docs |
| **Backend repo** | [`09-implementation/backend/`](09-implementation/backend/) |
| **Frontend repo** | [`09-implementation/frontend/`](09-implementation/frontend/) |
| **Báo cáo CNPM** | [`11-docs/2026-05-07_bao-cao-cnpm_v02.md`](11-docs/2026-05-07_bao-cao-cnpm_v02.md) |

**Tài khoản demo** (password chung `abc123`):
- `b22dccn001@ptit.edu.vn` — Sinh viên
- `gv@ptit.edu.vn` — GV/BTC (JUDGE + ORGANIZER)
- `bcn@ptit.edu.vn` — Ban Chủ nhiệm khoa (HOD)
- `admin@ptit.edu.vn` — Quản trị

---

## Trạng thái

| Hạng mục | v1.0 (2026-05-08) |
|----------|-------------------|
| Backend FastAPI | **104 endpoints** qua 16 router · 43 SQLAlchemy models · 25 bảng PostgreSQL |
| Frontend Flutter | **30+ screens** responsive web/mobile · APK Android 25.9 MB |
| 4 actor end-to-end | ✅ SV / GV-BTC / BCN-HOD / Admin (strict role separation Sprint 15) |
| Workflow phê duyệt 3 cấp | ✅ QĐ1 (BCN duyệt contest) · QĐ2 (BCN duyệt kết quả) · QĐ3 (BCN duyệt cert template) |
| Production foundation | ✅ Sentry FE+BE · Rate limit · Refresh token · Email Brevo HTTP · HSTS A+ · R2 file storage |
| WCAG 2.1 AA | ✅ Touch ≥44dp · Reduce-motion · Skeleton loading · Semantics deep wrap (axe-core 0 violations) |
| Light + Dark theme | ✅ Material 3 · 484 theme tokens · OKLCH 9-stop brand ramp |
| Biometric login (APK) | ✅ FaceID/TouchID + refresh token rotation |
| Workflow Sprint 13-19 | ✅ 14 hotfix UX iterate sidebar collapsible Pattern B (VS Code/Sentry style) |

**Production URL deploy cuối**: `a3f6a20e.ptit-contest-app.pages.dev` (alias `ptit-contest-app.pages.dev`)

---

## Tính năng chính

### Sinh viên
- Đăng nhập qua password / OTP 6-box / biometric (APK) / SSO PTIT (Coming soon)
- Onboarding 3 slides lần đầu mở app
- Khám phá cuộc thi — search, filter, hero "SỰ KIỆN NỔI BẬT"
- Đăng ký cá nhân hoặc theo team với leader assignment
- Submit bài làm (text/link/file ≤10MB upload R2) + countdown timer hết hạn
- Theo dõi tiến độ "Của tôi" với progress bar 5 stage (Chờ duyệt → Đã đăng ký → Đang dự thi → Đã kết thúc)
- Bảng xếp hạng podium top-3 (gold/silver/bronze) + table rank với "BẠN" highlight
- Nhận chứng nhận điện tử có QR verify
- Profile achievement stats (Cuộc thi / Giải thưởng / Chứng nhận)
- Notifications time-bucket (Hôm nay / Tuần này / Cũ hơn)

### GV / Ban tổ chức
- Tạo contest 3 chế độ INDIVIDUAL/TEAM/HYBRID
- Quản lý rounds + sessions + scoring criteria
- Submit BCN duyệt (QĐ1) trước khi mở đăng ký
- Phê duyệt entries cá nhân/team
- Assign judges + Open/Blind judging
- Chấm điểm với hero card "Hôm nay cần chấm" + filter scored vs unscored
- Compute results + submit BCN duyệt (QĐ2) + publish
- Activate cert template + cấp cert hàng loạt
- Export Excel báo cáo cuộc thi

### Ban Chủ nhiệm khoa (BCN)
- Phê duyệt 3 lane: Đề xuất cuộc thi (QĐ1) / Kết quả cuộc thi (QĐ2) / Cert template (QĐ3)
- Bulk approve entries (productivity ~30x)
- Giám sát tiến độ contest realtime
- Approve/reject với note + revision request

### Quản trị
- Quản lý user + role assignment
- Quản lý faculty/major/class master data
- Cấu hình hệ thống (system_configs)
- Backup & Restore database
- Audit log với filter user/action/contest/time range
- Anomaly detection report
- Bình luận moderation
- System health monitor (API/DB/R2)
- Export báo cáo tổng hệ thống xlsx

---

## Tech stack

### Backend (`09-implementation/backend/`)
- **Python 3.11+** · **FastAPI** · **SQLAlchemy 2.0 async** · **asyncpg**
- **PostgreSQL 14+** · **Alembic** baseline migration
- **Pydantic v2** · **JWT HS256** + refresh token rotation · **bcrypt**
- **Sentry** error tracking · **Brevo HTTP API** email · **Cloudflare R2** S3-compat object storage
- **slowapi** rate limit · **openpyxl** xlsx export
- Deploy: Railway auto via git push, Dockerfile cache-friendly

### Frontend (`09-implementation/frontend/`)
- **Flutter 3.27** · **Dart 3.6** · **Material 3** + 484 theme tokens
- **Riverpod 2.6** state · **Dio** HTTP · **GoRouter** navigation
- **Sentry FE** error tracking · **Shimmer** skeleton loading
- **local_auth** biometric (APK only) · **shared_preferences** persist UI state
- **google_fonts** Plus Jakarta Sans + JetBrains Mono · **intl** date format
- Deploy web: Cloudflare Pages manual via `build_deploy.ps1` (wrangler)
- Deploy mobile: APK Android local `flutter build apk` (KGP 2.2.0 + AGP 8 + Java 17)

### Database (`08-database/`)
- PostgreSQL schema `ptit_contest` — 25 bảng + 17 ENUM types
- ER diagram Mermaid: `2026-05-04_er-diagram_v02.mermaid`
- Schema SQL: `2026-05-04_sqlapp_v03.sql`

---

## Cấu trúc folder

```
12-cnpm-project/
├── README.md                    ← file này (overview)
├── 01-research/                 ← user research, persona, competitor analysis
├── 02-requirements/             ← traceability matrix v02 (104 endpoints + UI mapping)
├── 03-information-architecture/ ← workflow phê duyệt 3 cấp QĐ1+QĐ2+QĐ3
├── 04-wireframes/               ← low-fi sketches
├── 05-mockups/                  ← high-fi UI screens (4 HTML actor + React JSX 8350 dòng)
├── 06-design-system/            ← style guide + UI-UX Pro Max skill
├── 07-prototypes/               ← interactive prototypes
├── 08-database/                 ← schema SQL v03 + ER diagram Mermaid
├── 09-implementation/           ← code production
│   ├── backend/                 ← FastAPI + SQLAlchemy (104 endpoints)
│   └── frontend/                ← Flutter web + APK (30+ screens)
├── 10-testing/                  ← test cases + audit reports
├── 11-docs/                     ← báo cáo CNPM + audit reports + design audit
├── assets/                      ← shared logo, fonts
└── docs/                        ← biên bản họp + decision log
```

---

## Lịch sử Sprint (highlights)

| Phase | Sprint | Highlights |
|-------|--------|------------|
| Foundation | Phase 1 | Sentry · Rate limit · Refresh token · Email Brevo · HSTS A+ |
| Quick wins | Phase 2 Sprint 1 | Notification deep-link · Bulk approve · Excel export · Biometric · Skeleton |
| UX audit + tokens | Phase A + B + C | 4 token files · 24/24 screen audit · WCAG 0 violations |
| Audit + fix | Sprint 8-12 | DB/BE/FE smoke test · 11 bug fix · 6 endpoint mới wire UI · contest stats |
| Design folder | Sprint 13-18 | 14 items P1+P2+P3 từ design mockup · 2 endpoint mới (rounds + leaderboard) |
| Login redesign | Sprint 19 | Web 2-column branding · Onboarding 3 slides · OTP 6-box · Sidebar collapsible Pattern B (VS Code/Sentry style) |

Chi tiết từng sprint xem **báo cáo CNPM v02**: [`11-docs/2026-05-07_bao-cao-cnpm_v02.md`](11-docs/2026-05-07_bao-cao-cnpm_v02.md) (~1500 dòng).

---

## Setup local dev

### Backend

```bash
cd 09-implementation/backend
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env         # Sửa DATABASE_URL + JWT_SECRET_KEY

# Tạo DB + apply schema v03
psql -U postgres -c "CREATE DATABASE ptit_contest_db;"
psql -U postgres -d ptit_contest_db -f ../../08-database/2026-05-04_sqlapp_v03.sql
alembic stamp head

# Seed test users
python scripts/seed-test-users.py

# Run dev
uvicorn app.main:app --reload --port 8000
```

→ http://localhost:8000/api/docs

### Frontend

```bash
cd 09-implementation/frontend
flutter pub get

# Run web dev
flutter run -d chrome \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app

# Build production web (Cloudflare Pages)
./build_deploy.ps1   # PowerShell Windows

# Build APK Android
flutter build apk --release \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app
```

---

## Triển khai (deployment)

| Layer | Platform | Method | Frequency |
|-------|----------|--------|-----------|
| **Backend** | Railway | Git push → auto deploy | Mỗi khi merge BE diff |
| **Frontend Web** | Cloudflare Pages | `wrangler pages deploy` qua `build_deploy.ps1` | Mỗi khi merge FE diff |
| **APK Android** | Local file | `flutter build apk --release` | Theo release schedule |

Order: Backend trước → Frontend sau (FE phụ thuộc API mới của BE) → APK cuối.

---

## Naming convention

`YYYY-MM-DD_chu-de_v01.ext`

- kebab-case, không dấu tiếng Việt, không khoảng trắng
- Version `v01..v10` (KHÔNG `_FINAL`/`_revised`)
- Folder prefix số `01-`..`11-`

---

## Liên kết tham chiếu

- **Báo cáo CNPM**: [`11-docs/2026-05-07_bao-cao-cnpm_v02.md`](11-docs/2026-05-07_bao-cao-cnpm_v02.md) — đầy đủ chương 1-6 (~1500 dòng, 25 sprint)
- **Traceability matrix**: [`02-requirements/2026-05-04_traceability-matrix_v02.md`](02-requirements/) — 104 endpoint mapping với UI screens
- **Workflow approval 3 cấp**: [`03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`](03-information-architecture/)
- **Audit reports**: [`11-docs/audit-report-2026-05-06.md`](11-docs/audit-report-2026-05-06.md) · [`design-audit-2026-05-06.md`](11-docs/design-audit-2026-05-06.md) · [`a11y-baseline-2026-05-07.md`](11-docs/a11y-baseline-2026-05-07.md)

---

## Tác giả

Đồ án CNPM HK2 2026 — PTIT.

**Notion**: https://www.notion.so/35678677fb3d8150b200ca56be5a67e0
