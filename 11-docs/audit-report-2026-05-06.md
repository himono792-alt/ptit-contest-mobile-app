# Audit Report — PTIT Contest Management v1.0

**Ngày audit:** 2026-05-06
**Scope:** Database schema + Backend (FastAPI) + Frontend (Flutter) + Deploy strategy
**Mục đích:** Kiểm tra tính ổn định của dự án **TRƯỚC** khi bước vào Phase 1 (Production Foundation) trong roadmap 4 phase, để các nâng cấp sau không gặp rủi ro.
**Phương pháp:** Đọc 100% file SQL schema (1057 dòng) + 16 model files + 14 router files + 16 service files + middleware + config + frontend conditional imports + Dockerfile + alembic setup. So sánh chéo schema canonical (`08-database/2026-05-04_sqlapp_v03.sql`) ↔ SQLAlchemy models ↔ idempotent migration ↔ init-schema.sql.

---

## Tóm tắt điều hành (Executive summary)

Dự án **về cơ bản OK để demo nhưng chưa sẵn sàng cho production-scale upgrade**. Có 4 vấn đề **P0 (BLOCKER)** phải fix trước khi merge bất kỳ thứ gì lớn vào, 6 vấn đề **P1 (HIGH)** nên fix trong Sprint 1, và một loạt P2/P3 có thể defer.

### Mức độ ổn định theo lớp

| Lớp | Trạng thái | Ghi chú |
|---|---|---|
| **PostgreSQL Schema (DB)** | Vàng | Schema canonical đã drift khỏi production. Constraint logic vững nhưng FK cascade order có rủi ro. |
| **Backend FastAPI** | Vàng-Xanh | 99 endpoint, business logic chắc, nhưng có 1 bug routing CỨNG (cert verify), config production yếu, audit pool thiết kế tốt nhưng đo lường chưa có. |
| **Frontend Flutter** | Xanh | Conditional import cho web/mobile clean, token storage hoạt động trên cả LAN-HTTP, no obvious leak. |
| **Migration strategy** | **ĐỎ** | "Half-Alembic": có alembic.ini + env.py nhưng `versions/` rỗng. Đang chạy idempotent ALTER TABLE trong lifespan — không scale được. **Đây là rủi ro lớn nhất cho upgrade.** |
| **Deploy / Ops** | Vàng | Railway auto-deploy OK, nhưng không có Sentry, không có rate limit, không có CI test gate. |

---

## P0 — BLOCKER (phải fix trước khi đụng vào code mới)

### P0-1. Schema drift: file canonical KHÔNG match production

**Vấn đề.** File `08-database/2026-05-04_sqlapp_v03.sql` (1057 dòng) là byte-for-byte giống `09-implementation/backend/init-schema.sql`. Cả 2 đều **THIẾU**:

- 9 cột profile mở rộng trên `app_users`: `dob, gender, citizen_id, place_of_birth, address, ethnicity, religion, nationality, secondary_email`
- 1 cột `submission_files.file_data BYTEA`

