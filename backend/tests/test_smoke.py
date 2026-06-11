"""Smoke tests — verify app load + health endpoint mà không cần DB."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


def test_app_loads(client: TestClient) -> None:
    """Verify FastAPI app khởi tạo OK + có routes đã đăng ký."""
    routes = [r.path for r in app.routes]
    assert "/health" in routes
    assert "/api/auth/login" in routes
    assert "/api/auth/register" in routes
    assert "/api/auth/me" in routes
    assert "/api/contests" in routes


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
    # 5 endpoints implemented hiện tại
    assert "/api/auth/register" in spec["paths"]
    assert "/api/auth/login" in spec["paths"]
    assert "/api/auth/me" in spec["paths"]
    assert "/api/auth/logout" in spec["paths"]
    assert "/api/contests" in spec["paths"]
    assert "/api/contests/{slug}" in spec["paths"]


def test_login_requires_body(client: TestClient) -> None:
    r = client.post("/api/auth/login", json={})
    assert r.status_code == 422  # Pydantic validation
