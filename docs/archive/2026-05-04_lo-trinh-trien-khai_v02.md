# Lộ trình triển khai dự án CNPM — PTIT Contest Management

**Phiên bản:** v02
**Ngày tạo:** 2026-05-04
**Thay đổi so với v01:** Sửa scope mục tiêu (4 actor thay vì 2-3 đã gộp); bổ sung module BCN & Admin; chốt phương án kiến trúc UI multi-role; cập nhật DB schema, API contract, timeline.
**Dự án:** Ứng dụng di động + cổng web quản lý các cuộc thi sinh viên PTIT
**Môn:** Công nghệ phần mềm (CNPM) — HK2 2026
**Stack:** Ubuntu Server 24.04 LTS + FastAPI + PostgreSQL + Nginx + systemd (backend) | Flutter mobile + Flutter Web (frontend, multi-role 1 codebase)

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
- [Module 10 — Implement Frontend Flutter (multi-role)](#module-10--implement-frontend-flutter-multi-role)
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

### Mục tiêu cuối (cập nhật scope đúng — 4 actor)

Hoàn thiện hệ thống gồm:

1. **Mobile app (Flutter, build APK Android)** dành cho **Sinh viên (Student)** — đăng ký tài khoản, tìm kiếm cuộc thi, đăng ký tham gia, nộp bài, theo dõi kết quả, đánh giá cuộc thi.

2. **Cổng quản trị web (Flutter Web, cùng codebase mobile)** phục vụ 3 vai trò:
   - **Giảng viên/Ban tổ chức (Lecturer/Organizer)** — tạo & vận hành cuộc thi, phê duyệt thí sinh, chấm bài, công bố kết quả, thống kê.
   - **Ban Chủ nhiệm khoa (Head of Department / BCN)** — phê duyệt **đề xuất cuộc thi** từ BTC trước khi chạy; phê duyệt **kết quả chung cuộc** trước khi công bố; xuất giấy chứng nhận; thống kê hoạt động khoa.
   - **Admin (Quản trị hệ thống)** — quản lý tài khoản & phân quyền, quản lý khoa/ngành, cấu hình hệ thống, audit log, báo cáo toàn hệ thống.

3. **Backend API (FastAPI) + PostgreSQL** với RBAC (Role-Based Access Control) cho 4 vai trò + cơ chế **phê duyệt 2 cấp BTC ↔ BCN** (BTC tạo cuộc thi → BCN duyệt → BTC vận hành → BTC nhập kết quả → BCN duyệt kết quả → công bố).

### Phương án kiến trúc UI (chốt 2026-05-04)

**1 Flutter codebase, build 2 target:**
- **APK Android** (mobile-only) → cài trên điện thoại sinh viên, chỉ render `features/student/*`
- **Flutter Web build** (host qua Nginx) → GV/BCN/Admin login trên trình duyệt máy tính, render `features/{organizer,bcn,admin}/*` theo role

JWT chứa `role` claim → router guard quyết định màn hình hiển thị. Code share `core/` (theme, networking, auth, state) ~70-80%.

### Phạm vi

Test offline 100%. Không deploy production thật, không thuê SMS gateway/cloud, không tích hợp thanh toán. Toàn bộ stack chạy local trên máy chủ giả lập (WSL2 trên 1 laptop). Các thiết bị (điện thoại SV + máy tính BTC/BCN/Admin) cùng mạng LAN.

### Nguyên tắc làm việc

1. **Đặt tên file:** `YYYY-MM-DD_chu-de_v01.ext` (kebab-case, không dấu).
2. **Versioning thay vì ghi đè** — sửa file đã có → tăng `v01` → `v02`.
3. **Mỗi module = 1 deliverable cụ thể** lưu vào subfolder tương ứng (xem README.md).
4. **Commit nhỏ, sớm, thường xuyên** — mỗi PR 1 chức năng đơn lẻ.
5. **Decision log** ghi lại mọi quyết định công nghệ trong `docs/`.

### Vai trò gợi ý (4-5 thành viên)

| Vai trò | Trách nhiệm chính |
|---|---|
| **Team Lead / PM** | Lên kế hoạch, theo dõi tiến độ, viết báo cáo |
| **UX/UI Designer** | Wireframe, mockup, design system, mapping mockup → Flutter |
| **Backend Dev** | FastAPI, PostgreSQL, RBAC, approval workflow |
| **Frontend Dev (Flutter)** | App SV (mobile) + cổng web GV/BCN/Admin |
| **QA / DevOps** | Test cases, Docker, deploy, demo |

> Trong nhóm nhỏ có thể gộp vai trò.

---

## Module 1 — Khởi động dự án (Project Kickoff)

**Thời gian:** Tuần 1 (3-5 ngày)
**Lưu vào folder:** `docs/`, `01-research/`

### Mục tiêu
- Cả nhóm hiểu chung về scope (4 actor, không gộp), mục tiêu, deadline
- Phân vai rõ ràng, có công cụ giao tiếp
- Roadmap v02 được nhóm phê duyệt

### Việc làm
1. **Họp kickoff** → `docs/2026-MM-DD_bien-ban-hop-kickoff_v01.md`
2. **Phân vai (RACI)** → `docs/2026-MM-DD_phan-vai-team_v01.md`
3. **Setup tool team:** Git repo private, Notion/Trello board, Zalo/Discord
4. **Đọc & xác nhận lộ trình v02 (file này)**
5. **Lịch họp định kỳ:** daily 15p + weekly review thứ 7

### Deliverables
- [ ] Biên bản họp kickoff
- [ ] Bảng phân vai
- [ ] Git repo, mọi người clone OK
- [ ] Lịch họp định kỳ

---

## Module 2 — Nghiên cứu & phân tích yêu cầu

**Thời gian:** Tuần 1-2 (1 tuần)
**Lưu vào folder:** `01-research/`, `02-requirements/`

### Mục tiêu
Hiểu rõ 4 nhóm user; có tài liệu yêu cầu chi tiết để dev cứ nhìn vào đó mà code.

### Việc làm

#### 2.1 — User research (`01-research/`)
- Phỏng vấn 3-5 sinh viên: đăng ký cuộc thi ra sao, pain point gì
- Phỏng vấn 1-2 BTC (giảng viên CLB/Đoàn)
- Phỏng vấn 1 BCN (chủ nhiệm khoa hoặc đơn vị tương đương)
- Phỏng vấn 1 Admin (cán bộ phòng IT trường, nếu có)
- Output: `2026-MM-DD_user-interview-summary_v01.md`

#### 2.2 — Persona (`01-research/`)
- Persona 1: Sinh viên năm 1 (newbie)
- Persona 2: Sinh viên năm 3 (experienced)
- Persona 3: Giảng viên/BTC
- Persona 4: BCN
- Persona 5: Admin
- Output: `2026-MM-DD_persona-{role}_v01.md` (5 file hoặc 1 file gộp)

#### 2.3 — Functional requirements (`02-requirements/`)

**Đã có sẵn 4 bảng chức năng** trong `2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`:

| Bảng | Bộ phận | Số chức năng | Mã |
|---|---|---|---|
| 2.1 | Sinh viên | 11 | SV |
| 2.2 | Giảng viên/BTC | 7 | GV |
| 2.3 | Ban Chủ nhiệm khoa | 6 | BCN |
| 2.4 | Admin | 6 | Admin |

→ Review, fill các ô còn thiếu, bổ sung version `v02` nếu cần.

#### 2.4 — Use case diagram (`02-requirements/`)
- 1 use case diagram tổng có **đủ 4 actor**
- Đặc biệt vẽ rõ **flow phê duyệt 2 cấp** (BTC ↔ BCN):
  - `<<include>>`: BTC tạo cuộc thi → bao gồm yêu cầu BCN duyệt
  - `<<include>>`: BTC nhập kết quả → bao gồm yêu cầu BCN duyệt kết quả
- Output: `2026-MM-DD_use-case-diagram_v01.png`

#### 2.5 — User stories (`02-requirements/`)
Format: "Là [vai trò], tôi muốn [chức năng] để [mục đích]"
- Tối thiểu 11 SV + 7 GV + 6 BCN + 6 Admin = **30 user stories**
- Output: `2026-MM-DD_user-stories_v01.md`

#### 2.6 — Non-functional requirements (`02-requirements/`)
Performance, bảo mật (RBAC, audit log), khả năng mở rộng.
- Output: `2026-MM-DD_yeu-cau-phi-chuc-nang_v01.md`

#### 2.7 — Quy trình phê duyệt 2 cấp (workflow document)
Mô tả chi tiết bằng sequence/activity diagram:
- BTC submit cuộc thi → trạng thái `pending_bcn_approval` → BCN approve/reject → `published`
- BTC nhập kết quả → trạng thái `result_pending_bcn` → BCN approve → `result_published`
- Output: `2026-MM-DD_workflow-phe-duyet_v01.md`

### Deliverables
- [ ] User interview summary
- [ ] 4-5 personas
- [ ] 4 bảng functional requirements (đã có, review/update)
- [ ] Use case diagram đủ 4 actor + relationship
- [ ] ≥30 user stories
- [ ] Non-functional requirements
- [ ] Workflow phê duyệt 2 cấp

---

## Module 3 — Thiết kế kiến trúc thông tin (IA) & user flow

**Thời gian:** Tuần 2-3 (4-5 ngày)
**Lưu vào folder:** `03-information-architecture/`

### Mục tiêu
- 4 sitemap riêng cho 4 actor
- Các flow liên-actor (đặc biệt BTC ↔ BCN) được vẽ rõ

### Việc làm

#### 3.1 — Sitemap (4 file riêng)
- `2026-MM-DD_sitemap-student_v01.png`
- `2026-MM-DD_sitemap-organizer_v01.png`
- `2026-MM-DD_sitemap-bcn_v01.png`
- `2026-MM-DD_sitemap-admin_v01.png`

#### 3.2 — User flow chính
- **SV:** đăng ký → đăng nhập → tìm cuộc thi → đăng ký tham gia → nộp bài → xem kết quả
- **BTC:** đăng nhập → tạo cuộc thi → submit cho BCN → nhận approval → mở đăng ký → phê duyệt SV → chấm bài → submit kết quả cho BCN → công bố
- **BCN:** đăng nhập → xem queue đề xuất cuộc thi → approve/reject → giám sát → duyệt kết quả → cấp chứng nhận
- **Admin:** đăng nhập → quản lý user → quản lý khoa/ngành → cấu hình hệ thống → xem audit log
- **Cross-actor (quan trọng):** flow phê duyệt 2 cấp BTC↔BCN — vẽ swimlane diagram
- Output: `2026-MM-DD_user-flow-{ten}_v01.svg`

#### 3.3 — Navigation pattern (theo target build)
- **App mobile SV:** Bottom Tab (4 tab: Home / Cuộc thi / Thông báo / Cá nhân)
- **Web GV/BTC:** Sidebar drawer
- **Web BCN:** Sidebar drawer
- **Web Admin:** Sidebar drawer + top bar
- Output: `2026-MM-DD_navigation-pattern_v01.md`

### Deliverables
- [ ] 4 sitemap (1/actor)
- [ ] ≥6 user flow diagram (4 actor + 2 cross-actor)
- [ ] Navigation pattern document

---

## Module 4 — Wireframe & Mockup UI

**Thời gian:** Tuần 3-4 (1-1.5 tuần)
**Lưu vào folder:** `04-wireframes/`, `05-mockups/`

### Mục tiêu
UI cho cả 4 actor được nhóm + GV duyệt trước khi code.

### Tình trạng hiện tại
Đã có `05-mockups/2026-05-03_mockup_v01.html` chứa mockup cho **cả 4 actor** dưới dạng tab. Đây là tài sản cực giá trị — không phải thiết kế lại từ đầu.

### Việc làm

#### 4.1 — Audit mockup hiện có
- Đếm chính xác số màn cho từng actor (mockup nói SV có 14 màn — kiểm tra các actor khác)
- Liệt kê thiếu/thừa so với requirements 4 bảng
- Output: `2026-MM-DD_mockup-audit_v01.md`

#### 4.2 — Bổ sung wireframe low-fi cho màn còn thiếu (`04-wireframes/`)
- Output: `2026-MM-DD_wireframe-{actor}-{man-hinh}_v01.png`

#### 4.3 — Bổ sung mockup cho màn còn thiếu (`05-mockups/`)
- Update mockup HTML lên `v02` nếu phải bổ sung
- Hoặc dựng Figma master file
- Output: `2026-MM-DD_mockup-master_v01.fig` + export PNG từng màn

#### 4.4 — Review với "user thử"
- 2 SV xem màn SV
- 1 giảng viên xem màn BTC
- 1 cán bộ khoa xem màn BCN

### Màn hình tối thiểu (theo mockup hiện có)

**Sinh viên (~14 màn):** Splash, Onboarding, Đăng ký, Đăng nhập, Home/Hub, Search/Filter cuộc thi, Chi tiết cuộc thi, Đăng ký tham gia, Nộp bài, Lịch sử, Profile, Đánh giá, Thông báo, Đổi mật khẩu

**Giảng viên/BTC:** Đăng nhập, Dashboard BTC, Tạo cuộc thi, Quản lý cuộc thi, Phê duyệt thí sinh, Chấm bài, Nhập điểm, Công bố kết quả, Thống kê

**BCN:** Đăng nhập, Dashboard BCN, Phê duyệt đề xuất cuộc thi, Chi tiết đề xuất, Giám sát tiến độ, Phê duyệt kết quả, Cấp chứng nhận, Thống kê khoa

**Admin:** Đăng nhập, Dashboard Admin, Quản lý người dùng, Quản lý khoa/ngành, Cấu hình hệ thống, Audit log, Báo cáo toàn hệ thống

### Deliverables
- [ ] Mockup audit report
- [ ] Wireframe đầy đủ cho cả 4 actor
- [ ] Mockup high-fi đầy đủ cho cả 4 actor
- [ ] Figma master file (hoặc HTML mockup v02)

---

## Module 5 — Design System

**Thời gian:** Tuần 4 (3-4 ngày, song song Module 4 cuối)
**Lưu vào folder:** `06-design-system/`

### Mục tiêu
Ngôn ngữ thiết kế thống nhất; áp dụng được cho cả mobile (mật độ cao) và web (mật độ rộng).

### Việc làm

#### 5.1 — Color palette
- Primary: PTIT Red (lấy từ mockup hiện tại)
- Secondary, neutral, semantic (success/error/warning/info)
- Output: `2026-MM-DD_color-palette_v01.png` + `.md` ghi mã hex

#### 5.2 — Typography (responsive scale)
- Font family: Inter / Roboto / Be Vietnam Pro (hỗ trợ tiếng Việt)
- 2 scale: mobile (compact) + web (rộng hơn)
- Output: `2026-MM-DD_typography_v01.md`

#### 5.3 — Spacing scale
- 4 / 8 / 16 / 24 / 32 / 48 (8pt grid)

#### 5.4 — Components spec
- Mobile: Button, Input, Card, BottomNav, OtpInput, Modal
- Web (admin): Sidebar, DataTable, Filter chip, Pagination, FormSection, KPICard, Modal
- Mỗi component có đủ state: default/hover/pressed/disabled
- Output: `2026-MM-DD_components-spec_v01.fig` + `.md`

#### 5.5 — Icon set
- Material Icons / Phosphor / Lucide

### Deliverables
- [ ] Color palette với hex
- [ ] Typography (2 scale: mobile + web)
- [ ] Spacing scale
- [ ] Components spec đủ cho mobile + web
- [ ] Icon set chốt

---

## Module 6 — Thiết kế database

**Thời gian:** Tuần 2-3 (làm song song)
**Lưu vào folder:** `08-database/`

### Mục tiêu
Schema PostgreSQL hoàn chỉnh, hỗ trợ RBAC + workflow phê duyệt 2 cấp + audit log.

### Việc làm

#### 6.1 — Review schema hiện tại
File `2026-05-03_sqlapp_v01.txt` — kiểm tra đủ chưa.

#### 6.2 — Bảng cần có (target v02)

| Nhóm | Bảng | Mô tả |
|---|---|---|
| **Identity & RBAC** | `users` | Tài khoản chung (id, email, password_hash, status...) |
| | `roles` | `student`, `organizer`, `bcn`, `admin` |
| | `user_roles` | M-N: 1 user có thể nhiều role (vd giảng viên kiêm BCN) |
| | `permissions` | Chi tiết quyền (`contest.create`, `result.approve`,...) |
| | `role_permissions` | M-N |
| **Master data** | `faculties` | Khoa |
| | `departments` | Bộ môn |
| | `majors` | Ngành đào tạo |
| | `classes` | Lớp |
| **Profile** | `students` | Mã SV, lớp, khoa, niên khóa |
| | `organizers` | Mã giảng viên, khoa |
| | `bcn_members` | BCN thuộc khoa nào |
| **Contest** | `contests` | Cuộc thi (status: draft/pending_bcn/approved/running/closed) |
| | `contest_categories` | Phân loại |
| | `contest_rounds` | Vòng thi (sơ loại / bán kết / chung kết) |
| | `participants` | Đăng ký tham gia |
| | `submissions` | Bài nộp |
| | `scores` | Điểm |
| | `results` | Kết quả tổng (status: draft/pending_bcn/published) |
| | `certificates` | Giấy chứng nhận (có QR code) |
| | `reviews` | Đánh giá cuộc thi của SV |
| **Workflow** | `approval_requests` | Generic approval (entity_type, entity_id, status, requester, approver) |
| | `approval_history` | Lịch sử quyết định approve/reject |
| **System** | `auth_codes` | Mã 6 chữ số (cho cả SV — login OTP) |
| | `audit_logs` | Mọi hành động sửa đổi quan trọng |
| | `system_configs` | Cấu hình (OTP_TTL, MAX_FILE_SIZE...) |
| | `notifications` | Thông báo |

#### 6.3 — ER diagram
- Output: `2026-MM-DD_er-diagram_v01.png` (dbdiagram.io / DBeaver)

#### 6.4 — Seed data
- 30 SV, 5 GV, 2 BCN (1/khoa), 1 Admin
- 8 cuộc thi (đủ trạng thái)
- Output: `2026-MM-DD_seed-data_v01.sql`

#### 6.5 — Migration scripts
- Alembic format
- `migrations/0001_init_identity.sql`, `0002_master_data.sql`, `0003_contest.sql`, `0004_workflow.sql`, `0005_system.sql`

#### 6.6 — Schema final
- Output: `2026-MM-DD_schema_v02.sql` (override `v01`)

### Deliverables
- [ ] Schema SQL đủ ~25 bảng
- [ ] ER diagram
- [ ] Seed data
- [ ] Migration files

---

## Module 7 — Thiết kế kiến trúc backend & API contract

**Thời gian:** Tuần 3 (3-5 ngày)
**Lưu vào folder:** `docs/`

### Mục tiêu
- Architecture diagram + OpenAPI spec đầy đủ trước khi code

### Việc làm

#### 7.1 — Architecture diagram
- Mobile (Flutter APK) + Web (Flutter Web qua Nginx) ↔ Nginx (port 80, reverse proxy + serve static web build) ↔ FastAPI/Uvicorn (port 8000) ↔ PostgreSQL (port 5432)
- Output: `docs/2026-MM-DD_architecture-diagram_v01.png`

#### 7.2 — API contract (OpenAPI 3.0) — phân route theo role

**Public/auth (mọi role):**
- `POST /auth/register` — SV đăng ký
- `POST /auth/login` — login (email + pass) → JWT có claim `role`
- `POST /auth/request-otp` — request mã 6 chữ số (alternative login)
- `POST /auth/verify-otp` — verify OTP → JWT
- `POST /auth/logout`
- `GET /me`

**Sinh viên (`/student/*`):**
- `GET /student/contests` — list cuộc thi đang mở
- `GET /student/contests/{id}` — chi tiết
- `POST /student/contests/{id}/register` — đăng ký
- `DELETE /student/contests/{id}/register` — hủy đăng ký
- `POST /student/contests/{id}/submissions` — nộp bài (multipart/form-data)
- `GET /student/contests/{id}/result` — xem kết quả của mình
- `GET /student/history` — lịch sử
- `POST /student/contests/{id}/review` — đánh giá

**Giảng viên/BTC (`/organizer/*`):**
- CRUD `/organizer/contests`
- `POST /organizer/contests/{id}/submit-for-bcn-approval`
- `GET /organizer/contests/{id}/participants`
- `PATCH /organizer/contests/{id}/participants/{pid}/approve`
- `GET /organizer/contests/{id}/submissions`
- `POST /organizer/contests/{id}/submissions/{sid}/score`
- `POST /organizer/contests/{id}/results/submit-for-bcn-approval`

**BCN (`/bcn/*`):**
- `GET /bcn/approval-queue?type=contest|result`
- `POST /bcn/approval-requests/{id}/approve`
- `POST /bcn/approval-requests/{id}/reject`
- `GET /bcn/contests/in-progress` — giám sát
- `POST /bcn/certificates/issue`
- `GET /bcn/reports`

**Admin (`/admin/*`):**
- CRUD `/admin/users`, `/admin/roles`, `/admin/faculties`, `/admin/departments`, `/admin/classes`
- GET/PUT `/admin/system-configs`
- `GET /admin/audit-logs`
- `GET /admin/reports/system`

#### 7.3 — RBAC middleware spec
- `Depends(require_role('admin'))`, `Depends(require_role(['organizer', 'bcn']))`
- Hoặc permission-based: `Depends(require_permission('contest.approve'))`

#### 7.4 — Cấu trúc folder backend

```
09-implementation/backend/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── db/
│   │   ├── session.py
│   │   └── models/        # 1 file/bảng hoặc gộp theo nhóm
│   ├── routers/
│   │   ├── auth.py
│   │   ├── student.py
│   │   ├── organizer.py
│   │   ├── bcn.py
│   │   └── admin.py
│   ├── schemas/           # Pydantic
│   ├── services/          # business logic + workflow
│   │   ├── approval.py    # logic phê duyệt 2 cấp
│   │   └── audit.py
│   ├── core/
│   │   ├── security.py    # JWT, password hash
│   │   └── rbac.py        # decorators / dependencies
│   └── deps.py
├── tests/
├── alembic/
├── requirements.txt
├── Dockerfile
└── .env.example
```

### Deliverables
- [ ] Architecture diagram
- [ ] OpenAPI spec đầy đủ (~50 endpoints)
- [ ] RBAC strategy document
- [ ] Cấu trúc folder backend chốt

---

## Module 8 — Setup môi trường dev

**Thời gian:** Tuần 4 (2-3 ngày)
**Lưu vào folder:** `docs/`

### Việc làm
1. Cài WSL2 + Ubuntu 24.04
2. Cài PostgreSQL 16 trong WSL2
3. Cài Python 3.12 + venv
4. Cài Flutter SDK + Android Studio + Chrome (cho web build)
5. Cài Git, VS Code + extension (Python, Flutter, Dart, REST Client, PostgreSQL)
6. Verify "Hello World" cho cả 3: backend, Flutter mobile, Flutter web
7. Output: `docs/2026-MM-DD_setup-dev-environment_v01.md`

### Deliverables
- [ ] Document setup từ A-Z
- [ ] Mọi thành viên xác nhận chạy được cả 3 target

---

## Module 9 — Implement Backend (FastAPI)

**Thời gian:** Tuần 4-7 (3-3.5 tuần)
**Lưu vào folder:** `09-implementation/backend/`

### Sub-module

#### 9.1 — Bootstrap (1-2 ngày)
- `fastapi`, `uvicorn`, `sqlalchemy`, `alembic`, `psycopg2-binary`, `pydantic-settings`, `python-jose`, `passlib`, `python-multipart`
- `GET /health`

#### 9.2 — Database & RBAC core (3-4 ngày)
- Models SQLAlchemy
- Migration init
- Seed roles + permissions + admin user mặc định
- `core/security.py`: JWT issue/verify
- `core/rbac.py`: dependencies `require_role`, `require_permission`

#### 9.3 — Auth router (2-3 ngày)
- Register (chỉ SV self-register; GV/BCN/Admin do Admin tạo)
- Login (email+password) → JWT
- OTP flow (request + verify)
- `/me`

#### 9.4 — Student router (3-4 ngày)
- List/detail contest (chỉ contest status=`approved` hoặc `running`)
- Đăng ký, hủy đăng ký
- Upload bài
- Xem kết quả, lịch sử
- Review

#### 9.5 — Organizer router + workflow (3-4 ngày)
- CRUD contest
- **Submit cuộc thi cho BCN duyệt** → tạo `approval_request`
- Phê duyệt thí sinh
- Chấm điểm
- **Submit kết quả cho BCN** → tạo `approval_request`

#### 9.6 — BCN router (2-3 ngày) ⚡ **MỚI vs v01**
- Approval queue
- Approve/reject (chuyển trạng thái contest/result tương ứng)
- Giám sát contest đang chạy
- Cấp chứng nhận

#### 9.7 — Admin router (3-4 ngày) ⚡ **MỚI vs v01**
- CRUD users + assign role
- CRUD master data (faculty/department/major/class)
- System configs (OTP TTL, max file size)
- Audit logs query
- Reports

#### 9.8 — Audit log middleware (1-2 ngày) ⚡ **MỚI vs v01**
- Decorator/middleware ghi log mọi action sửa đổi
- Lưu vào `audit_logs` table

#### 9.9 — Validation, error handling, logging (1-2 ngày)

#### 9.10 — Unit test pytest (làm xen kẽ, target 60% coverage)

### Deliverables
- [ ] Toàn bộ ~50 endpoint chạy qua Swagger UI
- [ ] RBAC test pass (SV không gọi được endpoint admin, etc)
- [ ] Workflow phê duyệt 2 cấp test E2E
- [ ] Audit log ghi đủ
- [ ] Unit tests pass

---

## Module 10 — Implement Frontend Flutter (multi-role)

**Thời gian:** Tuần 5-9 (4-4.5 tuần, song song Module 9 từ tuần 5)
**Lưu vào folder:** `09-implementation/frontend/`

### Cấu trúc folder

```
09-implementation/frontend/
├── lib/
│   ├── main.dart                # entry point chung (detect role → route)
│   ├── app/
│   │   ├── router.dart          # go_router với role guard
│   │   └── theme.dart
│   ├── core/
│   │   ├── network/             # dio + interceptor (attach JWT, refresh)
│   │   ├── auth/                # JWT storage, role detection
│   │   ├── rbac/                # role guard widgets
│   │   └── utils/
│   ├── features/
│   │   ├── auth/                # login, register, OTP — dùng cho mọi role
│   │   ├── student/             # mobile-first (~14 màn)
│   │   ├── organizer/           # web-first (sidebar layout)
│   │   ├── bcn/                 # web-first
│   │   └── admin/               # web-first
│   └── shared/                  # widgets dùng chung
├── pubspec.yaml
├── android/
└── web/
```

### Sub-module

#### 10.1 — Bootstrap (1-2 ngày)
- `flutter create ptit_contest --platforms=android,web`
- Dependencies: `dio`, `flutter_riverpod` (hoặc `bloc`), `go_router`, `flutter_secure_storage`, `intl`, `freezed`, `json_serializable`, `file_picker`, `data_table_2` (cho admin web)

#### 10.2 — Theme & design system (1-2 ngày)
- Implement Module 5 vào `ThemeData` + custom widgets

#### 10.3 — Auth flow chung (3-4 ngày)
- Splash detect token
- Login/Register/OTP
- Lưu JWT, parse role
- `RoleGuard` widget

#### 10.4 — Feature Student (4-5 ngày)
- Bottom Tab navigation
- Home/Hub, Search, Detail, Register, Submit, Results, Profile, Reviews
- Tối ưu cho màn hình mobile

#### 10.5 — Feature Organizer (4-5 ngày) ⚡ **MỞ RỘNG vs v01**
- Sidebar layout (web)
- Dashboard, Contest CRUD, Submit-for-BCN button
- Participant approval table, Scoring form
- Submit results

#### 10.6 — Feature BCN (3-4 ngày) ⚡ **MỚI vs v01**
- Sidebar layout
- Approval queue (DataTable với filter)
- Detail approval (xem proposal → approve/reject + comment)
- Monitor contests
- Issue certificates

#### 10.7 — Feature Admin (3-4 ngày) ⚡ **MỚI vs v01**
- Sidebar layout
- User CRUD + role assignment
- Master data CRUD
- System configs form
- Audit log viewer (filter, search)
- Reports (chart với fl_chart hoặc syncfusion_flutter_charts)

#### 10.8 — Responsive & polish (2-3 ngày)
- Web layouts: tối thiểu width 1024px (desktop)
- Mobile: tối thiểu 360px
- Loading/error/empty states

### Deliverables
- [ ] APK build chạy trên Android (chỉ student features)
- [ ] Web build chạy qua Nginx (chỉ organizer/bcn/admin features hiển thị theo role)
- [ ] Login → role detection → route đúng
- [ ] RBAC client-side: route guard ngăn user access feature không có quyền

---

## Module 11 — Tích hợp End-to-End

**Thời gian:** Tuần 9-10 (1 tuần)
**Lưu vào folder:** `10-testing/`

### Việc làm
1. **Setup network LAN** — backend chạy WSL2, expose IP cho mobile + máy tính web client
2. **Test E2E các flow cross-actor:**
   - **Flow 1 (full lifecycle):** BTC tạo cuộc thi → BCN duyệt → SV đăng ký → SV nộp bài → BTC chấm → BTC submit kết quả → BCN duyệt kết quả → SV xem kết quả → BCN cấp chứng nhận
   - **Flow 2 (RBAC negative test):** SV cố gọi endpoint `/admin/*` → 403
   - **Flow 3:** Admin tạo tài khoản BCN mới → BCN login → vào được dashboard
   - **Flow 4:** Admin xem audit log có ghi đầy đủ
3. **Fix lỗi thường gặp:** CORS, ISO date format, snake_case vs camelCase, JWT expiry
4. Output: `10-testing/2026-MM-DD_smoke-test-report_v01.md`

### Deliverables
- [ ] 4 flow E2E pass
- [ ] Smoke test report

---

## Module 12 — Testing & QA

**Thời gian:** Tuần 10-11 (1-1.5 tuần)
**Lưu vào folder:** `10-testing/`

### Việc làm

#### 12.1 — Test cases (≥40 case) cho 4 actor
- Mỗi actor 10+ case, đặc biệt RBAC negative tests
- Output: `2026-MM-DD_test-cases_v01.xlsx`

#### 12.2 — Usability test
- 3 SV thử app mobile
- 1 GV thử portal organizer
- 1 BCN thử portal BCN (nếu khó tìm thì giáo viên đóng vai)
- Output: `2026-MM-DD_usability-test-report_v01.docx`

#### 12.3 — Performance test
- Locust/wrk → backend `/student/contests` với 100 concurrent
- Output: `2026-MM-DD_performance-report_v01.md`

#### 12.4 — Security test cơ bản
- JWT tampering: sửa role trong payload → server reject (vì chữ ký invalid)
- Direct API call không token → 401
- Audit log có ghi đầy đủ
- Output: `2026-MM-DD_security-test-report_v01.md`

#### 12.5 — Bug log
- Output: `2026-MM-DD_bug-log_v01.xlsx`

### Deliverables
- [ ] Test cases (≥40)
- [ ] Usability report
- [ ] Performance report
- [ ] Security test report
- [ ] Bug log

---

## Module 13 — Triển khai local (Docker / Nginx / systemd)

**Thời gian:** Tuần 11 (4-5 ngày)
**Lưu vào folder:** `09-implementation/deploy/`

### Việc làm

#### 13.1 — Dockerfile cho FastAPI

#### 13.2 — Docker Compose
```yaml
services:
  db: postgres:16
  api: build ./backend
  web:
    image: nginx:alpine
    volumes:
      - ./frontend/build/web:/usr/share/nginx/html  # Flutter Web build
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports: ["80:80"]
```

#### 13.3 — Nginx config
- `/api/*` → reverse proxy đến `api:8000`
- `/*` → serve static Flutter Web build
- (Mobile APK gọi trực tiếp `http://<lan-ip>/api/*`)

#### 13.4 — systemd unit file (báo cáo)
- `ptit-contest-api.service`
- Để demo "deploy không Docker"

#### 13.5 — Hướng dẫn deploy
- Output: `2026-MM-DD_deploy-guide_v01.md`

### Deliverables
- [ ] `docker-compose.yml` chạy 1 lệnh
- [ ] Nginx config
- [ ] systemd unit
- [ ] Deploy guide

---

## Module 14 — Documentation & báo cáo

**Thời gian:** Tuần 11-12 (làm xen kẽ từ tuần 8)

### Việc làm

#### 14.1 — Báo cáo chính (Word document)
- Chương 1: Giới thiệu
- Chương 2: Khảo sát hiện trạng & yêu cầu (4 actor, 30 user stories)
- Chương 3: Phân tích thiết kế (use case 4 actor, ERD ~25 bảng, sequence flow phê duyệt 2 cấp, class diagram)
- Chương 4: Thiết kế kiến trúc & công nghệ (giải thích tại sao chọn từng tech, có dẫn chứng từ research market 2026)
- Chương 5: Cài đặt & triển khai (RBAC, workflow, audit log)
- Chương 6: Kiểm thử (4 loại test)
- Chương 7: Kết luận & hướng phát triển
- Output: `docs/2026-MM-DD_bao-cao-cuoi-ky_v01.docx`

#### 14.2 — Decision log
- Output: `docs/2026-MM-DD_decision-log_v01.md`

#### 14.3 — User manual (4 manual riêng cho 4 role)
- Output: `docs/2026-MM-DD_user-manual-{role}_v01.docx`

#### 14.4 — README.md (root) — update phản ánh v02

#### 14.5 — Báo cáo tiến độ tuần (12 bản)

### Deliverables
- [ ] Báo cáo chính (≥50 trang vì scope lớn hơn)
- [ ] Decision log
- [ ] 4 user manual
- [ ] 12 báo cáo tiến độ tuần

---

## Module 15 — Chuẩn bị bảo vệ & demo

**Thời gian:** Tuần 12 (3-5 ngày cuối)

### Việc làm

#### 15.1 — Slide thuyết trình (~20-25 slide)
- Outline: Vấn đề → Giải pháp (4 actor) → Demo → Kiến trúc → Workflow phê duyệt → Kết quả → Hướng phát triển
- Output: `docs/2026-MM-DD_slide-bao-ve_v01.pptx`

#### 15.2 — Kịch bản demo (E2E, đủ 4 actor)
1. Admin tạo cuộc thi mẫu (nếu cần) + tạo tài khoản BCN, GV
2. GV/BTC login web → tạo cuộc thi → submit cho BCN
3. BCN login web → duyệt cuộc thi → cuộc thi mở
4. SV login mobile → đăng ký cuộc thi → nộp bài
5. GV chấm bài → submit kết quả
6. BCN duyệt kết quả → công bố
7. SV xem kết quả + đánh giá
8. Admin xem audit log thấy đầy đủ
- Output: `docs/2026-MM-DD_kich-ban-demo_v01.md`

#### 15.3 — Backup video demo

#### 15.4 — Tập demo nội bộ ≥3 lần

#### 15.5 — Q&A prep
- ≥25 câu hỏi giáo viên có thể hỏi (RBAC, workflow, lựa chọn tech, scalability...)

### Deliverables
- [ ] Slide
- [ ] Kịch bản demo cross-actor
- [ ] Video backup
- [ ] Q&A prep

---

## Timeline tổng hợp 12 tuần

```
Tuần │ 01 │ 02 │ 03 │ 04 │ 05 │ 06 │ 07 │ 08 │ 09 │ 10 │ 11 │ 12 │
─────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
M1   │ ██ │    │    │    │    │    │    │    │    │    │    │    │  Kickoff
M2   │ ██ │ ██ │    │    │    │    │    │    │    │    │    │    │  Research & Req (4 actor)
M3   │    │ ██ │ ██ │    │    │    │    │    │    │    │    │    │  IA & user flow (4 sitemap)
M4   │    │    │ ██ │ ██ │    │    │    │    │    │    │    │    │  Wireframe/Mockup
M5   │    │    │    │ ██ │    │    │    │    │    │    │    │    │  Design system
M6   │    │ ██ │ ██ │    │    │    │    │    │    │    │    │    │  Database (~25 bảng)
M7   │    │    │ ██ │    │    │    │    │    │    │    │    │    │  API contract (~50 endpoint)
M8   │    │    │    │ ██ │    │    │    │    │    │    │    │    │  Setup dev env
M9   │    │    │    │ ██ │ ██ │ ██ │ ██ │    │    │    │    │    │  Backend (+BCN +Admin +Audit)
M10  │    │    │    │    │ ██ │ ██ │ ██ │ ██ │ ██ │    │    │    │  Frontend Flutter multi-role
M11  │    │    │    │    │    │    │    │    │ ██ │ ██ │    │    │  Tích hợp E2E
M12  │    │    │    │    │    │    │    │    │    │ ██ │ ██ │    │  Testing/QA
M13  │    │    │    │    │    │    │    │    │    │    │ ██ │    │  Deploy local
M14  │    │    │    │    │    │    │    │ ██ │ ██ │ ██ │ ██ │ ██ │  Documentation
M15  │    │    │    │    │    │    │    │    │    │    │    │ ██ │  Demo prep
```

**Buffer:** Thêm 25% (vs 20% ở v01) vì scope tăng so với v01.

---

## Checklist deliverables cuối kỳ

### Code & sản phẩm
- [ ] Backend FastAPI ~50 endpoint với RBAC + workflow phê duyệt 2 cấp
- [ ] APK Android (Sinh viên)
- [ ] Flutter Web build (Organizer + BCN + Admin)
- [ ] Database ~25 bảng + seed data
- [ ] Docker Compose chạy 1 lệnh
- [ ] systemd unit file backup

### Tài liệu thiết kế
- [ ] User research summary
- [ ] 4-5 personas (đủ 4 actor + 2 SV phân nhóm)
- [ ] 4 bảng functional requirements
- [ ] Use case diagram đủ 4 actor
- [ ] ≥30 user stories
- [ ] Workflow phê duyệt 2 cấp document
- [ ] 4 sitemap + ≥6 user flow diagram
- [ ] Wireframe + mockup đủ 4 actor
- [ ] Design system (mobile + web)
- [ ] ER diagram
- [ ] Architecture diagram
- [ ] OpenAPI spec ~50 endpoint
- [ ] RBAC strategy doc

### Tài liệu kiểm thử
- [ ] Test cases ≥40 (bao gồm RBAC negative)
- [ ] Usability report (≥3 SV + 1 GV + 1 BCN)
- [ ] Performance report
- [ ] Security test report
- [ ] Bug log

### Tài liệu báo cáo
- [ ] Báo cáo chính (≥50 trang)
- [ ] Decision log
- [ ] 4 user manual (1/role)
- [ ] 12 báo cáo tiến độ tuần
- [ ] Slide thuyết trình
- [ ] Kịch bản demo cross-actor + video backup

---

## Rủi ro & phương án dự phòng

| Rủi ro | Xác suất | Tác động | Phương án dự phòng |
|---|---|---|---|
| Scope 4 actor quá lớn cho 12 tuần | **Cao** | Cao | **Cắt phạm vi sớm:** Admin chỉ làm CRUD users + audit log (cắt master data CRUD đơn giản hóa). Tuyệt đối không cắt BCN vì có workflow đặc trưng. |
| Thành viên drop môn / bận đột xuất | Trung bình | Cao | Phân vai cross-functional, ai cũng có 1 backup; commit code thường xuyên |
| RBAC implement sai (lỗ hổng) | Trung bình | Cao | Unit test cho mọi endpoint với cả token đúng/sai role; security test ở Module 12 |
| Workflow phê duyệt 2 cấp lằng nhằng | Cao | Trung bình | Vẽ kỹ state machine ở Module 2.7; viết unit test cho service `approval.py` riêng |
| Flutter Web khó load chậm trên mạng yếu | Thấp | Thấp | Demo qua localhost; pre-load `flutter build web --release` |
| Mobile chưa kết nối được backend (CORS, IP) | Trung bình | Thấp | Test sớm tuần 6; ngrok backup |
| Schema DB phải sửa lớn giữa kỳ | Trung bình | Cao | Migration via Alembic; review schema kỹ Module 6 trước khi code; bảng `audit_logs` schema cố định |
| Deadline gấp, không kịp Admin | Trung bình | Trung bình | **Ưu tiên cắt:** Admin reports + master data CRUD (giữ User CRUD + audit log). Báo cáo nói rõ "scope phase 1". |
| Không có người test usability đủ 4 role | Trung bình | Thấp | Giáo viên trong khoa đóng vai BCN/Admin test |
| Mất data | Thấp | Cao | Backup DB hàng tuần; Git push daily |

---

## Phụ lục — Liên kết hữu ích

- **README dự án:** `../README.md`
- **Tài liệu yêu cầu:** `../02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- **Mockup hiện tại (4 actor):** `../05-mockups/2026-05-03_mockup_v01.html`
- **Schema DB hiện tại:** `../08-database/2026-05-03_sqlapp_v01.txt`
- **Roadmap v01 (history):** `2026-05-04_lo-trinh-trien-khai_v01.md`
- **Notion project:** https://www.notion.so/35678677fb3d8150b200ca56be5a67e0

### Tài liệu học tập
- Flutter docs: https://docs.flutter.dev/
- Flutter Web: https://docs.flutter.dev/platform-integration/web
- FastAPI docs: https://fastapi.tiangolo.com/
- FastAPI security/RBAC: https://fastapi.tiangolo.com/advanced/security/
- PostgreSQL docs: https://www.postgresql.org/docs/16/
- Docker Compose docs: https://docs.docker.com/compose/

---

**Trạng thái lộ trình:** v02 — bản cập nhật scope đầy đủ 4 actor + workflow phê duyệt 2 cấp + multi-role frontend.
**Người chịu trách nhiệm cập nhật:** Team Lead.
