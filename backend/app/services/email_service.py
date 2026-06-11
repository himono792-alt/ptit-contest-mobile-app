"""Email service — Phase 1 step 4 (2026-05-06).

Migrate 2026-05-06 evening: SMTP (port 587 aiosmtplib) -> Brevo HTTP API (port 443 httpx).
Lý do: Railway hobby plan + nhiều free hosting (Heroku/Render/Vercel) block outbound TCP
port 25/465/587 chống spam abuse → SMTP timeout. HTTPS port 443 không bị block.

Dual-mode transport:
- "console" (dev): log email content ra stdout/Railway log, KHÔNG gửi thật.
  Set MAIL_TRANSPORT=console (default).
- "brevo" (production): POST tới https://api.brevo.com/v3/smtp/email (HTTPS).
  Set MAIL_TRANSPORT=brevo + BREVO_API_KEY env var.

Pattern KHÔNG block request:
- Mọi caller dùng FastAPI BackgroundTasks: bg.add_task(email_service.send_email, ...)
- Nếu HTTP fail/timeout, log warning + Sentry tự capture, KHÔNG raise.
- httpx timeout 15s tổng (Brevo thường <2s).

4 use case email:
- send_password_reset(email, full_name, reset_link) — link reset có TTL 15p
- send_welcome(email, full_name, temp_password) — admin tạo SV mới
- send_otp(email, full_name, otp_code) — OTP login alternative TTL 5p
- send_notification(email, full_name, title, body, target_url) — mirror in-app
"""

import logging
from pathlib import Path
from typing import Any

import httpx
from jinja2 import Environment, FileSystemLoader, select_autoescape

from app.config import settings

log = logging.getLogger("email")

# Brevo Transactional Email API endpoint (HTTP, port 443)
# Docs: https://developers.brevo.com/reference/sendtransacemail
_BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"
_BREVO_TIMEOUT_SECONDS = 15  # Brevo thường <2s, buffer cho slow network

# Jinja2 env load template từ app/templates/emails/
_TEMPLATE_DIR = Path(__file__).parent.parent / "templates" / "emails"
_jinja_env = Environment(
    loader=FileSystemLoader(_TEMPLATE_DIR),
    autoescape=select_autoescape(["html", "xml"]),
    trim_blocks=True,
    lstrip_blocks=True,
)


async def send_email(
    to_email: str,
    subject: str,
    template_name: str,
    context: dict[str, Any],
) -> bool:
    """Gửi 1 email với template Jinja2.

    Trả True nếu gửi thành công (hoặc console mode), False nếu HTTP fail.
    KHÔNG raise exception — caller dùng BackgroundTask sẽ không catch được.

    Args:
        to_email: địa chỉ người nhận
        subject: tiêu đề email (sẽ thêm prefix "[PTIT Contest] " ở đầu)
        template_name: tên file template trong app/templates/emails/ (vd "password_reset.html")
        context: dict variables truyền vào template
    """
    # Debug print — luôn xuất stdout Railway log (log.warning có thể bị drop)
    print(
        f"[EMAIL_DEBUG] send_email called: to={to_email} subject={subject!r} "
        f"transport={settings.mail_transport!r} from={settings.smtp_from!r}",
        flush=True,
    )
    # Render template HTML + plain text fallback
    try:
        html_template = _jinja_env.get_template(template_name)
        html_body = html_template.render(
            **context,
            app_name=settings.smtp_from_name,
            frontend_base_url=settings.frontend_base_url,
        )
    except Exception as e:
        log.error("Template render fail [%s]: %s", template_name, e)
        return False

    # Plain text fallback đơn giản: strip HTML tag thô (đủ cho client không render HTML)
    text_body = _strip_html(html_body)

    full_subject = f"[{settings.smtp_from_name}] {subject}"

    # Console transport (dev mode hoặc fallback nếu BREVO_API_KEY rỗng)
    if settings.mail_transport != "brevo" or not settings.brevo_api_key:
        if settings.mail_transport == "brevo" and not settings.brevo_api_key:
            log.warning("MAIL_TRANSPORT=brevo nhung BREVO_API_KEY rong -> fallback console")
        log.warning(
            "[EMAIL CONSOLE]\n"
            "  To: %s\n"
            "  Subject: %s\n"
            "  Template: %s\n"
            "  Context: %s",
            to_email, full_subject, template_name, context,
        )
        return True

    # Brevo HTTP API transport — POST https://api.brevo.com/v3/smtp/email
    payload = {
        "sender": {
            "name": settings.smtp_from_name,
            "email": settings.smtp_from,
        },
        "to": [{"email": to_email}],
        "subject": full_subject,
        "htmlContent": html_body,
        "textContent": text_body,
    }
    headers = {
        "api-key": settings.brevo_api_key,
        "accept": "application/json",
        "content-type": "application/json",
    }

    try:
        print(f"[EMAIL_DEBUG] About to POST Brevo API for {to_email}", flush=True)
        async with httpx.AsyncClient(timeout=_BREVO_TIMEOUT_SECONDS) as client:
            response = await client.post(_BREVO_API_URL, headers=headers, json=payload)

        if response.status_code in (200, 201):
            # Brevo trả 201 + body { "messageId": "<...@smtp-relay.mailin.fr>" }
            try:
                msg_id = response.json().get("messageId", "?")
            except Exception:
                msg_id = "?"
            print(
                f"[EMAIL_DEBUG] Brevo API OK: to={to_email} status={response.status_code} "
                f"messageId={msg_id}",
                flush=True,
            )
            log.warning(
                "Email sent: to=%s subject=%s template=%s messageId=%s",
                to_email, full_subject, template_name, msg_id,
            )
            return True

        # Brevo lỗi — log body để debug (vd 401 invalid api key, 400 sender not verified)
        print(
            f"[EMAIL_DEBUG] Brevo API ERROR: to={to_email} status={response.status_code} "
            f"body={response.text[:500]}",
            flush=True,
        )
        log.warning(
            "Email Brevo API fail: to=%s subject=%s status=%d body=%s",
            to_email, full_subject, response.status_code, response.text[:500],
        )
        return False

    except Exception as e:
        # KHÔNG raise — fail-open, log warning + Sentry sẽ tự capture qua attach_stacktrace
        print(
            f"[EMAIL_DEBUG] Brevo API EXCEPTION: to={to_email} err={type(e).__name__}: {e}",
            flush=True,
        )
        log.warning(
            "Email Brevo API exception: to=%s subject=%s err=%s",
            to_email, full_subject, e,
        )
        return False