Các cột này được thêm bằng idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` trong `app/main.py` (lifespan). Hậu quả:

1. Bất kỳ ai dump schema từ production xuống và cho người khác chạy lại từ file `2026-05-04_sqlapp_v03.sql` → **mất luôn 10 cột** đến khi backend khởi động và chạy idempotent block.
2. ORM expect `dob, file_data,...` ngay từ request đầu tiên — nếu lifespan chưa chạy xong (race condition khi cold-start) → **500 error** trên các request sớm.
3. File báo cáo môn CNPM (đồ án) đang nói "DB v03 = 43 bảng + đầy đủ trường" trong khi thực tế DB production có schema khác.

**Impact.** HIGH — bất kỳ lần reset DB nào cũng gây regression. Onboarding dev mới rất rối.

**Fix (~30 phút):**
1. Tạo file mới `08-database/2026-05-06_sqlapp_v04.sql` = v03 + 10 cột bổ sung **inline trong CREATE TABLE** (không dùng ALTER nữa).
2. Update `09-implementation/backend/init-schema.sql` thành bản v04.
3. Xóa `_PROFILE_MIGRATION_SQL` và try/except wrapper trong `app/main.py` (idempotent block không cần nữa).
4. Tạo Alembic migration baseline `0001_init.py` chỉ stamp current head, để Alembic biết DB đang ở v04.

---

### P0-2. Cert verify endpoint 404 vĩnh viễn — bug routing nuốt 1 trong 30 chức năng SV

**Vấn đề.** Trong `app/main.py:142`:

```python
app.include_router(certificates.verify_router)   # KHÔNG có prefix=P
```

Trong khi mọi router khác đều có `prefix=P` (= `/api`). Router definition trong `routers/certificates.py:25`:

```python
verify_router = APIRouter(prefix="/verify", tags=["certificates"])
```

→ Path thực tế là `/verify/{qr_code}`, **không phải** `/api/verify/{qr_code}` như memory `project_cnpm_status_2026-05.md` ghi nhận.

**Impact.** Bất cứ ai scan QR cert và app gọi `/api/verify/{qr}` đều nhận 404. Hiện FE đang dùng `/api/certificates/{qr}/render` để workaround → render HTML đẹp, nhưng **không có flow public verify "thật/giả"** ngoài render HTML. Một QR thu hồi (`revoked_at NOT NULL`) vẫn render PDF đẹp như thường.

**Fix (~5 phút):** đổi 1 dòng trong `main.py:142`:
```python
app.include_router(certificates.verify_router, prefix=P)
```

Sau đó FE update endpoint check, hoặc giữ cả 2 path bằng 1 router thứ 2.

---

### P0-3. Audit middleware giữ kết nối DB sau khi response đã trả

**Vấn đề.** Trong `app/middleware/audit.py:139-181`, sau khi `await self.app(scope, receive, send_wrapper)` hoàn tất (response đã đi ra cho client), code vẫn **AWAIT trong cùng request scope**:

```python
await self.app(scope, receive, send_wrapper)
# response đã được gửi
...
await _write_audit(...)   # block ~5-15ms — request worker bị chiếm
```

Đây là vấn đề:
- Pool audit có 4 conn (`pool_size=2, max_overflow=2`). Burst 20 req/sec → 5 req cùng lúc đợi conn → tail latency 50-100ms.
- Nếu audit DB chậm vì lý do nào đó (network blip Railway), request workers bị chiếm → 502 timeout cho user.
- Comment trong file nói "AWAIT trực tiếp — engine pool riêng đảm bảo cleanup đúng" — đúng về **cleanup**, sai về **throughput**.

**Impact.** Hiện tại traffic thấp nên không thấy. Khi triển khai cho 200 SV cùng đăng ký 1 cuộc thi → tail p99 latency tăng 5-10x.

**Fix (~30 phút):** chuyển sang pattern fire-and-forget bằng `asyncio.create_task` + 1 unbounded queue, hoặc tốt hơn dùng `BackgroundTasks` của FastAPI. Pattern đề xuất:

```python
import asyncio
_audit_queue: asyncio.Queue = asyncio.Queue(maxsize=1000)

async def _audit_worker():
    while True:
        payload = await _audit_queue.get()
        try:
            await _write_audit(**payload)
        except Exception:
            pass

# trong middleware sau khi response đã gửi:
try:
    _audit_queue.put_nowait({...})  # non-blocking
except asyncio.QueueFull:
    pass  # rớt audit dưới load cực đoan
```

Khởi worker trong `lifespan` startup, cancel ở shutdown.

---

### P0-4. Half-Alembic — không có migration history, mọi schema change phải sửa SQL thủ công

**Vấn đề.**
- `alembic.ini` có sẵn, `alembic/env.py` đã wire `Base.metadata` từ ORM
- Nhưng `alembic/versions/` **trống rỗng**
- Không có migration nào được commit → DB production **không có** bảng `alembic_version`
- Mọi schema change trong tương lai (Phase 1: Sentry chưa cần, refresh token thì cần `refresh_tokens` table; Phase 2: dark mode prefs trên `app_users`; Phase 3: WebSocket session table; Phase 4: S3 metadata table) đều sẽ phải:
  - Thêm vào `_PROFILE_MIGRATION_SQL` block trong `main.py`
  - Hoặc edit `init-schema.sql` thủ công + lo redeploy
  - Cả 2 đều **không reversible** và không track history.

**Impact.** Đây là lý do tại sao mỗi lần upgrade gần đây phải nhắc anh "đợi Railway deploy + chạy idempotent migration ở startup". Khi schema lớn hơn 10 cột mới thì block SQL trong main.py sẽ trở thành 1 file 200 dòng không ai dám đụng.

**Fix (~2 tiếng) — chuyển sang Alembic đầy đủ:**

```bash
# 1. Stamp baseline
cd 09-implementation/backend
alembic revision --autogenerate -m "baseline_v04"
# → Sẽ tạo file 0001_baseline_v04.py với toàn bộ schema hiện tại

