# PTIT Contest Backend — FastAPI + asyncpg + Uvicorn
FROM python:3.11-slim

# System deps cho psycopg/asyncpg + healthcheck + postgres client (psql)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev curl postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache pip install
COPY pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir .

# Copy source code
COPY . .

# Default port (Railway sẽ override $PORT)
ENV PORT=8000
EXPOSE 8000

# Init script — seed schema từ raw SQL nếu DB trống
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=15s --timeout=4s --retries=4 --start-period=30s \
    CMD curl -fsS http://localhost:${PORT}/health || exit 1

CMD ["/docker-entrypoint.sh"]
