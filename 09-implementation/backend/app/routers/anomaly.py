"""AD-06 Anomaly reports — scan audit_logs phát hiện hành vi bất thường.

GET /api/admin/anomaly-reports[?severity=HIGH|MEDIUM|LOW]

3 detection rules MVP (chỉ dựa trên audit_logs hiện có):
  HIGH   — User lock/unlock storm (≥3 lock+unlock cùng 1 user trong 24h)
  MEDIUM — Mass POST từ 1 IP (>30 POST/giờ — nghi script/bot)
  LOW    — Error/auth-fail spike từ 1 IP (>20 status 4xx/5xx trong 1h)

Tạo 2026-05-07 — fix bug FE 404 sau khi Sprint 6 add anomaly_reports_screen.dart
nhưng quên implement BE endpoint.
"""

from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import require_roles
from app.models.identity import AppUser

router = APIRouter(prefix="/admin", tags=["admin"])


def _row(
    *,
    type_: str,
    severity: str,
    description: str,
    count: int,
    detected_at: datetime,
    entity_type: str | None = None,
    entity_id: str | None = None,
    related_user_id: int | None = None,
    suggested_action: str | None = None,
) -> dict:
    return {
        "type": type_,
        "severity": severity,
        "description": description,
        "count": count,
        "detected_at": detected_at.isoformat(),
        "entity_type": entity_type,
        "entity_id": entity_id,
        "related_user_id": related_user_id,
        "suggested_action": suggested_action,
    }


@router.get("/anomaly-reports")
async def list_anomaly_reports(
    db: Annotated[AsyncSession, Depends(get_db)],
    _user: AppUser = Depends(require_roles("ADMIN")),
    severity: str | None = Query(None, regex="^(HIGH|MEDIUM|LOW)$"),
):
    """Scan audit_logs return list anomaly. Mỗi rule scan độc lập + concat.

    KHÔNG cache — admin click refresh là chạy lại fresh.
    """
    now = datetime.now(timezone.utc)
    findings: list[dict] = []

    # ---------- HIGH: User lock/unlock storm 24h ----------
    rows = (await db.execute(text("""
        SELECT entity_id, COUNT(*) AS c, MAX(created_at) AS last_at
        FROM ptit_contest.audit_logs
        WHERE entity_name = 'user'
          AND (details_json->>'path' LIKE '%/lock%'
            OR details_json->>'path' LIKE '%/unlock%')
          AND created_at >= :since
          AND entity_id IS NOT NULL
        GROUP BY entity_id
        HAVING COUNT(*) >= 3
        ORDER BY c DESC
        LIMIT 20
    """), {"since": now - timedelta(hours=24)})).all()
    for r in rows:
        findings.append(_row(
            type_="USER_LOCK_STORM",
            severity="HIGH",
            description=(
                f"User #{r.entity_id} bị lock/unlock {r.c} lần trong 24h gần đây. "
                "Có thể là dấu hiệu admin lạm quyền hoặc account compromised."
            ),
            count=int(r.c),
            detected_at=r.last_at or now,
            entity_type="user",
            entity_id=str(r.entity_id),
            related_user_id=int(r.entity_id) if str(r.entity_id).isdigit() else None,
            suggested_action="Kiểm tra audit log của user này + xác minh với admin thực hiện.",
        ))

    # ---------- MEDIUM: Mass POST từ 1 IP trong 1h ----------
    rows = (await db.execute(text("""
        SELECT ip_address, COUNT(*) AS c, MAX(created_at) AS last_at
        FROM ptit_contest.audit_logs
        WHERE action_type = 'POST'
          AND ip_address IS NOT NULL
          AND created_at >= :since
        GROUP BY ip_address
        HAVING COUNT(*) > 30
        ORDER BY c DESC
        LIMIT 20
    """), {"since": now - timedelta(hours=1)})).all()
    for r in rows:
        findings.append(_row(
            type_="MASS_POST_FROM_IP",
            severity="MEDIUM",
            description=(
                f"IP {r.ip_address} thực hiện {r.c} POST request trong 1 giờ qua. "
                "Có thể là script tự động/bot. Bình thường user thao tác <30 POST/giờ."
            ),
            count=int(r.c),
            detected_at=r.last_at or now,
            entity_type="ip",
            entity_id=str(r.ip_address),
            suggested_action="Kiểm tra IP — nếu lạ, cân nhắc rate-limit hoặc block tại tầng nginx/CF.",
        ))

    # ---------- LOW: Error/auth-fail spike từ 1 IP 1h ----------
    rows = (await db.execute(text("""
        SELECT ip_address, COUNT(*) AS c, MAX(created_at) AS last_at
        FROM ptit_contest.audit_logs
        WHERE ip_address IS NOT NULL
          AND created_at >= :since
          AND (details_json->>'status')::int >= 400
          AND (details_json->>'status')::int < 600
        GROUP BY ip_address
        HAVING COUNT(*) > 20
        ORDER BY c DESC
        LIMIT 20
    """), {"since": now - timedelta(hours=1)})).all()
    for r in rows:
        findings.append(_row(
            type_="ERROR_RESPONSE_SPIKE",
            severity="LOW",
            description=(
                f"IP {r.ip_address} nhận {r.c} response 4xx/5xx trong 1h. "
                "Có thể là probe scan endpoints hoặc client bug."
            ),
            count=int(r.c),
            detected_at=r.last_at or now,
            entity_type="ip",
            entity_id=str(r.ip_address),
            suggested_action="Xem audit log filter theo IP để biết endpoint nào bị probe.",
        ))

    if severity:
        findings = [f for f in findings if f["severity"] == severity]

    # Sort: HIGH → MEDIUM → LOW, rồi theo detected_at desc
    sev_rank = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    findings.sort(key=lambda f: (sev_rank.get(f["severity"], 9), f["detected_at"]), reverse=False)

    return {"items": findings, "total": len(findings)}