# 2. Mark DB production đã ở baseline (vì DB đã tồn tại)
alembic stamp head

# 3. Tắt idempotent block trong main.py — Alembic sẽ thay thế
# 4. Update Dockerfile entrypoint:
#    - Thay `psql -f init-schema.sql` bằng `alembic upgrade head`

# 5. Mọi schema change từ giờ:
alembic revision --autogenerate -m "add_refresh_tokens"
# Edit file generated, kiểm tra, commit, deploy → alembic upgrade head ở startup
```

**Lợi ích lớn:** rollback được, history track được, dev mới có thể reset DB local + `alembic upgrade head` là xong.

---

## P1 — HIGH (nên fix trong Sprint 1)

### P1-1. JWT secret và config production yếu

`app/config.py:37`:
```python
jwt_secret_key: str = "change-me-to-random-32-byte-string"
```

Default này nguy hiểm — nếu Railway env var `JWT_SECRET_KEY` không set hoặc bị xóa nhầm thì attacker có thể forge token. **Verify ngay** Railway dashboard có set `JWT_SECRET_KEY`. Đề xuất:
- Đổi default thành chuỗi rỗng + raise `RuntimeError` ở startup nếu rỗng và `app_env=="production"`.
- Memory ghi token expire 8h, code default 24h — chọn 1 và stick với nó (recommend 1h access + 7d refresh sau khi có refresh token).

### P1-2. `download_file` endpoint là PUBLIC — auth bypass có chủ đích nhưng không an toàn

`routers/submissions.py:190-222`:
```python
@submissions_router.get("/files/{file_id}/download")
async def download_file(...):
    """Public access (không cần auth — cho phép preview chia sẻ).
    Production: nên check perm + signed URL."""
