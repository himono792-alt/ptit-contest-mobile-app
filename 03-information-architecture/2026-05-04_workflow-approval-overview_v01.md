# Workflow Phê duyệt 2 cấp BTC ↔ BCN — Overview

**Phiên bản:** v01 (2026-05-04)
**Schema reference:** `ptit_contest` v03
**File liên quan trong folder này:**
- `2026-05-04_sequence-bcn-qd1-proposal_v01.mermaid` — Sequence QĐ1 (đề xuất cuộc thi)
- `2026-05-04_sequence-bcn-qd2-result_v01.mermaid` — Sequence QĐ2 (kết quả chung cuộc)
- `2026-05-04_state-contest-status_v01.mermaid` — State machine `contest_status`

---

## 1. Tóm tắt workflow

Hệ thống có **2 cấp phê duyệt** từ BTC (Giảng viên) lên BCN (Ban Chủ nhiệm khoa). Mỗi cấp là 1 quyết định riêng, lưu trong cùng bảng `workflow_approvals` nhưng phân biệt bằng cột `target_type` + `step`:

| Quyết định | target_type | step | Khi nào | Bảng bị ảnh hưởng |
|---|---|---|---|---|
| **BCN_QĐ1** | `CONTEST_PROPOSAL` | `BCN_QD1` | BTC submit cuộc thi mới | `contests.status` |
| **BCN_QĐ2** | `CONTEST_RESULT` | `BCN_QD2` | BTC chốt xong kết quả | `contest_results.bcn_approval_status` |

Cả 2 đều **hỗ trợ revision loop** thông qua cột `revision_round`. Nếu BCN yêu cầu chỉnh sửa, BTC sửa rồi submit lại → tạo bản ghi MỚI trong `workflow_approvals` với `revision_round` tăng dần (1 → 2 → 3...). Bản ghi cũ giữ nguyên để audit.

---

## 2. Cách đọc 3 diagram

### `sequence-bcn-qd1-proposal_v01.mermaid`

Cover **toàn bộ flow đề xuất cuộc thi**, từ lúc BTC tạo DRAFT đến khi PUBLISHED. Chia 6 section:
- **A.** BTC tạo + soạn thảo contest (DRAFT)
- **B.** BTC submit lần đầu (revision_round = 1)
- **C.** BCN xem queue + chi tiết
- **D.** Happy path: BCN APPROVE → contest PUBLISHED
- **E.** Revision loop: BCN request_revision → BTC sửa → re-submit (revision_round = 2)
- **F.** Reject hoàn toàn: BCN REJECT → contest về DRAFT

### `sequence-bcn-qd2-result_v01.mermaid`

Cover **flow công bố kết quả**, từ lúc BTC tổng hợp điểm các round đến khi SV thấy kết quả trên app. Chia 6 section:
- **A.** BTC compute final_score từ `round_results` → `contest_results`
- **B.** BTC submit kết quả cho BCN duyệt
- **C.** BCN xem queue + ranking
- **D.** Happy path: BCN APPROVE
- **E.** BTC publish → notify SV bulk → SV xem được + tải certificate
- **F.** Revision loop (tương tự QĐ1)

### `state-contest-status_v01.mermaid`

State machine cho **9 trạng thái** của `contest_status_enum`:
- DRAFT → PROPOSED → REVISION_REQUESTED ↔ PROPOSED → PUBLISHED
- PUBLISHED → REG_OPEN → REG_CLOSED → ONGOING → FINISHED
- CANCELLED có thể vào từ bất kỳ state nào (Admin emergency)

Highlight pre-condition để chuyển từ `ONGOING → FINISHED`:
1. `now() > contest.end_at`
2. `workflow_approvals(BCN_QD2).status = APPROVED`
3. `contest_results.published_at IS NOT NULL`

Thiếu 1 trong 3 → vẫn ở ONGOING.

---

## 3. Mapping ↔ Schema

### Bảng `workflow_approvals` (39-47 trong `sqlapp_v03.sql`)

| Cột | Vai trò trong workflow |
|---|---|
| `target_type` | Phân biệt QĐ1 vs QĐ2 |
| `step` | Bằng `BCN_QD1` cho proposal, `BCN_QD2` cho result. CHECK constraint enforce |
| `status` | PENDING / APPROVED / REJECTED / REVISION_REQUESTED |
| `revision_round` | 1, 2, 3, ... — tăng mỗi lần BTC re-submit |
| `submitted_by` | user_id của BTC |
| `reviewed_by` | user_id của BCN |
| `bcn_comment` | Lý do approve/reject/revision |
| `snapshot_json` | JSON snapshot key fields tại thời điểm submit (audit + so sánh diff giữa các revision) |
| UNIQUE `(contest_id, target_type, revision_round)` | Mỗi lần submit là 1 record duy nhất |

