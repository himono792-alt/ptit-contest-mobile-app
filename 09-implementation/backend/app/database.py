"""Async SQLAlchemy 2.0 engine + session factory."""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config import settings

# Engine — async, sử dụng asyncpg driver
# Fix P1-3 (audit 2026-05-06): pool size đọc từ settings (default 5+10=15) để fit
# Railway hobby plan ~22 conn limit. Audit pool 2+2 = 4 → tổng 19 conn.
engine: AsyncEngine = create_async_engine(
    settings.database_url,
    echo=settings.db_echo,
    pool_pre_ping=True,
    pool_size=settings.db_pool_size,
    max_overflow=settings.db_max_overflow,
    # Đảm bảo SQL chạy đúng schema "ptit_contest"
    connect_args={
        "server_settings": {"search_path": "ptit_contest,public"}
    },
)

# Session factory
AsyncSessionLocal: async_sessionmaker[AsyncSession] = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency: yield 1 AsyncSession per request, auto-close.

    Usage:
        @router.get("/items")
        async def list_items(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