```

File submission của SV đang public — **bất kỳ ai biết `file_id` là số từ 1 đến N đều download được tất cả file của tất cả SV trong tất cả contest**. Có 2 hướng fix:

1. (nhanh) Thêm `CurrentUser` dep + check user là owner/judge/organizer/admin.
2. (đúng) Generate signed URL HMAC có TTL ngắn.

### P1-3. Pool size có thể vượt Railway hobby plan

`database.py`: `pool_size=10, max_overflow=20` → 30 conn cho main pool
`audit.py`: `pool_size=2, max_overflow=2` → 4 conn cho audit pool

Tổng 34 conn. Railway hobby plan PostgreSQL allow ~22-25 conn (theo doc). Hiện tại trafic thấp nên không thấy nhưng nếu có 1 burst, sẽ thấy `OperationalError: too many connections`. Đề xuất:
- Set `pool_size=5, max_overflow=10` (= 15 main) + giữ 4 audit = 19 total → safe.
- Hoặc nâng plan lên Pro (~$5-20/tháng).

### P1-4. FK cascade order: xóa contest có thể conflict (potential, không phải actual)

Xét các FK liên quan khi DELETE 1 contest:

| Table | Column | ondelete |
|---|---|---|
| `contest_entries.contest_id` | → contests | CASCADE |
| `contest_entries.team_id` | → teams | **RESTRICT** |
| `teams.contest_id` | → contests | CASCADE |
| `teams.leader_student_id` | → students | RESTRICT |

PostgreSQL deferred cascade thường handle trong 1 transaction, nhưng order CASCADE là từ cha xuống — `entries` và `teams` cùng cấp con của `contest`. Nếu PG xóa `teams` trước → `entries.team_id RESTRICT teams` chặn → rollback. Hiện tại business logic `delete_contest` đã guard "chỉ DRAFT + no entries" nên **không hit thực tế**, nhưng nếu sau này admin cho phép force-delete thì sẽ bug.

**Fix (~10 phút):** đổi `contest_entries.team_id` từ `RESTRICT` → `CASCADE` (entry không nên tồn tại nếu team không còn).

### P1-5. Service worker cache làm anh thấy old UI

Đây là issue khá ổn rồi nhưng vẫn nên ghi lại: mỗi lần deploy Netlify, anh phải hard refresh (Ctrl+Shift+R) + unregister SW + clear caches mới thấy version mới. Fix dài hạn:
- Thêm `version` query param vào tên bundle (`main.dart.js?v=20260506`)
- Hoặc tắt service worker cho web build với `--web-renderer html --pwa-strategy=none`

### P1-6. Rate limit chưa có

Hiện tại `/api/auth/login` ai cũng có thể brute force pass. Memory đã ghi nhận ở TIER 1 (slowapi+Redis 1 ngày, ROI 10). Với refresh token sắp làm trong Phase 1, **rate limit phải có trước**, không thì attacker sẽ brute force qua login + refresh để keep session.

---

## P2 — MEDIUM (Sprint 2-3)

### P2-1. `requires_submission` boolean trên contest nhưng không enforce

Schema có `contests.requires_submission BOOLEAN`. Nhưng business logic không check: SV có thể nộp bài cho contest có `requires_submission=false` (lãng phí storage), hoặc skip nộp bài cho contest `requires_submission=true` mà vẫn được chấm. Nên enforce trong `submission_service.add_my_version` và `judging_service.compute_results`.

### P2-2. `system_configs` seed có URL localhost cho production

```sql
('certificate.qr_verify_url_base','http://localhost/verify/', 'STRING', ...)
```

→ Cert in HTML sẽ hiển thị `http://localhost/verify/{qr}` — không scan được trên điện thoại thật. Update seed để default về `https://luxury-crostata-3c5c69.netlify.app/verify/`.

### P2-3. `app_users.gender VARCHAR(10)` không có CHECK constraint

Comment ghi "Nam / Nữ / Khác" nhưng không enforce. SV có thể đẩy "M", "Female", "blah" qua API. Đề xuất CHECK constraint hoặc đổi sang ENUM.

### P2-4. `Submission.is_locked` boolean + status `LOCKED` enum — duplicate state

Có khả năng `is_locked=true` mà `status != LOCKED`. Cleanup: chọn 1 nguồn truth (recommend dùng `status` only).

### P2-5. `team_members.is_leader` duplicate với `teams.leader_student_id`

Có 2 unique index ngầm bảo vệ (1 leader/team) nhưng vẫn có khả năng inconsistent. Tracking: trigger hoặc invariant test.

### P2-6. Ngày tháng — tất cả đang TIMESTAMPTZ nhưng FE đôi khi gửi string không có TZ

Hiện Dio + Pydantic handle OK, nhưng test với input "2026-05-06T08:00:00" (naive) vs "2026-05-06T08:00:00+07:00" (aware) — kết quả lưu DB có thể lệch 7h. Recommend FE luôn gửi ISO + TZ.

### P2-7. `SubmissionFile.file_url NOT NULL` mâu thuẫn với flow upload BYTEA

Schema yêu cầu `file_url NOT NULL`, code set placeholder rồi UPDATE. Nếu transaction rollback giữa flush + update → giữ placeholder rác. Đề xuất:
- Đổi `file_url` thành nullable, hoặc
- Set giá trị thật ngay từ INSERT (cần generate file_id trước → dùng `nextval(seq)`)

---

## P3 — LOW / TECHNICAL DEBT

