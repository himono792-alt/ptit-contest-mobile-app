"""Email service — Phase 1 step 4 (2026-05-06).

Dual-mode transport:
- "console" (dev): log email content ra stdout/Railway log để debug nhanh không
  cần SMTP credentials. Set MAIL_TRANSPORT=console.
- "smtp" (production): gửi qua Brevo (smtp-relay.brevo.com:587) hoặc Gmail
  (smtp.gmail.com:587) với STARTTLS. Set MAIL_TRANSPORT=smtp + 5 env SMTP_*.

Pattern KHÔNG block request:
- Mọi caller dùng FastAPI BackgroundTasks: bg.add_task(email_service.send_email, ...)
- Nếu SMTP fail/timeout, log warning + capture Sentry, KHÔNG raise (request đã xong).
- Tránh dùng async với await trực tiếp trong endpoint vì sẽ block response 1-3s.

4 use case email:
- send_password_reset(email, full_name, reset_link) — link reset có TTL 15p
- send_welcome(email, full_name, temp_password) — admin tạo SV mới
- send_otp(email, full_name, otp_code) — OTP login alternative TTL 5p
- send_notification(email, full_name, title, body, target_url) — mirror in-app
"""

import logging
from pathlib import Path
from typing import Any

import aiosmtplib
from email.message import EmailMessage
from jinja2 import Environment, FileSystemLoader, select_autoescape

from app.config import settings

log = logging.getLogger("email")

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

    Trả True nếu gửi thành công (hoặc console mode), False nếu SMTP fail.
    KHÔNG raise exception — caller dùng BackgroundTask sẽ không catch được.

    Args:
        to_email: địa chỉ người nhận
        subject: tiêu đề email (sẽ thêm prefix "[PTIT Contest] " ở đầu)
        template_name: tên file template trong app/templates/emails/ (vd "password_reset.html")
        context: dict variables truyền vào template
    """
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

    # Console transport (dev mode hoặc fallback nếu SMTP_HOST rỗng)
    if settings.mail_transport != "smtp" or not settings.smtp_host:
        if settings.mail_transport == "smtp" and not settings.smtp_host:
            log.warning("MAIL_TRANSPORT=smtp nhung SMTP_HOST rong -> fallback console")
        log.info(
            "[EMAIL CONSOLE]\n"
            "  To: %s\n"
            "  Subject: %s\n"
            "  Template: %s\n"
            "  Context: %s\n"
            "  ---HTML---\n%s\n  ---END---",
            to_email, full_subject, template_name, context, html_body,
        )
        return True

    # SMTP transport — Brevo/Gmail/etc
    msg = EmailMessage()
    msg["From"] = f"{settings.smtp_from_name} <{settings.smtp_from}>"
    msg["To"] = to_email
    msg["Subject"] = full_subject
    msg.set_content(text_body)
    msg.add_alternative(html_body, subtype="html")

    try:
        # STARTTLS port 587 (Brevo, Gmail). Nếu SSL port 465 thì dùng use_tls=True + start_tls=False
        await aiosmtplib.send(
            msg,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_user or None,
            password=settings.smtp_password or None,
            start_tls=settings.smtp_use_tls,
            timeout=15,  # Tổng timeout 15s (Brevo thường <2s, để buffer cho slow network)
        )
        log.info("Email sent: to=%s subject=%s template=%s", to_email, full_subject, template_name)
        return True
    except Exception as e:
        # KHÔNG raise — fail-open, log warning + Sentry sẽ tự capture qua attach_stacktrace
        log.warning(
            "Email SMTP fail: to=%s subject=%s err=%s (transport=%s host=%s)",
            to_email, full_subject, e, settings.mail_transport, settings.smtp_host,
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
