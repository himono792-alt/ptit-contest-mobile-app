# Lộ trình triển khai dự án CNPM — PTIT Contest Management

**Phiên bản:** v01
**Ngày tạo:** 2026-05-04
**Dự án:** Ứng dụng di động quản lý cuộc thi sinh viên PTIT
**Môn:** Công nghệ phần mềm (CNPM) — HK2 2026
**Stack:** Ubuntu Server 24.04 LTS + FastAPI + PostgreSQL + Nginx + systemd (backend) | Flutter (mobile)

---

## Mục lục

- [0. Tổng quan & nguyên tắc làm việc](#0-tổng-quan--nguyên-tắc-làm-việc)
- [Module 1 — Khởi động dự án (Project Kickoff)](#module-1--khởi-động-dự-án-project-kickoff)
- [Module 2 — Nghiên cứu & phân tích yêu cầu](#module-2--nghiên-cứu--phân-tích-yêu-cầu)
- [Module 3 — Thiết kế kiến trúc thông tin (IA) & user flow](#module-3--thiết-kế-kiến-trúc-thông-tin-ia--user-flow)
- [Module 4 — Wireframe & Mockup UI](#module-4--wireframe--mockup-ui)
- [Module 5 — Design System](#module-5--design-system)
- [Module 6 — Thiết kế database](#module-6--thiết-kế-database)
- [Module 7 — Thiết kế kiến trúc backend & API contract](#module-7--thiết-kế-kiến-trúc-backend--api-contract)
- [Module 8 — Setup môi trường dev](#module-8--setup-môi-trường-dev)
- [Module 9 — Implement Backend (FastAPI)](#module-9--implement-backend-fastapi)
- [Module 10 — Implement Mobile App (Flutter)](#module-10--implement-mobile-app-flutter)
- [Module 11 — Tích hợp End-to-End](#module-11--tích-hợp-end-to-end)
- [Module 12 — Testing & QA](#module-12--testing--qa)
- [Module 13 — Triển khai local (Docker / Nginx / systemd)](#module-13--triển-khai-local-docker--nginx--systemd)
- [Module 14 — Documentation & báo cáo](#module-14--documentation--báo-cáo)
- [Module 15 — Chuẩn bị bảo vệ & demo](#module-15--chuẩn-bị-bảo-vệ--demo)
- [Timeline tổng hợp 12 tuần](#timeline-tổng-hợp-12-tuần)
- [Checklist deliverables cuối kỳ](#checklist-deliverables-cuối-kỳ)
- [Rủi ro & phương án dự phòng](#rủi-ro--phương-án-dự-phòng)

---

## 0. Tổng quan & nguyên tắc làm việc

**Mục tiêu cuối:** Hoàn thiện 1 hệ thống gồm (1) mobile app cho sinh viên đăng ký/tham gia cuộc thi, (2) cổng web quản trị cho Ban Tổ Chức (BTC), (3) backend API + database, đủ để demo offline và viết báo cáo môn học.

**Phạm vi:** Test offline 100%. Không deploy production thật, không thuê SMS gateway/cloud, không tích hợp thanh toán. Toàn bộ stack chạy local trên 1 máy (qua WSL2).

**Nguyên tắc:**
1. **Mỗi file đặt tên theo convention** `YYYY-MM-DD_chu-de_v01.ext` (kebab-case, không dấu).
2. **Versioning thay vì ghi đè** — sửa file đã có → tăng `v01` → `v02`.
3. **Mỗi module = 1 deliverable cụ thể** lưu vào subfolder tương ứng (xem README.md).
4. **Commit nhỏ, sớm, thường xuyên** — mỗi pull request 1 chức năng đơn lẻ.
5. **Decision log** ghi lại mọi quyết định công nghệ trong `docs/` để báo cáo có thể trích dẫn.

**Vai trò gợi ý (4-5 thành viên):**

| Vai trò | Trách nhiệm chính |
|---|---|
| **Team Lead / PM** | Lên kế hoạch, theo dõi tiến độ, viết báo cáo |
| **UX/UI Designer** | Wireframe, mockup, design system |
| **Backend Dev** | FastAPI, PostgreSQL, API design |
| **Mobile Dev** | Flutter app, tích hợp API |
| **QA / DevOps** | Test cases, Docker, deploy, demo |

> Trong nhóm nhỏ, 1 người có thể đảm nhiệm 2 vai trò (vd PM kiêm QA).

---

## Module 1 — Khởi động dự án (Project Kickoff)

**Thời gian:** Tuần 1 (3-5 ngày)
**Lưu vào folder:** `docs/`, `01-research/`

### Mục tiêu
- Cả nhóm hiểu chung về phạm vi, mục tiêu, deadline
- Phân vai rõ ràng, có công cụ giao tiếp
- Có roadmap chính thức được nhóm phê duyệt

### Việc làm cụ thể

1. **Họp kickoff** — chốt phạm vi đề tài với nhóm
   - Output: `docs/2026-MM-DD_bien-ban-hop-kickoff_v01.md`
2. **Phân vai** — bảng RACI (Responsible/Accountable/Consulted/Informed)
   - Output: `docs/2026-MM-DD_phan-vai-team_v01.md`
3. **Setup công cụ team:**
   - Git repo (GitHub private repo) — mọi người clone về
   - Notion/Trello board theo dõi task
   - Group chat (Zalo/Discord) cho daily sync
4. **Đọc và hiểu lộ trình này** — file bạn đang đọc
5. **Schedule định kỳ:**
   - Daily standup 15 phút (online)
   - Weekly review thứ 7 — review tiến độ, plan tuần sau

### Deliverables
- [ ] Biên bản họp kickoff
- [ ] Bảng phân vai
- [ ] Git repo đã setup, mọi người clone được
- [ ] Lịch họp định kỳ

---

## Module 2 — Nghiên cứu & phân tích yêu cầu

**Thời gian:** Tuần 1-2 (1 tuần)
**Lưu vào folder:** `01-research/`, `02-requirements/`

### Mục tiêu
- Hiểu rõ user (sinh viên PTIT, BTC) cần gì
- Có tài liệu yêu cầu chi tiết để dev cứ nhìn vào đó mà code

### Việc làm cụ thể

1. **User research** (`01-research/`)
   - Phỏng vấn 3-5 sinh viên: họ tham gia cuộc thi gì, đăng ký kiểu gì, pain point gì?
   - Phỏng vấn 1-2 BTC cũ (CLB/Đoàn): họ tổ chức ra sao, dùng tool gì?
   - Output: `2026-MM-DD_user-interview-summary_v01.md`
2. **Persona** (`01-research/`)
   - Persona 1: Sinh viên năm nhất (newbie, ít kinh nghiệm)
   - Persona 2: Sinh viên năm 3 (đã quen, tham gia nhiều cuộc thi)
   - Persona 3: Trưởng BTC CLB
   - Output: `2026-MM-DD_persona-sv-ptit_v01.md`
3. **Competitor analysis** (`01-research/`)
   - Khảo sát 3-5 app tương tự (Devpost, HackerEarth, một số app sự kiện VN)
   - Output: `2026-MM-DD_competitor-analysis_v01.docx`
4. **Functional requirements** (`02-requirements/`)
   - Liệt kê chi tiết tính năng từng vai trò (sinh viên, BTC, admin)
   - Đã có file: `2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx` — review và update lên `v02` nếu cần
5. **Use case & user story** (`02-requirements/`)
   - Use case diagram (UML) cho các flow chính
   - User story dạng: "Là [vai trò], tôi muốn [chức năng] để [mục đích]"
   - Output: `2026-MM-DD_use-cases_v01.md`, `2026-MM-DD_user-stories_v01.md`
6. **Non-functional requirements** (`02-requirements/`)
   - Performance, bảo mật, khả năng mở rộng (cho báo cáo, dù demo offline)
   - Output: `2026-MM-DD_yeu-cau-phi-chuc-nang_v01.md`

### Deliverables
- [ ] User interview summary
- [ ] Persona document (≥2 personas)
- [ ] Competitor analysis
- [ ] Functional requirements (đầy đủ)
- [ ] Use case diagram + user stories
- [ ] Non-functional requirements

---

## Module 3 — Thiết kế kiến trúc thông tin (IA) & user flow

**Thời gian:** Tuần 2-3 (4-5 ngày)
**Lưu vào folder:** `03-information-architecture/`

### Mục tiêu
- Vẽ ra "bản đồ" toàn bộ app trước khi vào code
- Mỗi flow chính có sơ đồ rõ ràng

### Việc làm cụ thể

1. **Sitemap** — sơ đồ tổ chức tất cả màn hình
   - Output: `2026-MM-DD_sitemap_v01.png` (vẽ Figma/draw.io/Excalidraw)
2. **User flow chính:**
   - Flow đăng nhập sinh viên (mã 6 chữ số)
   - Flow đăng ký cuộc thi
   - Flow xem kết quả
   - Flow BTC tạo cuộc thi
   - Output: `2026-MM-DD_user-flow-{ten-flow}_v01.svg` (1 file/flow)
3. **Navigation pattern** — bottom tab? drawer? hierarchical?
   - Quyết định: **Bottom Tab** cho sinh viên (3-4 tab chính), **Drawer** cho BTC
   - Output: `2026-MM-DD_navigation-pattern_v01.md`

### Công cụ
- Figma (free tier đủ dùng)
- draw.io / Excalidraw (free, browser-based)
- Whimsical (đẹp, có miễn phí)

### Deliverables
- [ ] Sitemap toàn app
- [ ] ≥4 user flow diagram
- [ ] Navigation pattern decision document

---

## Module 4 — Wireframe & Mockup UI

**Thời gian:** Tuần 3-4 (1-1.5 tuần)
**Lưu vào folder:** `04-wireframes/`, `05-mockups/`

### Mục tiêu
- Có UI cuối cùng đã được nhóm + giáo viên duyệt trước khi code
- Mỗi màn hình có file mockup để mobile dev cứ nhìn mà làm

### Việc làm cụ thể

1. **Wireframe (low-fi)** — chỉ bố cục, không màu (`04-wireframes/`)
   - Vẽ tất cả màn hình ở mức skeleton (hộp vuông, text placeholder)
   - Tool: Balsamiq, Figma low-fi, hoặc vẽ tay scan
   - Output: `2026-MM-DD_wireframe-{ten-man-hinh}_v01.png`
2. **Review wireframe** với cả nhóm, sửa cho đến khi đồng thuận
3. **Mockup (high-fi)** — đầy đủ màu, font, icon (`05-mockups/`)
   - Đã có: `2026-05-03_mockup_v01.html` (bản HTML hiện tại)
   - Update lên Figma → export PNG cho từng màn hình
   - Output: `2026-MM-DD_mockup-{ten-man-hinh}_v01.png`
4. **Mockup Figma file** (master file)
   - Output: `2026-MM-DD_mockup-master_v01.fig`
5. **Review với "user thử" 2-3 người** — cho họ nhìn mockup, hỏi "anh/chị hiểu màn này làm gì?"

### Màn hình tối thiểu cần làm
- Splash
- Onboarding (Chào mừng)
- Nhập mã 6 chữ số (Login)
- Contest Hub (danh sách cuộc thi)
- Chi tiết cuộc thi
- Trang cá nhân sinh viên
- Cổng BTC: Dashboard
- Cổng BTC: Tạo/Sửa cuộc thi
- Cổng BTC: Quản lý người tham gia

### Deliverables
- [ ] Wireframe đầy đủ các màn hình
- [ ] Mockup high-fi đầy đủ các màn hình
- [ ] File master Figma chia sẻ với nhóm

---

## Module 5 — Design System

**Thời gian:** Tuần 4 (3-4 ngày, làm song song với Module 4 cuối)
**Lưu vào folder:** `06-design-system/`

### Mục tiêu
- Có "ngôn ngữ thiết kế" thống nhất, mobile dev không cần đoán màu/size

### Việc làm cụ thể

1. **Color palette** — primary, secondary, semantic (success/error/warning/info)
   - Output: `2026-MM-DD_color-palette_v01.png` + bản `.md` ghi mã hex
2. **Typography** — font family, scale (h1, h2, body, caption), weight
   - Output: `2026-MM-DD_typography_v01.md`
3. **Spacing scale** — 4 / 8 / 16 / 24 / 32 / 48 (chuẩn 8pt grid)
   - Output: `2026-MM-DD_spacing_v01.md`
4. **Components spec** — button, input, card, modal, bottom-nav, OTP input
   - Mỗi component có các state: default, hover, pressed, disabled
   - Output: `2026-MM-DD_components-spec_v01.fig` + bản `.md` mô tả
5. **Icon set** — chọn 1 bộ icon (Material Icons / Phosphor / Lucide)
   - Output: list trong `2026-MM-DD_icon-set_v01.md`

### Deliverables
- [ ] Color palette với mã hex
- [ ] Typography scale
- [ ] Spacing scale
- [ ] Components specification
- [ ] Icon set chốt

---

## Module 6 — Thiết kế database

**Thời gian:** Tuần 2-3 (làm song song Module 3-4)
**Lưu vào folder:** `08-database/`

### Mục tiêu
- Schema PostgreSQL hoàn chỉnh, có ER diagram, sẵn sàng cho backend

### Việc làm cụ thể

1. **Review schema hiện tại** — `2026-05-03_sqlapp_v01.txt`
2. **Bổ sung table còn thiếu** dựa trên user story Module 2:
   - `users` (sinh viên, BTC, admin)
   - `contests` (cuộc thi)
   - `participants` (đăng ký tham gia)
   - `submissions` (nộp bài)
   - `results` (kết quả/điểm)
   - `auth_codes` (mã 6 chữ số tạm thời)
3. **ER diagram** — vẽ bằng dbdiagram.io hoặc DBeaver
   - Output: `2026-MM-DD_er-diagram_v01.png`
4. **Sample data** (seed) — script INSERT 20-30 sinh viên, 5-10 cuộc thi
   - Output: `2026-MM-DD_seed-data_v01.sql`
5. **Migration scripts** — chia DDL thành các migration nhỏ (Alembic format nếu dùng)
   - Output: `migrations/0001_initial.sql`, `0002_add_results.sql`, ...
6. **Schema final v02** — ghi đè/bổ sung lên `v01`
   - Output: `2026-MM-DD_schema_v02.sql`

### Deliverables
- [ ] Schema SQL final
- [ ] ER diagram
- [ ] Seed data script
- [ ] Migration files

---

## Module 7 — Thiết kế kiến trúc backend & API contract

**Thời gian:** Tuần 3 (3-5 ngày)
**Lưu vào folder:** `09-implementation/backend/docs/` (sẽ tạo)

### Mục tiêu
- Có sơ đồ kiến trúc + danh sách endpoint trước khi code

### Việc làm cụ thể

1. **Sơ đồ kiến trúc tổng** (`docs/`)
   - Mobile (Flutter) ↔ Nginx (port 80) ↔ FastAPI/Uvicorn (port 8000) ↔ PostgreSQL (port 5432)
   - Tool: draw.io
   - Output: `docs/2026-MM-DD_architecture-diagram_v01.png`
2. **API contract (OpenAPI spec)** — liệt kê endpoint trước khi code
   - `POST /auth/request-code` — sinh viên yêu cầu mã đăng nhập
   - `POST /auth/verify-code` — verify mã, trả JWT
   - `GET /contests` — list cuộc thi
   - `GET /contests/{id}` — chi tiết
   - `POST /contests/{id}/register` — đăng ký
   - `POST /contests/{id}/submissions` — nộp bài
   - `GET /me` — profile
   - `GET /admin/contests` — BTC list (auth admin)
   - `POST /admin/contests` — BTC tạo
   - ...
   - Output: `docs/2026-MM-DD_api-spec_v01.yaml` (OpenAPI 3.0)
3. **Cấu trúc folder backend** (sẽ thực hiện ở Module 9):

```
09-implementation/backend/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── db/
│   │   ├── session.py
│   │   └── models.py
│   ├── routers/
│   │   ├── auth.py
│   │   ├── contests.py
│   │   ├── submissions.py
│   │   └── admin.py
│   ├── schemas/        # Pydantic models
│   ├── services/       # business logic
│   └── deps.py         # dependencies (auth, db session)
├── tests/
├── alembic/            # migrations
├── requirements.txt
├── Dockerfile
└── .env.example
```

### Deliverables
- [ ] Architecture diagram
- [ ] OpenAPI spec đầy đủ
- [ ] Cấu trúc folder backend đã thống nhất

---

## Module 8 — Setup môi trường dev

**Thời gian:** Tuần 4 (2-3 ngày, làm song song Module 5)
**Lưu vào folder:** `docs/`

### Mục tiêu
- Mọi thành viên có môi trường dev giống nhau, chạy được "Hello World" backend + mobile

### Việc làm cụ thể

1. **Hướng dẫn cài WSL2 + Ubuntu 24.04** — viết doc cho cả nhóm
2. **Cài PostgreSQL trong WSL2:**
   ```bash
   sudo apt install postgresql-16
   sudo systemctl start postgresql
   sudo -u postgres createdb ptit_contest
   ```
3. **Cài Python 3.12 + tạo venv cho FastAPI**
4. **Cài Flutter SDK** — Windows hay WSL2 đều được, dev mobile thường Windows tiện hơn (dùng emulator/device USB)
5. **Cài Android Studio** (cho emulator + cài Android SDK)
6. **Cài Git, VS Code, các extension cần thiết:**
   - Python, Pylance, Black Formatter
   - Flutter, Dart
   - PostgreSQL, REST Client
7. **Viết script setup tự động** (bash script chạy được toàn bộ trên máy mới)
8. **Document hướng dẫn:**
   - Output: `docs/2026-MM-DD_setup-dev-environment_v01.md`

### Deliverables
- [ ] Document hướng dẫn cài đặt từ A-Z
- [ ] Script setup tự động (optional)
- [ ] Mọi thành viên xác nhận chạy được Hello World cả 2 phía

---

## Module 9 — Implement Backend (FastAPI)

**Thời gian:** Tuần 4-7 (3-3.5 tuần)
**Lưu vào folder:** `09-implementation/backend/`

### Mục tiêu
- Backend hoàn thiện, đáp ứng đầy đủ API contract Module 7

### Việc làm cụ thể (theo thứ tự)

#### 9.1 — Bootstrap project (1-2 ngày)
- `fastapi`, `uvicorn`, `sqlalchemy`, `alembic`, `psycopg2-binary`, `pydantic-settings`, `python-jose` (JWT), `passlib`
- Setup config qua `.env` (DB URL, JWT secret)
- Hello World endpoint: `GET /health`

#### 9.2 — Database layer (2-3 ngày)
- Models SQLAlchemy khớp schema Module 6
- Alembic migration đầu tiên
- Seed script

#### 9.3 — Auth (2-3 ngày)
- `POST /auth/request-code` — generate mã 6 chữ số, lưu DB với expiry 5 phút
- `POST /auth/verify-code` — verify, trả JWT
- Middleware/dependency `get_current_user`

#### 9.4 — Contest endpoints (3-4 ngày)
- CRUD contest cho BTC
- List/detail cho sinh viên
- Register/unregister

#### 9.5 — Submission endpoints (2-3 ngày)
- Upload file submission (lưu local filesystem hoặc S3 fake)
- List submission của user, của contest

#### 9.6 — Admin/BTC features (2-3 ngày)
- Quản lý người tham gia
- Cập nhật kết quả
- Dashboard data

#### 9.7 — Validation, error handling, logging (1-2 ngày)
- Pydantic validators chi tiết
- Custom exception handler
- Logging với `structlog` hoặc Python logging

#### 9.8 — Unit test với pytest (2-3 ngày, làm xen kẽ)
- Test mỗi router ít nhất 2 case (happy + error)
- Coverage tối thiểu 60%

### Deliverables
- [ ] Toàn bộ endpoint hoạt động qua Swagger UI (`/docs`)
- [ ] Migration chạy clean trên DB mới
- [ ] Seed data có sẵn
- [ ] Unit test pass

---

## Module 10 — Implement Mobile App (Flutter)

**Thời gian:** Tuần 5-9 (4-4.5 tuần, làm song song Module 9 từ tuần 5)
**Lưu vào folder:** `09-implementation/mobile/`

### Mục tiêu
- Mobile app đầy đủ tính năng theo mockup, gọi được tất cả API backend

### Việc làm cụ thể

#### 10.1 — Bootstrap project (1-2 ngày)
- `flutter create ptit_contest_app`
- Cài dependencies trong `pubspec.yaml`:
  - `dio` (HTTP client)
  - `riverpod` hoặc `bloc` (state management)
  - `go_router` (navigation)
  - `flutter_secure_storage` (lưu JWT)
  - `intl` (i18n, format ngày)
  - `freezed` + `json_serializable` (model)
- Cấu trúc folder:
  ```
  lib/
  ├── main.dart
  ├── app/                 # router, theme
  ├── core/                # constants, utils, http client
  ├── features/
  │   ├── auth/
  │   ├── contests/
  │   ├── submissions/
  │   └── admin/
  └── shared/              # widgets dùng chung
  ```

#### 10.2 — Theme & design system (1-2 ngày)
- Implement color, typography, spacing từ Module 5 vào `ThemeData`
- Custom widget cơ bản: PrimaryButton, AppTextField, OtpInput, ContestCard

#### 10.3 — Auth flow (3-4 ngày)
- Splash screen
- Onboarding/Chào mừng
- Nhập mã 6 chữ số (gọi `/auth/verify-code`)
- Lưu JWT vào secure storage
- Auto-login nếu JWT còn hạn

#### 10.4 — Contest list & detail (3-4 ngày)
- Contest Hub với bottom tab
- Pull-to-refresh
- Chi tiết cuộc thi
- Đăng ký/hủy đăng ký

#### 10.5 — Submission flow (3-4 ngày)
- Form nộp bài
- Upload file
- List bài đã nộp

#### 10.6 — Profile (2 ngày)
- Trang cá nhân
- Lịch sử cuộc thi đã tham gia
- Logout

#### 10.7 — Cổng BTC (mobile) hoặc web (3-5 ngày)
- **Lựa chọn:** Flutter cũng build được web → có thể làm portal BTC bằng Flutter Web (cùng codebase, share code)
- Hoặc: Làm 1 trang HTML đơn giản call API (nhanh hơn nếu deadline gấp)

#### 10.8 — Polish & UX (2-3 ngày)
- Loading state, error state cho mọi screen
- Empty state (chưa có cuộc thi nào...)
- Hint, helper text

### Deliverables
- [ ] App chạy được trên Android emulator + device thật
- [ ] Tất cả flow theo mockup hoạt động
- [ ] Build được APK release

---

## Module 11 — Tích hợp End-to-End

**Thời gian:** Tuần 9-10 (1 tuần)
**Lưu vào folder:** `10-testing/`

### Mục tiêu
- Mobile + backend chạy đồng bộ, không lỗi tích hợp

### Việc làm cụ thể

1. **Setup network giữa mobile và backend**
   - Mobile chạy device thật → kết nối Wi-Fi cùng mạng với laptop chạy backend
   - Lấy IP máy chạy backend (vd `192.168.1.10:8000`)
   - Config Flutter base URL = IP đó
2. **Test từng flow E2E:**
   - Login → vào Contest Hub → đăng ký → nộp bài → xem kết quả
   - BTC tạo cuộc thi → xuất hiện trên app sinh viên
3. **Fix lỗi tích hợp** — thường gặp:
   - CORS (FastAPI thêm `CORSMiddleware`)
   - Date format không khớp (chuẩn ISO 8601)
   - Field name camelCase vs snake_case
4. **Smoke test report** — output: `10-testing/2026-MM-DD_smoke-test-report_v01.md`

### Deliverables
- [ ] Tất cả flow E2E pass
- [ ] Smoke test report

---

## Module 12 — Testing & QA

**Thời gian:** Tuần 10-11 (1-1.5 tuần)
**Lưu vào folder:** `10-testing/`

### Mục tiêu
- Có đầy đủ tài liệu testing để nộp báo cáo

### Việc làm cụ thể

1. **Test cases (manual)** — bảng Excel, mỗi case có:
   - ID, Mô tả, Tiền điều kiện, Bước thực hiện, Kết quả mong đợi, Kết quả thực tế, Pass/Fail
   - Output: `2026-MM-DD_test-cases_v01.xlsx`
2. **Usability test** — cho 3-5 sinh viên dùng thử app
   - Ghi lại: họ làm task gì? Mất bao lâu? Bị lúng túng ở đâu?
   - Output: `2026-MM-DD_usability-test-report_v01.docx`
3. **Performance test cơ bản** — dùng `locust` hoặc `wrk` đo backend
   - 100 concurrent users, request `/contests` → đo latency
   - Output: `2026-MM-DD_performance-report_v01.md`
4. **Bug log** — track tất cả bug đã phát hiện và đã fix
   - Output: `2026-MM-DD_bug-log_v01.xlsx`

### Deliverables
- [ ] Test cases (≥30 case)
- [ ] Usability report
- [ ] Performance report
- [ ] Bug log

---

## Module 13 — Triển khai local (Docker / Nginx / systemd)

**Thời gian:** Tuần 11 (4-5 ngày)
**Lưu vào folder:** `09-implementation/deploy/`

### Mục tiêu
- Demo bằng 1 lệnh `docker compose up`, mô phỏng kiến trúc production-grade trong báo cáo

### Việc làm cụ thể

1. **Dockerfile cho FastAPI**
2. **Docker Compose** — gộp PostgreSQL + FastAPI + Nginx
   ```yaml
   services:
     db: postgres:16
     api: build ./backend
     nginx: nginx:alpine (reverse proxy 80 → api:8000)
   ```
3. **Nginx config** — reverse proxy + serve static (nếu có Flutter Web cho BTC)
4. **systemd unit file** (`ptit-contest.service`) — chạy mà không qua Docker
   - Mô tả trong báo cáo: "Hai phương án triển khai: Docker (recommended) hoặc systemd direct"
5. **Hướng dẫn deploy:**
   - Output: `09-implementation/deploy/2026-MM-DD_deploy-guide_v01.md`

### Deliverables
- [ ] `docker-compose.yml` chạy thành công
- [ ] Nginx config working
- [ ] systemd unit file
- [ ] Deploy guide

---

## Module 14 — Documentation & báo cáo

**Thời gian:** Tuần 11-12 (làm xen kẽ từ tuần 8)
**Lưu vào folder:** `docs/`

### Mục tiêu
- Báo cáo môn học đầy đủ, có thể nộp + thuyết trình

### Việc làm cụ thể

1. **Báo cáo chính (Word document)** — cấu trúc gợi ý:
   - Chương 1: Giới thiệu (mục đích, phạm vi, ý nghĩa)
   - Chương 2: Khảo sát hiện trạng & yêu cầu
   - Chương 3: Phân tích thiết kế (use case, sequence, class diagram, ERD)
   - Chương 4: Thiết kế kiến trúc & công nghệ (giải thích lý do chọn FastAPI/Flutter/PostgreSQL — có dẫn chứng từ research)
   - Chương 5: Cài đặt & triển khai
   - Chương 6: Kiểm thử
   - Chương 7: Kết luận & hướng phát triển
   - Output: `docs/2026-MM-DD_bao-cao-cuoi-ky_v01.docx`
2. **Decision log** — ghi mọi quyết định kỹ thuật quan trọng
   - Output: `docs/2026-MM-DD_decision-log_v01.md`
3. **README chính của project** — đã có, update theo tiến độ
4. **Hướng dẫn người dùng (User manual)** — cho người chấm bài có thể tự cài, tự chạy
   - Output: `docs/2026-MM-DD_user-manual_v01.docx`
5. **Báo cáo tiến độ tuần** — đã làm từ Module 1
   - `docs/2026-MM-DD_bao-cao-tien-do-tuan-{N}_v01.md`

### Deliverables
- [ ] Báo cáo chính (≥40 trang)
- [ ] Decision log
- [ ] User manual
- [ ] 12 bản báo cáo tiến độ tuần

---

## Module 15 — Chuẩn bị bảo vệ & demo

**Thời gian:** Tuần 12 (3-5 ngày cuối)
**Lưu vào folder:** `docs/`

### Mục tiêu
- Demo trơn tru, slide đẹp, trả lời được mọi câu hỏi giáo viên

### Việc làm cụ thể

1. **Slide thuyết trình** (PowerPoint, ~15-20 slide)
   - Outline: Vấn đề → Giải pháp → Demo → Công nghệ → Kết quả → Hướng phát triển
   - Output: `docs/2026-MM-DD_slide-bao-ve_v01.pptx`
2. **Kịch bản demo** — viết step-by-step:
   - Bước 1: Mở app, đăng nhập với mã `123456`
   - Bước 2: Vào Contest Hub, đăng ký cuộc thi "Hackathon PTIT 2026"
   - Bước 3: Mở cổng BTC, xem danh sách đăng ký mới
   - ...
   - Output: `docs/2026-MM-DD_kich-ban-demo_v01.md`
3. **Backup plan:**
   - Quay sẵn video demo phòng khi mạng/máy chết
   - Backup database + screenshot tất cả màn hình
4. **Tập demo nội bộ 2-3 lần** — đo thời gian, tinh chỉnh
5. **Q&A prep** — list 20 câu hỏi giáo viên có thể hỏi + sẵn câu trả lời
   - Output: `docs/2026-MM-DD_qa-prep_v01.md`

### Deliverables
- [ ] Slide thuyết trình
- [ ] Kịch bản demo + video backup
- [ ] Q&A prep
- [ ] Tập demo nội bộ ≥2 lần

---

## Timeline tổng hợp 12 tuần

```
Tuần │ 01 │ 02 │ 03 │ 04 │ 05 │ 06 │ 07 │ 08 │ 09 │ 10 │ 11 │ 12 │
─────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
M1   │ ██ │    │    │    │    │    │    │    │    │    │    │    │  Kickoff
M2   │ ██ │ ██ │    │    │    │    │    │    │    │    │    │    │  Research & Req
M3   │    │ ██ │ ██ │    │    │    │    │    │    │    │    │    │  IA & user flow
M4   │    │    │ ██ │ ██ │    │    │    │    │    │    │    │    │  Wireframe/Mockup
M5   │    │    │    │ ██ │    │    │    │    │    │    │    │    │  Design system
M6   │    │ ██ │ ██ │    │    │    │    │    │    │    │    │    │  Database
M7   │    │    │ ██ │    │    │    │    │    │    │    │    │    │  API contract
M8   │    │    │    │ ██ │    │    │    │    │    │    │    │    │  Setup dev env
M9   │    │    │    │ ██ │ ██ │ ██ │ ██ │    │    │    │    │    │  Backend impl
M10  │    │    │    │    │ ██ │ ██ │ ██ │ ██ │ ██ │    │    │    │  Mobile impl
M11  │    │    │    │    │    │    │    │    │ ██ │ ██ │    │    │  Tích hợp E2E
M12  │    │    │    │    │    │    │    │    │    │ ██ │ ██ │    │  Testing/QA
M13  │    │    │    │    │    │    │    │    │    │    │ ██ │    │  Deploy local
M14  │    │    │    │    │    │    │    │ ██ │ ██ │ ██ │ ██ │ ██ │  Documentation
M15  │    │    │    │    │    │    │    │    │    │    │    │ ██ │  Demo prep
```

**Buffer:** Mỗi module nên trừ thêm 20% thời gian cho bug, sửa chữa, họp ngoài ý muốn.

---

## Checklist deliverables cuối kỳ

### Code & sản phẩm
- [ ] Backend FastAPI chạy được, full API
- [ ] Mobile app Flutter (APK) chạy được trên Android
- [ ] Cổng BTC (Flutter Web hoặc HTML)
- [ ] Database schema + seed data
- [ ] Docker Compose chạy 1 lệnh

### Tài liệu thiết kế
- [ ] User research summary
- [ ] Persona (≥2)
- [ ] Functional + non-functional requirements
- [ ] Use case diagram + user stories
- [ ] Sitemap + user flow diagrams
- [ ] Wireframe + mockup đầy đủ
- [ ] Design system (color/typo/spacing/components)
- [ ] ER diagram
- [ ] Architecture diagram
- [ ] OpenAPI spec

### Tài liệu kiểm thử
- [ ] Test cases (≥30)
- [ ] Usability report
- [ ] Performance report
- [ ] Bug log

### Tài liệu báo cáo
- [ ] Báo cáo chính (≥40 trang)
- [ ] Decision log
- [ ] User manual
- [ ] 12 báo cáo tiến độ tuần
- [ ] Slide thuyết trình
- [ ] Kịch bản demo + video backup

---

## Rủi ro & phương án dự phòng

| Rủi ro | Xác suất | Tác động | Phương án dự phòng |
|---|---|---|---|
| Thành viên drop môn / bận đột xuất | Trung bình | Cao | Phân vai cross-functional, ai cũng có 1 backup; commit code thường xuyên |
| Flutter learning curve dốc hơn dự kiến | Trung bình | Trung bình | Dành tuần 4-5 chỉ để học + làm "Hello World" cẩn thận; có sẵn tutorial sample app |
| Mobile chưa kết nối được backend (CORS, IP) | Cao | Thấp | Test sớm từ tuần 6; dùng ngrok backup nếu mạng nội bộ chập chờn |
| Schema DB phải sửa lớn giữa kỳ | Trung bình | Cao | Migration via Alembic, không sửa tay; review schema kỹ ở Module 6 trước khi code |
| Deadline gấp, không kịp Cổng BTC | Trung bình | Trung bình | Cắt phạm vi: làm HTML đơn giản thay vì Flutter Web; nói rõ trong báo cáo "scope giới hạn" |
| Máy nhóm yếu, không chạy nổi emulator | Thấp | Trung bình | Dùng device Android thật qua USB; share 1 máy mạnh làm "build server" |
| Không có người test usability | Thấp | Thấp | Test với chính sinh viên trong khoa, ít nhất 3 người |
| Mất data do xóa nhầm | Thấp | Cao | Backup DB hàng tuần; Git push daily; dùng GitHub repo private |

---

## Phụ lục — Liên kết hữu ích

- **README dự án:** `../README.md`
- **Tài liệu yêu cầu:** `../02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- **Mockup hiện tại:** `../05-mockups/2026-05-03_mockup_v01.html`
- **Schema DB hiện tại:** `../08-database/2026-05-03_sqlapp_v01.txt`
- **Notion project:** https://www.notion.so/35678677fb3d8150b200ca56be5a67e0

### Tài liệu học tập

**Flutter:**
- Flutter docs: https://docs.flutter.dev/
- Code With Andrea (YouTube tiếng Anh): bài Flutter clean architecture
- FlutterDev VN (Facebook group)

**FastAPI:**
- FastAPI docs: https://fastapi.tiangolo.com/
- Tutorial: "Full Stack FastAPI + PostgreSQL" của tiangolo

**PostgreSQL:**
- PostgreSQL docs: https://www.postgresql.org/docs/16/

**Docker:**
- Docker Compose docs: https://docs.docker.com/compose/

---

**Trạng thái lộ trình:** v01 — bản đầu tiên, sẽ update theo tiến độ thực tế.
**Người chịu trách nhiệm cập nhật:** Team Lead.