| # | Vấn đề | Effort |
|---|---|---|
| P3-1 | TODO ở `auth.py:52` — audit row cho login (đã có middleware, nhưng login endpoint trong skip pattern) | 15p |
| P3-2 | TODO ở `entry_service.py:151` — check `cancel.min_days_before` config | 30p |
| P3-3 | TODO ở `result_service` — bulk notification thật khi publish results | 1h |
| P3-4 | `db_echo: bool = False` — bật khi debug nhưng không có structured logging | 2h |
| P3-5 | Không có `request_id` trace cross-service | 2h |
| P3-6 | CORS regex permit `*.netlify.app, *.vercel.app` — quá rộng cho production | 10p |
| P3-7 | Bcrypt rounds 12 ổn cho 2024, 2026 nên nâng 13 | 5p |
| P3-8 | Dockerfile copy `init-schema.sql` không dùng .dockerignore filter | 5p |

---

## Kết quả audit theo nhánh

### 1. Database schema (43 bảng)

**Vững:**
- ENUM types đầy đủ + match Python `enums.py` 1-1
- CHECK constraints tốt: `chk_contest_time`, `chk_team_member_range`, `chk_entry_target`, `chk_revoke_consistent`
- Partial unique index xuất sắc: `uq_dept_one_primary_approver`, `uq_team_one_leader`, `uq_contest_active_template`, `uq_contest_individual_entry`, `uq_contest_team_entry`, `idx_issued_certs_active`
- Trigger `set_updated_at()` áp dụng đúng cho mọi bảng cần
- Indexes coverage tốt cho query patterns chính (status, FK joins, time-range)

**Yếu:**
- Schema canonical drift (P0-1)
- FK cascade tiềm năng conflict (P1-4)
- Một số CHECK còn thiếu (P2-3)
- Duplicate state fields (P2-4, P2-5)

### 2. Backend FastAPI

**Vững:**
- 102 routes phân chia rõ ràng theo 14 router (auth/users/contests/approvals/entries/teams/submissions/judging/results/reviews/notifications/certificates/reports/admin)
- Service layer thuần, không leak ORM
- Async pattern nhất quán với SQLAlchemy 2.0
- Authorization helpers (`_ensure_organizer`, `_ensure_btc_or_hod`,...) DRY tốt
- Error message tiếng Việt thân thiện
- Conditional `_STRUCTURE_EDITABLE_STATUSES` chứa `ONGOING` cho phép thêm round phụ — chuyên nghiệp

**Yếu:**
- Routing bug cert verify (P0-2)
- Audit middleware throughput (P0-3)
- JWT secret default unsafe (P1-1)
- File download public (P1-2)
- Pool size có thể vượt Railway hobby (P1-3)
- 4 TODO chưa giải quyết (P3-1 đến P3-3)

### 3. Frontend Flutter

**Vững:**
- 27 screen file phân chia theo `lib/features/{auth,student,admin,...}/`
- Conditional import sạch: `local_storage_stub.dart` + `local_storage_web.dart` qua `dart.library.html`
- TokenStorage dual-mode đúng pattern: secure storage trên mobile, fallback localStorage trên web (vì LAN HTTP không secure storage)
- Riverpod 2.6 + go_router 14 + Dio 5.7 đều phiên bản mới
- google_fonts, file_picker, jwt_decoder cài đầy đủ

**Yếu:**
- Service Worker cache khi deploy (P1-5) — UX dev khó chịu
- Không có offline mode / loading skeleton (đã trong roadmap Phase 2)
- Không có deep-link cho notification (đã trong TIER 1 backlog)

### 4. Migration / Deploy

**Vững:**
- Dockerfile đa tầng + entrypoint check schema có sẵn → skip init nếu đã có
- Railway auto-deploy on git push hoạt động
- Idempotent ALTER TABLE trong lifespan giải quyết được cho 10 cột bổ sung

**Yếu:**
- Half-Alembic (P0-4) — **đây là rủi ro #1 cho upgrade**
- init-schema.sql drift khỏi production (P0-1)
- Không có CI test gate trước khi deploy
- Không có healthcheck endpoint sâu (chỉ có `/health` trả `{ok}`, không check DB)
- Không có rollback strategy nếu deploy fail

---

## Hành động đề xuất TRƯỚC khi vào Phase 1

Dựa trên priority list bên trên, em đề xuất thực hiện theo thứ tự sau, tổng **~1.5 ngày**:

### Sprint 0 — Stabilization (1.5 ngày, 4 P0 + 3 P1)

