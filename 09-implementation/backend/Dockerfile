# PTIT Contest Backend — FastAPI + asyncpg + Uvicorn
FROM python:3.11-slim

# System deps cho psycopg/asyncpg + healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache pip install — chỉ copy pyproject để layer này invalidate khi deps đổi
COPY pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir .

# Copy source code (layer này invalidate khi code đổi, deps vẫn cache)
COPY . .

# Default port
EXPOSE 8000

# Healthcheck — kiểm tra /health endpoint
HEALTHCHECK --interval=15s --timeout=4s --retries=4 --start-period=20s \
    CMD curl -fsS http://localhost:8000/health || exit 1

# Run alembic migrate + uvicorn
CMD sh -c "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"
