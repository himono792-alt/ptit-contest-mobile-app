## Mô tả

Mô tả ngắn gọn thay đổi trong PR này.

## Loại thay đổi

- [ ] Bug fix (non-breaking)
- [ ] Feature mới (non-breaking)
- [ ] Breaking change (sẽ break existing API)
- [ ] Refactor (không thay đổi behavior)
- [ ] Performance improvement
- [ ] Docs only

## Endpoints affected

Liệt kê endpoints thay đổi:
- `GET /api/...`
- `POST /api/...`

## Why

Tại sao cần thay đổi này (link issue nếu có): Closes #...

## What changed

- Bullet point các thay đổi chính
- Bullet point...

## Test

Cách verify đã test:
- [ ] `uvicorn app.main:app --reload` chạy OK
- [ ] Test endpoint qua Swagger UI: http://localhost:8000/api/docs
- [ ] curl smoke test với JWT token

## Migration note

(Nếu có) Hướng dẫn migrate DB:
```bash
alembic upgrade head
```

## Checklist

- [ ] Code style OK (`ruff check app/`)
- [ ] CHANGELOG.md updated `[Unreleased]` section
- [ ] README.md updated nếu có endpoint mới
- [ ] Test local đầy đủ