| Bước | Task | Time | File chính bị sửa |
|---|---|---|---|
| 1 | Fix P0-2 cert verify (1 dòng + smoke test) | 15p | `app/main.py` |
| 2 | Fix P1-2 download_file auth (5 dòng) | 30p | `routers/submissions.py` |
| 3 | Fix P1-1 JWT default + check production env | 30p | `app/config.py`, `Dockerfile` |
| 4 | Fix P0-3 audit middleware queue + worker | 1h | `middleware/audit.py`, `main.py` |
| 5 | Fix P1-3 pool size config | 15p | `database.py`, `middleware/audit.py` |
| 6 | Fix P0-1 schema canonical: viết v04 inline 10 cột mới + update init-schema.sql | 1h | `08-database/v04.sql`, `init-schema.sql`, gỡ idempotent block |
| 7 | Fix P0-4 Alembic: stamp baseline + setup workflow | 2h | `alembic/versions/0001_baseline.py`, `Dockerfile entrypoint`, `main.py` |
| 8 | Smoke test E2E: login + tạo contest + register + nộp bài + chấm + cert | 1h | — |
| 9 | Update memory checkpoint với findings + fixes | 15p | `project_cnpm_status_2026-05.md` |

Sau Sprint 0, dự án sẽ ở trạng thái **Xanh** thật sự, có thể merge feature mới mà không lo "schema lệch" hay "audit pool sập".

### Sprint 1 (Phase 1 chính thức) — 1.5 tuần như roadmap

Có thể bắt đầu ngay sau Sprint 0:
1. Sentry (1 ngày)
2. Rate limit slowapi+Redis (1 ngày) — P1-6
3. Refresh token (2 ngày)
4. Email service production (2 ngày)
5. HSTS HTTPS-only (1 ngày)

---

## Phụ lục A — Checklist nâng cấp an toàn

Khi merge bất kỳ feature schema-change nào sau Sprint 0:

```
[ ] Tạo Alembic migration: alembic revision --autogenerate -m "feature_xxx"
[ ] Review file generated, sửa naming convention nếu cần
[ ] Test local: alembic downgrade -1 && alembic upgrade head
[ ] Update Pydantic schema + ORM model
[ ] Update OpenAPI doc nếu thêm endpoint
[ ] Smoke test trên local trước khi push
[ ] Push → Railway → quan sát log: alembic upgrade head succeed
[ ] Curl healthcheck: /health
[ ] Curl 1 endpoint quan trọng để verify schema mới hoạt động
[ ] Update file 11-docs/CHANGELOG.md
```

## Phụ lục B — Lệnh test sau Sprint 0

```bash
# Backend
cd 09-implementation/backend
alembic current                              # phải hiện 0001_baseline_v04
alembic check                                # phải PASS (no pending changes)
pytest tests/                                # nếu có test

# DB integrity
psql $DATABASE_URL -c "
SELECT COUNT(*) AS orphan_entries
FROM ptit_contest.contest_entries e
WHERE e.team_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM ptit_contest.teams t WHERE t.team_id = e.team_id);
"  # → 0
psql $DATABASE_URL -c "
SELECT column_name FROM information_schema.columns
WHERE table_schema='ptit_contest' AND table_name='app_users'
ORDER BY ordinal_position;
"  # → phải có đủ 21 cột (12 gốc + 9 profile)

# API smoke
curl https://ptit-contest-mobile-app-production.up.railway.app/health
curl https://ptit-contest-mobile-app-production.up.railway.app/api/verify/I1TfZL2Ub7ZeFsixryGgOcq0FHpWKCmHikMGphk_asI
# Phải trả 200 với { valid: true, ... }
```

---

**Tổng kết:** Dự án đã đi xa và làm đúng nhiều thứ (43 bảng có constraint vững, 102 endpoint phân lớp clean, Frontend responsive 2 chiều). Vấn đề là về **migration discipline** — đã đến lúc chuyển từ "idempotent ALTER trong lifespan" sang "Alembic baseline + sau đó autogenerate". 1.5 ngày Sprint 0 sẽ unlock 9 tuần Phase 1-4 đi mượt.
