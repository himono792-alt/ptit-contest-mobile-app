"""Render HTML chứng nhận Mẫu C dùng CHUNG cho /render (HTML) và /pdf (weasyprint).

Một nguồn HTML duy nhất → bản PDF tải về GIỐNG HỆT bản xem trên trình duyệt.
- Đổ dữ liệu vào placeholder {{...}}.
- Chèn QR phía SERVER (segno → PNG data-URI) thay vì qrcodejs CDN → không cần JS,
  weasyprint render được, và không phụ thuộc mạng cho riêng phần QR.
- Xử lý trường hợp không có giải (award rỗng) ở server (vì PDF không chạy JS).
"""
from datetime import datetime
from pathlib import Path
from typing import Any

import segno

from app.config import settings

_TEMPLATE_PATH = Path(__file__).parent.parent / "assets" / "cert_template.html"

# Khối thành tích khi CÓ giải (mặc định trong template) và khi KHÔNG có giải.
_ACH_WITH_AWARD = (
    '<div class="ach" id="ach">\n'
    '        đã đạt <span class="award">{{award_title}}</span><br>\n'
    '        tại cuộc thi: <span class="contest">{{contest_title}}</span>\n'
    '      </div>'
)
_ACH_NO_AWARD = (
    '<div class="ach" id="ach">\n'
    '        đã tham gia cuộc thi:<br>\n'
    '        <span class="contest">{{contest_title}}</span>\n'
    '      </div>'
)


def _qr_img_tag(verify_url: str) -> str:
    """QR PNG data-URI (segno, pure-Python) bọc trong <img> vừa ô qr-box."""
    data_uri = segno.make(verify_url, error="m").png_data_uri(scale=5, border=0)
    return f'<img alt="QR" style="width:100%;height:100%" src="{data_uri}">'


def render_certificate_html(info: dict[str, Any], qr_code: str) -> str:
    """Trả HTML chứng nhận đã đổ dữ liệu + chèn QR server (không còn placeholder/JS)."""
    html = _TEMPLATE_PATH.read_text(encoding="utf-8")

    # Không có giải → đổi khối thành tích trước khi thay token.
    award = (info.get("award_title") or "").strip()
    if not award and _ACH_WITH_AWARD in html:
        html = html.replace(_ACH_WITH_AWARD, _ACH_NO_AWARD, 1)

    issued = info.get("issued_at")
    repl = {
        "{{full_name}}": info.get("student_name") or "",
        "{{student_code}}": info.get("student_code") or "",
        "{{award_title}}": award,
        "{{contest_title}}": info.get("contest_title") or "",
        "{{issued_date}}": issued.strftime("%d/%m/%Y") if issued else "",
        "{{qr_code}}": qr_code,
    }
    for k, v in repl.items():
        html = html.replace(k, str(v))

    verify_url = f"{settings.frontend_base_url}/verify/{qr_code}"
    # Chèn QR server vào ô qr-box (thay chữ "QR" placeholder).
    html = html.replace('">QR</div>', f'">{_qr_img_tag(verify_url)}</div>', 1)
    # Bỏ qrcodejs CDN + script preview (đã render server-side, không cần JS).
    import re
    html = re.sub(r'<script[^>]*src="https://cdnjs[^"]*"></script>', "", html)
    html = re.sub(r"<script>.*?</script>", "", html, flags=re.DOTALL)
    # Chỉ cho TRÌNH DUYỆT: tự co cert (khổ cứng 297mm) vừa cửa sổ để không bị
    # tràn ngang/cắt mép (nhìn như lệch). weasyprint bỏ qua <script> → PDF vẫn A4.
    scaler = (
        "<script>(function(){var c=document.querySelector('.cert');if(!c)return;"
        "function fit(){c.style.transform='none';var w=c.offsetWidth,h=c.offsetHeight;"
        "var s=Math.min(1,(window.innerWidth-24)/w);c.style.transformOrigin='top center';"
        "c.style.transform='scale('+s+')';var st=document.querySelector('.stage');"
        "if(st){st.style.minHeight='0';st.style.padding='12px 0';st.style.height=(h*s+24)+'px';}}"
        "window.addEventListener('resize',fit);fit();})();</script>"
    )
    html = html.replace("</body>", scaler + "</body>", 1)
    return html
