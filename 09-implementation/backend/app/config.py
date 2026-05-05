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
    # mail_transport: "smtp" (production qua Brevo/Gmail) | "console" (dev: log ra stdout)
    # Nếu mail_transport=smtp mà SMTP_HOST rỗng → fallback console + warning.
    mail_transport: str = "console"
    smtp_host: str = ""
    smtp_port: int = 587  # Brevo + Gmail dùng port 587 STARTTLS
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    smtp_from_name: str = "PTIT Contest"
    smtp_use_tls: bool = True  # STARTTLS (port 587). Set False nếu dùng SSL port 465.
    # FE base URL — dùng cho link reset password trong email
    frontend_base_url: str = "https://luxury-crostata-3c5c69.netlify.app"


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
