# Thiết kế logic phúc khảo kết quả (Result Appeal) — v01

**Ngày:** 2026-06-27 · **Trạng thái:** Spec để chốt (chưa code) · **Phạm vi:** logic nghiệp vụ + state machine + endpoint + RBAC + edge case

---

## 0) Hiện trạng (đã rà soát codebase)

Phúc khảo **mới chỉ có khung dữ liệu**, chưa có nghiệp vụ:

| Tầng | Có sẵn? | Vị trí |
|---|---|---|
| Bảng `result_appeals` | ✅ | `backend/init-schema.sql:675` |
| Model `ResultAppeal` | ✅ | `backend/app/models/judging.py:136` |
| Enum `AppealStatus` (PENDING/IN_REVIEW/ACCEPTED/REJECTED/CLOSED) | ✅ | `backend/app/models/enums.py:101` |
| Trigger `updated_at` | ✅ | `init-schema.sql:691` |
| Schema Pydantic | ❌ | — |
| Router / endpoint | ❌ | `result_appeals`/appeal = 0 hit trong routers |
| Service nghiệp vụ | ❌ | — |
| UI Flutter (SV gửi / GV-BCN xử lý) | ❌ | 0 hit trong `frontend/lib` |

Cột bảng `result_appeals`: `appeal_id, contest_id, round_id(null), entry_id, submitted_by_student_id, title, content_text, status, response_text, handled_by, handled_at, created_at, updated_at`.

→ Thiết kế dưới đây **bám sát đúng các cột đã có**, không đề xuất đổi schema trừ khi nêu rõ ở mục 9.

---

## 1) Luồng kết quả hiện tại (để biết phúc khảo "chèn" vào đâu)

```
Judge chấm (scores → judge_assignments)
   └─ GV-05 compute round_results (total/avg + rank)
        └─ GV-06 compute contest_results (final_score, rank_no, award_title,
                                          bcn_approval_status=PENDING)
             └─ GV-06 submit-for-approval → WorkflowApproval(CONTEST_RESULT, BCN_QD2, PENDING)
                  └─ BCN decide → APPROVED
                       └─ GV-06 publish → published_at=now, contest.status=FINISHED,
                                          bulk-notify SV (in-app + deep-link)
                            └─ GV/BCN issue_certificates (cần APPROVED + published_at)
```

**Điểm mấu chốt:** kết quả chỉ "thật" sau khi **BCN duyệt (BCN_QĐ2) + GV publish**. Cert chỉ cấp sau publish và có sẵn cơ chế **revoke** (`issued_certificates.revoked_at/revoked_by/revoke_reason`). Đây là lý do phúc khảo phải tôn trọng vòng duyệt 2 cấp: **sửa kết quả ⇒ phải duyệt lại ⇒ publish lại ⇒ thu hồi & cấp lại cert.**

---

## 2) Định nghĩa & nguyên tắc

**Phúc khảo (Result Appeal):** yêu cầu của SV xem xét lại **điểm/thứ hạng/giải** của *entry mình tham gia* sau khi kết quả đã **published**.

Nguyên tắc thiết kế:

1. **Chỉ mở sau publish.** Trước publish kết quả chưa chính thức → SV chưa có cơ sở phúc khảo. (Thắc mắc trước publish đi qua kênh Q&A/Review `SV-11`, không phải phúc khảo.)
2. **Có cửa sổ thời gian.** Chỉ nhận phúc khảo trong `APPEAL_WINDOW_DAYS` ngày kể từ `published_at`. Hết hạn → đóng kênh.
3. **Một entry — một phúc khảo đang mở.** Chống spam: không tạo mới khi entry còn appeal ở trạng thái PENDING/IN_REVIEW.
4. **Tôn trọng workflow 2 cấp.** Mọi thay đổi điểm/kết quả sau phúc khảo phải re-submit BCN_QĐ2 và re-publish; cert liên quan bị revoke + cấp lại.
5. **Bất biến lịch sử (audit).** Không xoá appeal; chỉ chuyển trạng thái. `response_text` + `handled_by` + `handled_at` lưu vết người xử lý.

---

## 3) Ai gửi — ai xử lý (RBAC)

| Hành động | Vai trò | Ghi chú |
|---|---|---|
| Gửi phúc khảo | **SV (STUDENT)** sở hữu entry | INDIVIDUAL: chính chủ. TEAM: **đội trưởng** (leader) đại diện gửi |
| Xem phúc khảo của mình | SV chủ entry | |
| Tiếp nhận + chấm lại (chuyên môn) | **GV/BTC (ORGANIZER)** của contest | Người gần điểm nhất, xử lý nội dung |
| Giám sát / quyết định cuối nếu đổi kết quả | **BCN/HOD** khoa host | Qua vòng duyệt BCN_QĐ2 revision |
| Xem toàn bộ (đọc) | Admin | Chỉ đọc/thống kê |

