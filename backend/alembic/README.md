# Alembic Migrations

## Cách setup lần đầu (recommend)

Vì schema đã có sẵn trong `database/2026-05-06_sqlapp_v04.sql`, dùng pattern **baseline + future autogenerate**:

```bash
# 1. Tạo DB rỗng
psql -U postgres -c "CREATE DATABASE ptit_contest_db;"

# 2. Apply schema từ file SQL gốc
psql -U postgres -d ptit_contest_db -f ../database/2026-05-06_sqlapp_v04.sql

# 3. Stamp Alembic version table (chưa có migration nào, chỉ đánh dấu baseline)
alembic stamp head
```

## Tạo migration mới khi sửa model

```bash
# Sửa file trong app/models/*.py rồi:
alembic revision --autogenerate -m "add column XYZ"

# Review file vừa tạo trong alembic/versions/, edit nếu cần.
# Apply:
alembic upgrade head

# Rollback 1 step:
alembic downgrade -1
```

## Lưu ý

- Schema nằm trong `ptit_contest` (không phải `public`). `env.py` đã set `version_table_schema="ptit_contest"`.
- Alembic sẽ KHÔNG track các ENUM type tự sinh nếu không cẩn thận. Khi autogenerate liên quan đến enum, review kỹ migration trước khi apply.
- Async config: env.py dùng `async_engine_from_config` + `asyncio.run`.
