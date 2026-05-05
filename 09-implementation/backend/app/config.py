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
    db_echo: bool = False  # set True để log SQL khi debug

    # CORS
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    # Auth
    # Fix P1-1 (audit 2026-05-06): default rỗng + raise nếu production. Trước đây có
    # default "change-me-..." → nguy hiểm nếu Railway env var bị xóa.
    jwt_secret_key: str = ""
    jwt_algorithm: str = "HS256"
    # Access token TTL: 60p cho production (đi với refresh token Phase 1).
    # Dev có thể nâng qua .env để đỡ phải re-login.
    jwt_access_token_expire_minutes: int = 60

    # DB pool — Fix P1-3 (audit 2026-05-06): giảm xuống cho Railway hobby (~22 conn).
    # Main pool 5+10=15 + audit pool 2+2=4 = 19 conn → safe.
    db_pool_size: int = 5
    db_max_overflow: int = 10

    # Server
    host: str = "0.0.0.0"
    port: int = 8000


@lru_cache
def get_settings() -> "Settings":
    """Cached singleton — settings không đổi trong runtime của app."""
    s = Settings()
    # Production env safety check (Fix P1-1)
    if s.app_env == "production" and not s.jwt_secret_key:
        raise RuntimeError(
            "JWT_SECRET_KEY phải được set khi APP_ENV=production. "
            "Generate: python -c \"import secrets; print(secrets.token_urlsafe(32))\""
        )
    # Dev fallback chỉ khi không phải production — log warning rõ ràng
    if not s.jwt_secret_key:
        import warnings
        s.jwt_secret_key = "DEV_INSECURE_DEFAULT_DO_NOT_USE_IN_PRODUCTION"
        warnings.warn(
            "JWT_SECRET_KEY rỗng — dùng fallback insecure (dev only). "
            "Set env var trước khi deploy.",
            stacklevel=2,
        )
    return s


settings = get_settings()