> **Quyết định cần chốt (mục 9 – Q1):** ai là người "handled_by" chính — **GV/BTC** (đề xuất) hay **BCN**. Đề xuất: **GV/BTC xử lý chuyên môn**, BCN chỉ vào cuộc khi kết quả thay đổi (vì BCN là tầng duyệt, không nên là tầng tiếp nhận đơn lẻ).

---

## 4) State machine phúc khảo

Dùng đúng 5 trạng thái enum đã có:

```
            (SV gửi)
              │
              ▼
          ┌───────┐   GV tiếp nhận    ┌──────────┐
          │PENDING│ ───────────────▶  │IN_REVIEW │
          └───────┘                   └──────────┘
              │                          │      │
   (SV rút / hết hạn,                    │      │
    GV từ chối sớm)                      │      │
              │                 GV kết luận:     │
              │            ┌────────────┘        └───────────┐
              ▼            ▼                                  ▼
          ┌──────┐    ┌─────────┐  (đổi điểm)           ┌─────────┐
          │CLOSED│    │ACCEPTED │ ─── re-judge ───┐     │REJECTED │
          └──────┘    └─────────┘                 │     └─────────┘
                          │ (đã cập nhật kết quả)  │          │
                          └──────────┬─────────────┘          │
                                     ▼                        ▼
                                 ┌──────┐                 ┌──────┐
                                 │CLOSED│                 │CLOSED│
                                 └──────┘                 └──────┘
```

**Bảng chuyển trạng thái:**

| Từ | Đến | Ai | Điều kiện | Hệ quả |
|---|---|---|---|---|
| (none) | PENDING | SV | Trong cửa sổ, entry hợp lệ, chưa có appeal mở | Tạo bản ghi, notify GV/BTC contest |
| PENDING | IN_REVIEW | GV/BTC | — | `handled_by=GV`, bắt đầu xử lý, notify SV |
| PENDING | CLOSED | SV | SV tự rút | Đóng, không tác động kết quả |
| PENDING/IN_REVIEW | REJECTED | GV/BTC | Có `response_text` (lý do) | Giữ nguyên kết quả, notify SV |
| IN_REVIEW | ACCEPTED | GV/BTC | Có `response_text` | Mở luồng re-judge (mục 5), notify SV |
| ACCEPTED | CLOSED | GV/BTC (auto) | Sau khi re-publish xong | Khoá đơn, kết quả mới hiệu lực |
| REJECTED | CLOSED | hệ thống (auto) | — | Đóng hồ sơ |

> CLOSED = trạng thái cuối, bất biến. ACCEPTED là "đã chấp nhận xem lại", còn việc kết quả có đổi hay không phụ thuộc re-judge; sau re-publish thì CLOSED.

---

## 5) Hệ quả khi ACCEPTED — đồng bộ với workflow 2 cấp

Đây là phần "khó" nhất và là lý do phải chốt kỹ. Khi GV ACCEPTED và **điểm thực sự thay đổi**:

```
GV sửa điểm (scores) cho entry bị phúc khảo
  └─ recompute round_results (total/avg + rank vòng đó)
       └─ recompute contest_results (final_score, rank_no, award_title)
            │   ⚠️ reset: bcn_approval_status = PENDING, published_at = NULL
            ▼
       GV submit-for-approval (BCN_QĐ2 — revision mới, revision_round++)
            └─ BCN duyệt lại → APPROVED
                 └─ GV publish lại → published_at=now (FINISHED giữ nguyên)
                      ├─ Revoke cert cũ của các entry bị ảnh hưởng (revoke_reason="Phúc khảo #<id>")
                      ├─ Issue lại cert theo kết quả mới
                      └─ Notify: SV phúc khảo + các SV bị đổi hạng/giải
  └─ Appeal → CLOSED, lưu response_text + handled_at
```

**Lưu ý hệ thống đã hỗ trợ sẵn:**
- `compute_contest_results` đã có logic "Reset approval status nếu đang APPROVED và compute lại" (`result_service.py:125`) → tự đưa về PENDING + `published_at=None`. Phúc khảo tái dùng đúng cơ chế này.
- `WorkflowApproval.revision_round` đã có → mỗi lần sửa là một revision, BCN thấy lịch sử.
- Cert có sẵn `revoke_*` → thu hồi cert sai, cấp lại cert đúng.

