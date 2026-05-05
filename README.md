# 12 — CNPM Project: PTIT Contest Management System

**Trạng thái:** Active
**Môn:** Công nghệ phần mềm (CNPM)
**Học kỳ:** HK2 2026
**Topic:** Ứng dụng di động quản lý cuộc thi sinh viên PTIT

---

## Mô tả

Hệ thống quản lý cuộc thi sinh viên cho PTIT, gồm:
- **Mobile app** (giao diện sinh viên + Ban tổ chức): đăng nhập bằng mã 6 chữ số, xem cuộc thi, theo dõi kết quả.
- **Backend database** (PostgreSQL): schema `ptit_contest` quản lý contest, participant, submission.
- **Cổng Ban tổ chức:** vai trò admin để tạo/duyệt cuộc thi.

Mockup gồm các màn hình: Splash → Contest Hub → Chào mừng → Nhập mã → Cổng BTC.

---

## Cấu trúc folder (theo chuẩn UX/UI design + SE lifecycle)

```
12-cnpm-project/
├── README.md                          ← file này
├── 01-research/                       ← user research, persona, competitor analysis
├── 02-requirements/                   ← yêu cầu chức năng/phi chức năng, use case, user story
│   └── 2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx     (tài liệu chính)
├── 03-information-architecture/       ← sitemap, user flow, navigation pattern
├── 04-wireframes/                     ← low-fi sketches (skeleton bố cục)
├── 05-mockups/                        ← high-fi UI screens (chi tiết màu sắc)
│   └── 2026-05-03_mockup_v01.html                       (mockup HTML hiện tại)
├── 06-design-system/                  ← style guide: colors, typography, components, icons
├── 07-prototypes/                     ← interactive prototype (Figma exports, ...)
├── 08-database/                       ← schema + ER diagrams + SQL scripts
│   └── 2026-05-03_sqlapp_v01.txt                        (PostgreSQL schema)
├── 09-implementation/                 ← code (mobile app, backend, API)
├── 10-testing/                        ← test cases, usability test, QA reports
├── assets/                            ← shared: logo, fonts, images, icons
└── docs/                              ← reports, biên bản họp, references
```

---

## Hướng dẫn sử dụng từng folder

### 01-research/
Trước khi thiết kế phải hiểu user. Folder này chứa:
- User interview transcripts
- Personas (hồ sơ user mẫu)
- Competitive analysis (phân tích app tương tự đang có trên thị trường)
- Survey results

**Naming:** `2026-MM-DD_persona-sv-ptit_v01.md`, `2026-MM-DD_competitor-analysis_v01.docx`

### 02-requirements/
Yêu cầu hệ thống:
- Functional requirements (chức năng)
- Non-functional (hiệu năng, bảo mật, scalability)
- Use cases / User stories
- Acceptance criteria

**Naming:** `2026-MM-DD_use-cases-sinh-vien_v01.md`, `2026-MM-DD_yeu-cau-chuc-nang_v01.docx`

### 03-information-architecture/
Cấu trúc thông tin app:
- Sitemap (sơ đồ tổ chức màn hình)
- User flow (luồng đi qua các màn hình)
- Navigation pattern (tab bar / drawer / hierarchical)

**Naming:** `2026-MM-DD_sitemap_v01.png`, `2026-MM-DD_user-flow-dang-ki-cuoc-thi_v01.svg`

### 04-wireframes/
Low-fidelity sketches — chỉ bố cục, KHÔNG màu, KHÔNG ảnh thật:
- Wireframe từng màn hình (Splash, Login, Contest List, ...)
- Có thể vẽ tay scan, hoặc dùng Balsamiq, Figma low-fi

**Naming:** `2026-MM-DD_wireframe-contest-list_v01.png`

### 05-mockups/
High-fidelity UI screens — đầy đủ màu, font, icon, ảnh thật:
- Mỗi màn hình 1 file (hoặc gộp nhiều state)
- Export từ Figma/Sketch/Adobe XD

**Naming:** `2026-MM-DD_mockup-contest-hub_v01.png`, `2026-MM-DD_mockup-flow-dang-ki_v01.fig`