### Bảng `contests` — các cột liên quan

- `status` — sync với state diagram
- `proposed_by` — BTC nào đề xuất (= `created_by` lần đầu, có thể khác nếu multiple BTC)
- `host_faculty_id` — quyết định **BCN nào** có quyền duyệt (BCN của khoa nào → check qua `department_heads.faculty_id`)

### Bảng `contest_results` — cột liên quan

- `bcn_approval_status` — denormalize từ `workflow_approvals` để query nhanh "kết quả này đã được BCN duyệt chưa"
- `published_at` — timestamp BTC public ra

---

## 4. RBAC chi tiết — ai làm được gì

| Action | Endpoint | Role required | Scope check |
|---|---|---|---|
| Tạo contest | `POST /api/contests` | `ORGANIZER` | — |
| Edit contest (DRAFT/REVISION_REQUESTED) | `PATCH /api/contests/{id}` | `ORGANIZER` | `created_by = self` HOẶC trong `contest_organizers` |
| Submit cho BCN duyệt | `POST /api/contests/{id}/submit-for-approval` | `ORGANIZER` | Same as edit |
| Xem queue chờ duyệt | `GET /api/me/pending-approvals` | `HOD` | filter `host_faculty_id = department_heads.faculty_id` |
| Duyệt approval | `POST /api/approvals/{id}/decide` | `HOD` | Same as queue + `is_primary_approver = TRUE` (nếu enforce) |
| Compute results | `POST /api/contests/{id}/results/compute` | `ORGANIZER` | Same as edit + contest đã có round_results |
| Submit results cho BCN | `POST /api/contests/{id}/results/submit-for-approval` | `ORGANIZER` | Same |
| Publish results | `POST /api/contests/{id}/results/publish` | `ORGANIZER` | + check `workflow_approvals(BCN_QD2).status = APPROVED` |

---

## 5. Edge cases cần test (cho QA)

### Workflow QĐ1
1. **Revision loop 3 lần** — submit → request_revision → submit lại → request_revision → submit lại → APPROVED. Kiểm tra `revision_round` tăng đúng 1→2→3, mỗi record có snapshot riêng.
2. **BTC sửa contest khi đang PROPOSED** — backend phải reject (chỉ cho sửa khi DRAFT/REVISION_REQUESTED).
3. **BCN khoa khác cố duyệt** — BCN khoa A không được duyệt contest của khoa B. Backend filter `department_heads.faculty_id = contests.host_faculty_id`.
4. **Race condition: 2 BCN cùng khoa duyệt cùng lúc** — phải có row-level lock hoặc dùng `UPDATE ... WHERE status='PENDING'` để phát hiện.
5. **REJECT rồi DELETE** — sau khi reject, BTC có quyền DELETE contest không? (chỉ cho phép nếu không có `contest_entries`).

### Workflow QĐ2
6. **Publish khi chưa APPROVE** — backend phải trả 403, không cho publish.
7. **BCN approve rồi BTC sửa rank** — sau khi APPROVED nếu BTC PATCH contest_results, có cần re-approve không? **Đề xuất:** YES, mọi thay đổi sau APPROVED đều reset về PENDING + tạo workflow_approvals mới.
8. **Notify SV bulk khi publish** — test với contest 100+ entries, đảm bảo background job không block API.
9. **SV không có result (đã hủy đăng ký)** — không nhận notify "Kết quả đã có" để tránh spam.

### State diagram
10. **Auto transition** — REG_OPEN/CLOSED/ONGOING/FINISHED chuyển dựa trên `now()` so với timestamp. Cần scheduled job (vd: Celery beat hoặc systemd timer) chạy mỗi 5 phút check.
11. **CANCELLED ở mọi state** — Admin có quyền cancel bất cứ lúc nào, nhưng phải xử lý refund đăng ký nếu sau REG_OPEN.

---

## 6. Cho dev (FastAPI implementation tips)

### Routers structure
```
app/routers/
  contests.py          # CRUD contests + rounds + sessions
  approvals.py         # GET pending-approvals, POST decide
  results.py           # compute, submit-for-approval, publish
```