> **Quyết định cần chốt (Q2):** khi ACCEPTED nhưng **điểm không đổi** (GV xem lại thấy đúng) → vẫn ACCEPTED rồi CLOSED với `response_text` giải thích, **không** đụng workflow. Đề xuất: tách rõ "ACCEPTED nhưng giữ nguyên điểm" (không re-publish) vs "ACCEPTED + đổi điểm" (re-publish). Đề xuất gộp: dùng REJECTED cho "xem lại, điểm đúng, không đổi"; ACCEPTED chỉ khi **có** thay đổi. (Đơn giản hoá state, xem Q2.)

---

## 6) Điều kiện hợp lệ khi SV gửi (validation)

Khi `POST .../appeals`, kiểm tra tuần tự:

1. User là STUDENT.
2. Contest tồn tại & `status = FINISHED` & kết quả đã `published_at IS NOT NULL`.
3. Entry thuộc về SV này (INDIVIDUAL: student_id khớp; TEAM: SV là leader của team entry).
4. `now <= published_at + APPEAL_WINDOW_DAYS` (config; mặc định đề xuất **7 ngày**).
5. Chưa có appeal nào của entry này ở trạng thái PENDING/IN_REVIEW.
6. `title` (≤255) + `content_text` không rỗng.
7. (Tuỳ chọn) `round_id` nếu phúc khảo điểm 1 vòng cụ thể; null = phúc khảo kết quả chung.

Vi phạm → 400/403/409 với thông báo tiếng Việt rõ ràng (mẫu giống các service hiện có).

---

## 7) API đề xuất (REST, khớp pattern dự án)

### SV
| Method | Path | Mô tả |
|---|---|---|
| POST | `/api/contests/{contest_id}/appeals` | Gửi phúc khảo (body: `round_id?`, `entry_id`, `title`, `content_text`) |
| GET | `/api/me/appeals` | Danh sách phúc khảo của tôi (mọi contest) |
| GET | `/api/appeals/{appeal_id}` | Chi tiết (chủ đơn / GV contest / BCN / Admin) |
| POST | `/api/appeals/{appeal_id}/withdraw` | SV tự rút (PENDING → CLOSED) |

### GV/BTC + BCN
| Method | Path | Mô tả |
|---|---|---|
| GET | `/api/contests/{contest_id}/appeals` | Queue phúc khảo của contest (lọc theo status) |
| POST | `/api/appeals/{appeal_id}/start-review` | PENDING → IN_REVIEW |
| POST | `/api/appeals/{appeal_id}/resolve` | Kết luận: body `decision=ACCEPTED|REJECTED`, `response_text` |
| GET | `/api/me/appeals-inbox` | (GV) gom phúc khảo các contest mình phụ trách |

> Việc sửa điểm + re-submit BCN tái dùng **endpoint sẵn có** (`judging submit_scores`, `results/compute`, `results/submit-for-approval`, `results/publish`, `certificates/issue`). Không cần API mới cho phần đó — chỉ cần **gợi ý luồng** trên UI sau khi ACCEPTED.

---

## 8) Thông báo (notification)

Tái dùng `notification_service.notify_users(...)` (có sẵn deep-link `target_route`):

| Sự kiện | Người nhận | Nội dung |
|---|---|---|
| SV gửi phúc khảo | GV/BTC contest | "Có phúc khảo mới ở {contest}" → route queue |
| GV start-review | SV chủ đơn | "Phúc khảo của bạn đang được xem xét" |
| GV resolve (REJECTED) | SV chủ đơn | "Phúc khảo bị từ chối: {lý do}" |
| GV resolve (ACCEPTED) | SV chủ đơn | "Phúc khảo được chấp nhận, kết quả đang cập nhật" |
| Re-publish sau phúc khảo | SV chủ đơn + SV bị đổi hạng/giải | "Kết quả {contest} đã cập nhật" |

---

## 9) Quyết định đã CHỐT (2026-06-27)

| # | Câu hỏi | Chốt |
|---|---|---|
| **Q1** | Ai xử lý phúc khảo | **GV/BTC xử lý chuyên môn; BCN duyệt lại (BCN_QĐ2 revision) chỉ khi kết quả đổi.** `handled_by` = GV/BTC. |
| **Q2** | Điểm xem lại thấy đúng | **ACCEPTED = có đổi điểm (kéo theo re-judge + re-publish). Xem lại nhưng giữ nguyên → REJECTED + giải thích.** State 5 trạng thái giữ nguyên, không thêm cờ. |
| **Q3** | Cửa sổ thời gian | **BTC tự đặt deadline theo từng contest.** → thêm cột `appeal_deadline TIMESTAMPTZ NULL` vào bảng `contests`. Cho phép gửi khi `appeal_deadline IS NOT NULL AND now <= appeal_deadline`. NULL = chưa mở phúc khảo. |
| **Q4** | Phạm vi build | **Full backend + UI cùng lúc.** |

