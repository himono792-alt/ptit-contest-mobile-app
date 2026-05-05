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
    jwt_secret_key: str = "change-me-to-random-32-byte-string"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 1440

    # Server
    host: str = "0.0.0.0"
    port: int = 8000


@lru_cache
def get_settings() -> Settings:
    """Cached singleton — settings không đổi trong runtime của app."""
    return Settings()


settings = get_settings()