# ---------- High-level helpers ----------

async def send_password_reset(
    to_email: str, full_name: str, reset_token: str
) -> bool:
    """SV-02 forgot password — gửi link reset (TTL 15p)."""
    reset_link = f"{settings.frontend_base_url}/#/reset-password?token={reset_token}"
    return await send_email(
        to_email=to_email,
        subject="Đặt lại mật khẩu",
        template_name="password_reset.html",
        context={
            "full_name": full_name,
            "reset_link": reset_link,
            "ttl_minutes": 15,
        },
    )


async def send_welcome(
    to_email: str, full_name: str, temp_password: str
) -> bool:
    """AD-01 admin tạo user — gửi welcome + temp password."""
    login_link = f"{settings.frontend_base_url}/#/login"
    return await send_email(
        to_email=to_email,
        subject="Chào mừng đến với PTIT Contest",
        template_name="welcome.html",
        context={
            "full_name": full_name,
            "email": to_email,
            "temp_password": temp_password,
            "login_link": login_link,
        },
    )


async def send_otp(to_email: str, full_name: str, otp_code: str) -> bool:
    """SV-01b login alternative — gửi OTP 6 chữ số (TTL 5p)."""
    return await send_email(
        to_email=to_email,
        subject="Mã đăng nhập một lần (OTP)",
        template_name="otp.html",
        context={
            "full_name": full_name,
            "otp_code": otp_code,
            "ttl_minutes": 5,
        },
    )


async def send_notification(
    to_email: str,
    full_name: str,
    title: str,
    body: str,
    target_route: str | None = None,
) -> bool:
    """SV-07 notification mirror — gửi email cho event critical (entry approved, cert issued)."""
    target_url = (
        f"{settings.frontend_base_url}/#{target_route}" if target_route else None
    )
    return await send_email(
        to_email=to_email,
        subject=title,
        template_name="notification.html",
        context={
            "full_name": full_name,
            "title": title,
            "body": body,
            "target_url": target_url,
        },
    )


# ---------- Internal ----------

def _strip_html(html: str) -> str:
    """Plain text fallback đơn giản — strip tag thô.

    Dùng cho text/plain body của email (RFC 2046 multipart/alternative).
    Email client không render HTML (vd Mutt CLI) sẽ thấy text version.
    Không cần BeautifulSoup vì template ngắn + đơn giản.
    """
    import re
    # Remove HTML tag, decode common entities
    text = re.sub(r"<[^>]+>", "", html)
    text = (
        text.replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&#39;", "'")
        .replace("&quot;", '"')
    )
    # Strip excessive whitespace
    text = re.sub(r"\n\s*\n\s*\n+", "\n\n", text).strip()
    return text
