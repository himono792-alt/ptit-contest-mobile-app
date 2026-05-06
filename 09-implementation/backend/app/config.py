"""Application settings (loaded from .env via pydantic-settings)."""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_name: str = "PTIT Contest API"
    app_env: str = "development"
    debug: bool = True
    api_prefix: str = "/api"

    # Database
    database_url: str = Field(
        default="postgresql+asyncpg://ptit_contest:dev_password@localhost:5432/ptit_contest_db"
    )
    db_echo: bool = False

    # CORS
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    # Auth
    # Fix P1-1 (audit 2026-05-06): default rong + raise neu production.
    jwt_secret_key: str = ""
    jwt_algorithm: str = "HS256"
    # Access token TTL: 60p cho production.
    jwt_access_token_expire_minutes: int = 60
    # Refresh token TTL — Phase 1 step 3 (2026-05-06)
    # Stateless JWT, khong luu DB. TTL 7 ngay phu hop voi biometric login Flutter.
    jwt_refresh_token_expire_days: int = 7

    # DB pool — Fix P1-3 (audit 2026-05-06): giam xuong cho Railway hobby (~22 conn).
    # Main pool 5+10=15 + audit pool 2+2=4 = 19 conn -> safe.
    db_pool_size: int = 5
    db_max_overflow: int = 10

    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    # Sentry — Phase 1 step 1 (2026-05-06)
    sentry_dsn: str = ""
    sentry_traces_sample_rate: float = 0.1
    sentry_release: str = ""

    # Rate limit — Phase 1 step 2 (2026-05-06)
    redis_url: str = ""
    rate_limit_default: str = "200/minute"
    rate_limit_enabled: bool = True

    # Email service — Phase 1 step 4 (2026-05-06)
    # Migrate 2026-05-06 evening: SMTP -> Brevo HTTP API (Railway block port 587).
    # mail_transport: "brevo" (production qua HTTP API) | "console" (dev: log stdout)
    # Nếu mail_transport=brevo mà BREVO_API_KEY rỗng → fallback console + warning.
    mail_transport: str = "console"
    brevo_api_key: str = ""  # Generate ở https://app.brevo.com/settings/keys/api
    smtp_from: str = ""  # Email sender (đã verify trên Brevo, vd himono792@gmail.com)
    smtp_from_name: str = "PTIT Contest"
    # Legacy SMTP fields — giữ tạm cho backward-compat env, không dùng nữa.
    # Có thể xóa sau khi cleanup Railway env.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    # FE base URL — dùng cho link reset password trong email + QR verify cert
    # Migrate 2026-05-06: Netlify hết quota build → Cloudflare Pages thay thế.
    frontend_base_url: str = "https://ptit-contest-app.pages.dev"

    # Security headers — Phase 1 step 5 (2026-05-06)
    # HSTS max-age default 1 năm = 31536000s. Đủ pass HSTS preload list.
    # Nếu cần lock dài hơn (2 năm) → set HSTS_MAX_AGE=63072000 trên Railway env.
    # Nếu cần test/dev → HSTS_ENABLED=false để tắt (vẫn còn 4 header còn lại).
    hsts_enabled: bool = True
    hsts_max_age: int = 31536000

    # R2 object storage — Sprint 3 (2026-05-07)
    # Cloudflare R2 S3-compatible (free 10GB + 1M Class A ops/mo).
    # Skip nếu R2_BUCKET_NAME rỗng → fallback BYTEA in-DB (legacy mode).
    # New submissions go R2, old BYTEA giữ nguyên (lazy migration).
    r2_endpoint_url: str = ""  # https://{account_id}.r2.cloudflarestorage.com
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket_name: str = ""
    # Public URL cho download (tuỳ chọn — dùng presigned URL nếu rỗng)
    r2_public_url: str = ""


@lru_cache
def get_settings() -> "Settings":
    s = Settings()
    # Production env safety check (Fix P1-1)
    if s.app_env == "production" and not s.jwt_secret_key:
        raise RuntimeError(
            "JWT_SECRET_KEY phai duoc set khi APP_ENV=production. "
            "Generate: python -c \"import secrets; print(secrets.token_urlsafe(32))\""
        )
    if not s.jwt_secret_key:
        import warnings
        s.jwt_secret_key = "DEV_INSECURE_DEFAULT_DO_NOT_USE_IN_PRODUCTION"
        warnings.warn(
            "JWT_SECRET_KEY rong - dung fallback insecure (dev only). "
            "Set env var truoc khi deploy.",
            stacklevel=2,
        )
    return s


settings = get_settings()
