# Sprint 0 — Smoke Test Checklist

**Ngày:** 2026-05-06
**Mục đích:** Verify 7 fix Sprint 0 hoạt động đúng trên Railway production sau khi push.

---

## Bước 1: Push code lên Railway

```powershell
cd E:\PARA\10-projects\12-cnpm-project
git status   # Xem 9 file thay đổi
git add 08-database/2026-05-06_sqlapp_v04.sql `
        09-implementation/backend/init-schema.sql `
        09-implementation/backend/app/main.py `
        09-implementation/backend/app/config.py `
        09-implementation/backend/app/database.py `
        09-implementation/backend/app/middleware/audit.py `
        09-implementation/backend/app/routers/submissions.py `
        09-implementation/backend/docker-entrypoint.sh `
        09-implementation/backend/alembic/versions/0001_baseline_v04.py `
        11-docs/audit-report-2026-05-06.md `
        11-docs/sprint0-smoke-test-checklist.md
git commit -m "Sprint 0: fix 4 P0 + 3 P1 + 1 P2 audit findings"
git push
```

Đợi ~2 phút Railway redeploy. Vào Railway dashboard quan sát log:
- [ ] Thấy `Schema tồn tại nhưng chưa track Alembic — stamp baseline...`
- [ ] Thấy `Legacy DB đã được stamp baseline` (lần đầu) HOẶC `Migrations up-to-date` (lần sau)
- [ ] Thấy `audit worker started (queue maxsize=1000)`
- [ ] Thấy `Profile fields migration: ok (idempotent safety net)`
- [ ] Thấy `PTIT Contest Backend starting...` rồi `Starting uvicorn`
- [ ] Health check Railway xanh

Nếu thấy log lỗi `RuntimeError: JWT_SECRET_KEY phải được set...` → vào Railway dashboard set env var `JWT_SECRET_KEY` (đã set rồi nhưng verify lại).

---

## Bước 2: Test endpoint quan trọng

### Test 1 — Health (sanity check)

```powershell
curl https://ptit-contest-mobile-app-production.up.railway.app/health
```

Expected: `{"status":"ok","app":"PTIT Contest API","env":"production"}`
- [ ] PASS

### Test 2 — Cert verify P0-2 fix (TRƯỚC trả 404, GIỜ phải 200)

```powershell
$qr = "I1TfZL2Ub7ZeFsixryGgOcq0FHpWKCmHikMGphk_asI"   # SV b22dccn001 INDIVIDUAL Giải Nhất
curl "https://ptit-contest-mobile-app-production.up.railway.app/api/verify/$qr"
```

Expected: `{"valid":true,"cert_id":...,"contest_title":"Cuộc thi Hackathon mùa hè 2027","award_title":"Giải Nhất",...}`
- [ ] PASS — TRƯỚC Sprint 0 endpoint này trả 404

```powershell
# Test với QR sai → phải trả valid:false
curl "https://ptit-contest-mobile-app-production.up.railway.app/api/verify/INVALID_QR"
```

Expected: `{"valid":false}`
- [ ] PASS

### Test 3 — Download file P1-2 fix (TRƯỚC public, GIỜ phải 401 nếu không auth)

```powershell
# Không có Bearer token
curl -i "https://ptit-contest-mobile-app-production.up.railway.app/api/submissions/files/1/download"
```

Expected: `HTTP/1.1 401 Unauthorized`
- [ ] PASS — TRƯỚC Sprint 0 endpoint stream file ra mà không auth

```powershell
# Login lấy token rồi test với auth
$body = @{username="b22dccn001@ptit.edu.vn"; password=$env:DEMO_PASSWORD} | ConvertTo-Json
$res = Invoke-RestMethod -Uri "https://ptit-contest-mobile-app-production.up.railway.app/api/auth/login" `
       -Method Post -ContentType "application/x-www-form-urlencoded" `
       -Body "username=b22dccn001@ptit.edu.vn&password=$($env:DEMO_PASSWORD)"
$token = $res.access_token

# Hiện tại b22dccn001 chưa upload file nào nên test với owner thực sự sẽ 404
# Nhưng quan trọng là không bị 401 nữa
curl -H "Authorization: Bearer $token" `
     "https://ptit-contest-mobile-app-production.up.railway.app/api/submissions/files/1/download" -i
```

Expected (1 trong 3): 200 (nếu owner có file này), 403 (không phải owner), 404 (file không tồn tại) — KHÔNG được 401
- [ ] PASS

### Test 4 — Pool size (P1-3): nhiều request đồng thời không sập

```powershell
# Bắn 30 request song song xem có connection pool exhaustion không
1..30 | ForEach-Object -Parallel {
  curl -s -o /dev/null -w "%{http_code} " https://ptit-contest-mobile-app-production.up.railway.app/api/contests
} -ThrottleLimit 30
```

Expected: 30 response code 200, không 500 connection error
- [ ] PASS

### Test 5 — JWT TTL P1-1 (60p mới, không phải 24h)

```powershell
$body = "username=b22dccn001@ptit.edu.vn&password=$($env:DEMO_PASSWORD)"
$res = Invoke-RestMethod -Uri "https://ptit-contest-mobile-app-production.up.railway.app/api/auth/login" `
       -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $res.access_token

# Decode JWT (base64 phần payload)
$payload = $token.Split(".")[1]
$padding = "=" * ((4 - $payload.Length % 4) % 4)
$json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload + $padding))
$claims = $json | ConvertFrom-Json
$expSec = $claims.exp - $claims.iat
Write-Host "JWT TTL = $expSec giây = $([math]::Round($expSec/60)) phút"
```

