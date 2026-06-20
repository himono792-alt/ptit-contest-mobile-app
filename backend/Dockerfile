# PTIT Contest Backend — FastAPI + asyncpg + Uvicorn
FROM python:3.11-slim

# System deps:
#  - gcc/libpq-dev: build psycopg/asyncpg
#  - curl/postgresql-client: healthcheck + psql
#  - weasyprint runtime (pango/cairo/gdk-pixbuf...) + font tiếng Việt fallback
#    (Liberation/DejaVu) cho PDF chứng nhận Mẫu C khi offline; có mạng thì lấy Google Fonts.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev curl postgresql-client \
    libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz0b libffi-dev \
    libgdk-pixbuf-2.0-0 libcairo2 shared-mime-info \
    fonts-liberation fonts-dejavu-core \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Sprint 7 (2026-05-07): cache-friendly Dockerfile.
#
# Cũ: COPY . . trước pip install → mỗi commit (kể cả chỉ sửa scripts/seed.py
# hay docs) invalidate cache → reinstall toàn bộ deps ~5 min → Railway timeout.
#
# Mới: COPY pyproject.toml + stub `app/__init__.py` TRƯỚC pip install.
# pip resolve deps + build wheel "ptit-contest-backend" với stub app/ trống.
# Layer này chỉ invalidate khi pyproject.toml đổi (rare). Pip cache reused
# qua mọi commit thay file source → build incremental ~30s.
#
# Sau khi pip xong → COPY . . overwrite stub app/ với source thật. Python
# WORKDIR=/app, sys.path[0]='' → import app/ đọc từ workdir trước site-packages
# → source thật được load runtime. Stub trong site-packages bị shadow.
COPY pyproject.toml ./
RUN mkdir -p app && touch app/__init__.py
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir .

# Copy full source SAU pip — tận dụng Docker layer cache.
COPY . .

# Default port (Railway sẽ override $PORT)
ENV PORT=8000
EXPOSE 8000

# Init script — seed schema từ raw SQL nếu DB trống
RUN chmod +x /app/docker-entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=15s --timeout=4s --retries=4 --start-period=30s \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

CMD ["/app/docker-entrypoint.sh"]
