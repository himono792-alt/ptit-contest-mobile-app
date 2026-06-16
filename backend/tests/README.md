# Backend tests

Bộ test tích hợp cho FastAPI backend. **Không cần Docker / Postgres cài sẵn / quyền root** —
`conftest.py` tự bật một PostgreSQL nhúng (user-space, gói `pgserver`), nạp `init-schema.sql`
(schema thật v04) rồi seed dữ liệu demo (`scripts/seed-demo.py`).

## Chạy

```bash
cd backend
pip install -e ".[dev]"     # cài pytest + pgserver + httpx
pytest -v
```

Lần đầu `pgserver` tải binary Postgres (~vài chục MB), các lần sau chạy offline.

## Cấu trúc

| File | Bao phủ |
|------|---------|
| `test_smoke.py` | App khởi tạo, `/health`, OpenAPI spec, validation 422. |
| `test_auth.py` | Login đúng/sai, `/me` trả role chính xác (SV/GV/BCN/Admin), refresh token, RBAC (SV không vào được endpoint admin). |
| `test_contests_workflow.py` | List/detail cuộc thi, filter theo status, BCN thấy queue duyệt QĐ1, SV bị chặn khỏi queue. |
| `test_publish_notification.py` | **Fix B** — publish kết quả tạo notification thật cho mọi SV đăng ký APPROVED, `notified_count` đúng, deep-link `/contests/{id}`, loại entry PENDING/CANCELLED. |

## Ghi chú kỹ thuật

- Engine test dùng `NullPool` (mỗi connection mở/đóng tươi) để tránh lỗi asyncpg
  "event loop is closed" khi pytest dùng event loop khác nhau giữa các test.
- `citext` extension không có trong bản Postgres nhúng → conftest shim bằng `DOMAIN text`
  (đủ cho test; production vẫn dùng extension `citext` thật trong `init-schema.sql`).
- Rate limit bị tắt trong test (`limiter.enabled = False`) để login nhiều lần không bị 429.
