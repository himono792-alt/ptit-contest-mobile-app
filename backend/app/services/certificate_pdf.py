"""Tải PDF chứng nhận = render HTML Mẫu C ra PDF bằng weasyprint.

Một nguồn HTML duy nhất (certificate_render) → PDF GIỐNG HỆT bản /render trên
trình duyệt. Font Google online (demo có mạng) hoặc fallback font hệ thống.
"""
from pathlib import Path
from typing import Any

import weasyprint

from app.services.certificate_render import render_certificate_html

_ASSETS = Path(__file__).parent.parent / "assets"


def build_certificate_pdf(info: dict[str, Any], qr_code: str) -> bytes:
    html = render_certificate_html(info, qr_code)
    return weasyprint.HTML(string=html, base_url=str(_ASSETS)).write_pdf()
