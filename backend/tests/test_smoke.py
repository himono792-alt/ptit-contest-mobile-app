"""Smoke tests — verify app load + health endpoint mà không cần DB."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


def _registered_paths() -> set[str]:
    """Thu thập path đã đăng ký, bền với nhiều version FastAPI.

    FastAPI mới bọc include_router thành object không có `.path` → fallback
    sang OpenAPI spec để lấy danh sách path ổn định giữa các version.
    """
    paths = {getattr(r, "path", None) for r in app.routes}
    paths.discard(None)
    paths |= set(app.openapi().get("paths", {}).keys())
    return paths


def test_app_loads(client: TestClient) -> None:
    """Verify FastAPI app khởi tạo OK + có routes đã đăng ký."""
    paths = _registered_paths()
    assert "/health" in paths
    assert "/api/auth/login" in paths
    assert "/api/auth/register" in paths
    assert "/api/auth/me" in paths


def test_health(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "app" in body


def test_openapi(client: TestClient) -> None:
    r = client.get("/api/openapi.json")
    assert r.status_code == 200
    spec = r.json()
    assert "paths" in spec
    assert "/api/auth/register" in spec["paths"]
    assert "/api/auth/login" in spec["paths"]
    assert "/api/auth/me" in spec["paths"]
    assert "/api/auth/logout" in spec["paths"]


def test_login_requires_body(client: TestClient) -> None:
    r = client.post("/api/auth/login", json={})
    assert r.status_code == 422  # Pydantic validation