Expected: `JWT TTL = 3600 giây = 60 phút`
- [ ] PASS — Trước là 86400 (24h)

### Test 6 — Cert template render (sanity, vẫn phải hoạt động)

Mở browser:
```
https://ptit-contest-mobile-app-production.up.railway.app/api/certificates/I1TfZL2Ub7ZeFsixryGgOcq0FHpWKCmHikMGphk_asI/render
```

Expected: HTML cert đẹp, tên SV b22dccn001, "Giải Nhất"
- [ ] PASS

### Test 7 — Audit worker P0-3 (kiểm tra qua log Railway)

Tạo 1 contest mới qua FE hoặc curl, sau đó:

```powershell
# Login GV
$body = "username=gv@ptit.edu.vn&password=$($env:DEMO_PASSWORD)"
$gvRes = Invoke-RestMethod -Uri "https://ptit-contest-mobile-app-production.up.railway.app/api/auth/login" `
         -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
$gvToken = $gvRes.access_token

# Tạo contest (POST, sẽ trigger audit)
curl -X POST "https://ptit-contest-mobile-app-production.up.railway.app/api/contests" `
     -H "Authorization: Bearer $gvToken" `
     -H "Content-Type: application/json" `
     -d '{"slug":"sprint0-test","title":"Sprint 0 Test","description":"Test audit","delivery_mode":"ONLINE","participation_mode":"INDIVIDUAL","start_at":"2026-12-01T08:00:00Z","end_at":"2026-12-31T23:59:00Z"}'
```

Sau đó vào Railway log search `audit worker` — KHÔNG nên thấy `audit queue full` hay `audit write failed` warnings.
- [ ] PASS

Optional: query audit_logs để verify record có ghi:
```sql
SELECT log_id, action_type, entity_name, entity_id, created_at
FROM ptit_contest.audit_logs
ORDER BY log_id DESC LIMIT 5;
```

### Test 8 — Alembic version table (P0-4)

```sql
-- Qua Railway DB shell hoặc psql
SELECT version_num FROM ptit_contest.alembic_version;
```

Expected: `0001_baseline_v04`
- [ ] PASS — Trước là không có bảng này

### Test 9 — E2E full pipeline (smoke quan trọng nhất)

Vào https://luxury-crostata-3c5c69.netlify.app làm:
1. Login SV b22dccn001 → vào tab Cuộc thi → đăng ký 1 contest đang REG_OPEN
2. Login GV → tab Phê duyệt → approve entry
3. SV vào tab Của tôi → thấy entry approved
4. (Nếu contest đang ONGOING + có submission round) SV vào nộp bài
5. GV chấm điểm
6. Cert flow nếu contest FINISHED

- [ ] PASS — Pipeline E2E vẫn hoạt động sau Sprint 0

---

## Bước 3: Verify checklist hoàn tất

Nếu tất cả 9 test PASS → Sprint 0 thành công, sẵn sàng vào Phase 1.

Nếu test nào FAIL:
- Test 1 (health): Railway service crash → check log Python exception
- Test 2 (cert verify): Có thể service worker cache hoặc Railway chưa redeploy → đợi 1-2p rồi retry
- Test 3 (download auth): Nếu vẫn trả 200 → check submissions.py đã được copy đúng vào container
- Test 4 (pool): Nếu thấy `OperationalError: too many connections` → giảm pool xuống nữa (DB_POOL_SIZE=3)
- Test 5 (JWT TTL): Nếu vẫn 86400 → check Railway env var `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` có override không
- Test 7 (audit): Nếu thấy `audit worker exception` → check JWT_SECRET_KEY env var đúng
- Test 8 (alembic): Nếu không thấy bảng → entrypoint chưa chạy alembic stamp head, check Dockerfile copy file alembic.ini + thư mục alembic/

---

## Bước 4: Báo Claude kết quả

Nói "Sprint 0 ok" hoặc paste log error nếu fail. Em sẽ:
- Nếu pass → đề xuất bắt đầu Phase 1 (Sentry + rate limit + refresh token + email + HSTS)
- Nếu fail → debug từng test cụ thể

---

## Phụ lục: rollback nếu cần

Nếu Railway deploy fail toàn bộ:

```powershell
git revert HEAD --no-edit
git push
```

Sau khi rollback, Sprint 0 fix sẽ bị undo. Có thể chọn lọc fix lẻ rồi push từng phần để cô lập bug.