### Service layer
```python
# app/services/approval_service.py

def submit_for_approval(contest_id: int, target_type: str, user_id: int) -> int:
    """Tạo workflow_approvals record mới (revision_round = max+1)."""
    with db.transaction():
        max_rev = db.query("SELECT COALESCE(MAX(revision_round),0) FROM workflow_approvals WHERE contest_id=:c AND target_type=:t",
                            c=contest_id, t=target_type)
        approval_id = db.execute("INSERT INTO workflow_approvals (...) VALUES (...) RETURNING approval_id",
                                 revision_round=max_rev+1, ...)
        # Update contest.status hoặc contest_results.bcn_approval_status
        if target_type == 'CONTEST_PROPOSAL':
            db.execute("UPDATE contests SET status='PROPOSED' WHERE contest_id=:c", c=contest_id)
        return approval_id

def decide(approval_id: int, action: str, comment: str, bcn_user_id: int):
    """action ∈ {approve, reject, request_revision}"""
    status_map = {
        'approve': 'APPROVED',
        'reject': 'REJECTED',
        'request_revision': 'REVISION_REQUESTED',
    }
    new_status = status_map[action]
    with db.transaction():
        db.execute("UPDATE workflow_approvals SET status=:s, reviewed_by=:u, reviewed_at=NOW(), bcn_comment=:c WHERE approval_id=:id",
                   s=new_status, u=bcn_user_id, c=comment, id=approval_id)
        # Side effect: update contest.status / contest_results.bcn_approval_status
        ...
```

### Snapshot JSON schema (cho `workflow_approvals.snapshot_json`)

**For CONTEST_PROPOSAL:**
```json
{
  "title": "...",
  "description": "...",
  "rules_text": "...",
  "delivery_mode": "ONLINE",
  "start_at": "2026-05-15T08:00:00Z",
  "end_at": "2026-05-15T17:00:00Z",
  "rounds": [{"round_no": 1, "round_name": "Vòng loại", ...}],
  "sessions": [...]
}
```

**For CONTEST_RESULT:**
```json
{
  "results": [
    {"entry_id": 5, "final_score": 95.5, "rank_no": 1, "award_title": "Giải Nhất"},
    {"entry_id": 8, "final_score": 92.0, "rank_no": 2, "award_title": "Giải Nhì"},
    ...
  ]
}
```

Snapshot này dùng để:
- Hiển thị "diff" giữa các revision (BCN xem so với lần trước BTC sửa gì)
- Audit/rollback nếu cần

---

## 7. Cho frontend (Flutter Web tips)

### Component states cho mỗi role

**BTC view:**
- DRAFT → enable edit toàn bộ + nút "Submit"
- PROPOSED → disable edit + hiển thị "Đang chờ BCN duyệt" + button "Withdraw" (rút lại)
- REVISION_REQUESTED → enable edit + hiển thị `bcn_comment` đỏ + nút "Re-submit"
- PUBLISHED+ → read-only

**BCN view:**
- Pending list: card hiển thị contest title + revision_round + thời gian submit
- Detail: form view + 3 nút (Approve / Request Revision / Reject) + textbox comment
- Approved/Rejected list: history view

### Routing render theo role (từ JWT)

```dart
// router_config.dart
if (user.hasRole('STUDENT')) → routes for SV (mobile APK only)
if (user.hasRole('ORGANIZER')) → routes for GV
if (user.hasRole('HOD')) → routes for BCN (web only, sidebar layout)
if (user.hasRole('ADMIN')) → routes for Admin
```

---

## 8. Render diagrams

Các file `.mermaid` render được trong:
- VS Code (cài extension "Markdown Preview Mermaid Support")
- GitHub (auto render trong markdown preview hoặc khi mở `.mermaid` directly)
- Notion (paste code vào code block kiểu mermaid)
- Mermaid Live Editor: https://mermaid.live (paste content)

Để export PNG/SVG cho báo cáo .docx, dùng `mmdc`:
```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i 2026-05-04_sequence-bcn-qd1-proposal_v01.mermaid -o output.png -w 1600
```

---

**Sources:**
- Schema: `08-database/2026-05-04_sqlapp_v03.sql` (workflow_approvals table)
- ER diagram: `08-database/2026-05-04_er-diagram_v02.mermaid`
- Traceability matrix: `02-requirements/2026-05-04_traceability-matrix_v02.md` (BCN-02, BCN-04, GV-02, GV-06)