### 06-design-system/
Style guide nhất quán cho cả app:
- Color palette (primary, secondary, semantic colors)
- Typography (font family, size, weight, line-height)
- Components (button, card, input, modal — variants states)
- Icon set
- Spacing scale (4/8/16/24/32...)

**Naming:** `2026-MM-DD_color-palette_v01.png`, `2026-MM-DD_typography_v01.md`, `2026-MM-DD_components-spec_v01.fig`

### 07-prototypes/
Interactive prototype — click được, demo được:
- Figma prototype link export
- mockup.html dạng clickable
- Lottie animations

**Naming:** `2026-MM-DD_prototype-flow-dang-nhap_v01.html`

### 08-database/
Thiết kế DB:
- Schema SQL (DDL)
- ER diagram
- Sample data
- Migration scripts

**Naming:** `2026-MM-DD_schema_v01.sql`, `2026-MM-DD_er-diagram_v01.png`

### 09-implementation/
Code thực tế:
- Mobile app source (chia subfolder `frontend/` `backend/` khi cần)
- API specs (OpenAPI/Swagger)
- Build scripts

**Naming:** code file giữ tên gốc theo convention framework. Doc/spec file đặt theo chuẩn PARA.

### 10-testing/
Kiểm thử:
- Test cases (manual + automated)
- Usability test reports
- QA bug reports
- Performance test results

**Naming:** `2026-MM-DD_test-cases-login_v01.xlsx`, `2026-MM-DD_usability-report_v01.docx`

### assets/
Shared resources dùng chéo nhiều folder:
- Logo (PNG, SVG, AI)
- Brand fonts (TTF, OTF)
- Stock photos
- Icon set chung

**Naming:** `logo-ptit-contest_v01.svg`, `font-roboto.ttf`

### docs/
Tài liệu meta (không thuộc design hay code):
- Báo cáo tiến độ tuần
- Biên bản họp nhóm
- References (paper, link tham khảo)
- Decision log

**Naming:** `2026-MM-DD_bao-cao-tien-do-tuan-X_v01.docx`, `2026-MM-DD_bien-ban-hop_v01.md`

---

## Tech stack (cập nhật khi quyết định)

| Layer | Tool |
|---|---|
| Backend DB | PostgreSQL (schema `ptit_contest`) |
| Mobile UI mockup | HTML/CSS (xem `05-mockups/2026-05-03_mockup_v01.html`) |
| Mobile app (planned) | (cập nhật: Flutter / React Native / native Android) |
| Backend API (planned) | (cập nhật: Node.js Express / Python FastAPI / Java Spring Boot) |

---

## Naming convention nhắc lại

`YYYY-MM-DD_chu-de_v01.ext`

- Không khoảng trắng, không dấu tiếng Việt, không ký tự đặc biệt
- kebab-case (gạch nối) cho topic
- Version `v01, v02, ..., v10` (KHÔNG dùng `_FINAL`, `_revised`)
- Folder name kebab-case, có prefix số `01-`, `02-`, ...

Chi tiết: `..\..\..\..\..\Personal Knowlege Management\2026-05-04_naming-va-subfolder-guide_v01.md`

---

## Việc đang/sẽ làm

- [x] Tạo cấu trúc 11 subfolder (2026-05-04)
- [x] Move 3 file hiện có vào đúng folder (2026-05-04)
- [ ] Quyết định tech stack mobile (Flutter / React Native / Android native)
- [ ] Vẽ wireframe các màn hình chính → save vào `04-wireframes/`
- [ ] Tạo design system (palette, typography, components) → `06-design-system/`
- [ ] Implement schema từ `08-database/2026-05-03_sqlapp_v01.txt` lên môi trường dev
- [ ] Convert mockup HTML → mobile UI thực tế trong `09-implementation/`
- [ ] Báo cáo tiến độ hàng tuần vào `docs/`

---

## Liên kết

- Notion project: https://www.notion.so/35678677fb3d8150b200ca56be5a67e0
- Repo Git (nếu có): (paste URL)
