"""OTP login service — Phase 1 step 4 (2026-05-06).

In-memory OTP store cho login alternative (E3 scope):
- SV/GV nhập email -> backend gen OTP 6 số + send email -> SV nhập OTP -> login.
- Storage: dict in-memory {email: (otp_hash, expires_at)} -> đủ cho MVP single-replica.
  Railway hobby chạy 1 replica nên OK. Khi scale multi-replica -> migrate Redis.
- TTL: 5 phút. Single-use (xóa entry sau khi verify thành công).
- Hash OTP bằng bcrypt giống password để chống timing attack + DB dump leak.
- Anti-enumeration: tracking attempt count per email, lock 30p sau 5 lần sai.

Tradeoff in-memory vs Redis:
- In-memory: 0 dep, restart Railway = mất OTP đang chờ (acceptable, user request lại).
- Redis: persist + multi-replica nhưng phức tạp setup. Defer khi scale.
"""

import logging
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import bcrypt

log = logging.getLogger("otp")

# Storage in-memory — dict cho lookup O(1)
_store: dict[str, "OTPEntry"] = {}

# Anti-bruteforce — 5 lần sai/email -> lock 30p
_LOCK_AFTER_ATTEMPTS = 5
_LOCK_DURATION_MINUTES = 30
_OTP_TTL_MINUTES = 5


@dataclass
class OTPEntry:
    otp_hash: bytes  # bcrypt hash của 6 chữ số
    expires_at: datetime  # UTC
    attempts: int = 0  # Số lần verify sai
    locked_until: datetime | None = None  # Lock sau quá nhiều attempts


def generate_otp(email: str) -> str:
    """Sinh OTP 6 chữ số cho email + lưu hash. Trả OTP plaintext để gửi qua email.

    Idempotent: gọi lại sẽ overwrite OTP cũ (user click "Resend code" trên FE).
    """
    # secrets.randbelow(10**6) -> số int 0-999999, format 6 chữ số (zero-padded)
    code = f"{secrets.randbelow(10**6):06d}"
    otp_hash = bcrypt.hashpw(code.encode("utf-8"), bcrypt.gensalt(rounds=10))
    _store[email.lower()] = OTPEntry(
        otp_hash=otp_hash,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=_OTP_TTL_MINUTES),
    )
    log.warning("OTP generated: email=%s (TTL %dp)", email, _OTP_TTL_MINUTES)
    return code


def verify_otp(email: str, code: str) -> bool:
    """Verify OTP. Trả True nếu đúng + xóa entry (single-use).

    Side effects:
    - Sai 5 lần -> lock 30p (set locked_until)
    - Đúng -> xóa entry (single-use)
    - Hết hạn -> xóa entry, trả False
    """
    key = email.lower()
    entry = _store.get(key)
    if entry is None:
        log.warning("OTP verify: email=%s -> no entry", email)
        return False

    now = datetime.now(timezone.utc)

    # Check lock
    if entry.locked_until and now < entry.locked_until:
        log.warning("OTP verify: email=%s -> locked until %s", email, entry.locked_until)
        return False

    # Check expired
    if now > entry.expires_at:
        log.warning("OTP verify: email=%s -> expired", email)
        _store.pop(key, None)
        return False

    # Verify hash (bcrypt timing-safe)
    try:
        is_valid = bcrypt.checkpw(code.encode("utf-8"), entry.otp_hash)
    except Exception:
        is_valid = False

    if is_valid:
        log.warning("OTP verify: email=%s -> SUCCESS", email)
        _store.pop(key, None)  # Single-use, xóa ngay
        return True

    # Sai -> tăng attempts, lock nếu vượt
    entry.attempts += 1
    if entry.attempts >= _LOCK_AFTER_ATTEMPTS:
        entry.locked_until = now + timedelta(minutes=_LOCK_DURATION_MINUTES)
        log.warning(
            "OTP verify: email=%s -> LOCKED (attempts=%d)", email, entry.attempts
        )
    else:
        log.warning("OTP verify: email=%s -> wrong (attempts=%d)", email, entry.attempts)
    return False


def cleanup_expired() -> int:
    """Xóa entry đã hết hạn. Trả số entry xóa được.

    Có thể gọi định kỳ qua background task (vd 1 lần/giờ) để tránh memory leak
    nếu nhiều user request OTP nhưng không verify.
    """
    now = datetime.now(timezone.utc)
    expired_keys = [
        k for k, v in _store.items()
        if now > v.expires_at and (v.locked_until is None or now > v.locked_until)
    ]
    for k in expired_keys:
        _store.pop(k, None)
    return len(expired_keys)