**Bổ sung do Q3=C — thay đổi schema:**
- `contests.appeal_deadline TIMESTAMPTZ NULL` (BTC đặt khi/ sau publish).
- Alembic migration mới (`0003_contest_appeal_deadline.py`) + cập nhật `init-schema.sql` + model `Contest`.
- API: BTC set qua `PATCH /api/contests/{id}` (hoặc field trong publish). UI BTC có ô chọn ngày hết hạn phúc khảo.
- Validation tạo appeal đổi từ "publish + N ngày" → so với `contest.appeal_deadline`.

---

## 10) Rủi ro & edge case đã tính

| Tình huống | Xử lý |
|---|---|
| Cert đã cấp rồi mới phúc khảo thắng | Revoke cert cũ (revoke_reason gắn appeal_id) + issue lại theo kết quả mới |
| Contest đã CANCELLED | Không nhận phúc khảo (chỉ FINISHED + published) |
| TEAM entry — nhiều thành viên cùng gửi | Chỉ leader gửi; ràng buộc "1 entry 1 appeal mở" chặn trùng |
| SV spam nhiều đơn | Ràng buộc PENDING/IN_REVIEW duy nhất per entry |
| Phúc khảo làm tụt hạng SV khác | Notify SV bị ảnh hưởng khi re-publish; lưu audit qua revision_round |
| BCN từ chối duyệt kết quả mới | Kết quả mới không published; appeal vẫn ACCEPTED nhưng chờ — cần trạng thái chờ duyệt (xem Q2/B nếu cần) |
| Hết hạn cửa sổ khi đơn đang IN_REVIEW | Đơn đang xử lý vẫn tiếp tục; cửa sổ chỉ chặn **tạo mới** |
| `published_at` reset khi recompute | Đã là cơ chế sẵn có; phúc khảo tái dùng, không phát sinh logic lạ |

---

## 11) Việc cần làm khi build (sau khi chốt Q1–Q4)

1. `schemas/appeal.py` — `AppealCreateIn`, `AppealOut`, `AppealResolveIn`, `AppealListItem`.
2. `services/appeal_service.py` — validate, create, start_review, resolve, withdraw, list (RBAC scope).
3. `routers/appeals.py` — 7 endpoint mục 7; đăng ký vào `app/main.py`.
4. (Nếu Q3=C) thêm cột `appeal_deadline`/config vào `contests`.
5. Notify hooks mục 8.
6. Test pytest: happy path + 6 edge case mục 10 (dùng `pgserver` như bộ test hiện có — xem memory test 2026-06-16).
7. UI Flutter (đợt sau / hoặc cùng nếu Q4=B): SV form gửi + "Phúc khảo của tôi"; GV queue + nút start-review/resolve.

---

## 12) ĐÃ TRIỂN KHAI (2026-06-27)

Sau khi chốt Q1–Q4, đã build full backend + UI:

**Backend**
- `models/contest.py` + `init-schema.sql` + Alembic `0004_contest_appeal_deadline.py`: cột `contests.appeal_deadline`.
- `schemas/appeal.py`: `AppealCreateIn / AppealResolveIn / AppealWindowIn / AppealOut`.
- `services/appeal_service.py`: create / list_my / withdraw / get (RBAC) / list_contest / start_review / resolve / set_appeal_window.
- `routers/appeals.py` (8 endpoint) + đăng ký `main.py`. `schemas/contest.py` ContestDetail thêm `appeal_deadline`.
- Notify: SV gửi → BTC; start-review/resolve → SV (deep-link `/me/appeals`).

**Frontend (Flutter)**
- `core/models/appeal.dart`.
- SV: `appeal_dialog.dart` (gửi) + `my_appeals_screen.dart` (danh sách + rút). Nút "Gửi phúc khảo" trên card Kết quả + action "Phúc khảo của tôi" ở app bar.
- GV: `admin/gv_appeals_screen.dart` (chọn contest FINISHED → đặt hạn phúc khảo + queue + Nhận xử lý/Chấp nhận/Từ chối) + nav item "Phúc khảo" trong sidebar GV.

**Test:** `backend/tests/test_appeals.py` — 8 test (happy ACCEPT/REJECT, no-window, quá hạn, không phải chủ entry, 1-đơn-mở, rút đơn, RBAC) **PASS** với Postgres nhúng (pgserver). Full suite 57 passed (1 fail `test_download_cert_pdf` chỉ do stub weasyprint trong sandbox, không liên quan).

**Còn lại để anh chạy trên máy:** `flutter analyze` (SDK không có trong sandbox) + build deploy + chạy migration `alembic upgrade head` cho DB cũ.
