#!/usr/bin/env bash
# Start backend + Flutter web cho LAN test (vd: iPhone Safari trên cùng WiFi).
#
# IP LAN máy Windows: 192.168.1.63
# Backend đang chạy trong WSL2 → cần port forward Windows → WSL2.
#
# === BƯỚC 1: Mở firewall Windows (1 lần duy nhất) ===
# PowerShell ADMIN:
#   New-NetFirewallRule -Name PtitWeb -DisplayName "PTIT Web 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
#   New-NetFirewallRule -Name PtitApi -DisplayName "PTIT API 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
#
# === BƯỚC 2: Port forward Windows → WSL2 (cập nhật mỗi lần WSL khởi động lại) ===
# PowerShell ADMIN:
#   $wslIp = (wsl hostname -I).Trim().Split()[0]
#   netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0 2>$null
#   netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=$wslIp
#   netsh interface portproxy show all
# (Hoặc nếu Windows 11 build mới có WSL mirrored networking: thêm vào %USERPROFILE%/.wslconfig:
#    [wsl2]
#    networkingMode=mirrored
#  rồi `wsl --shutdown` — sẽ KHÔNG cần netsh portproxy nữa.)
#
# === BƯỚC 3: Backend (terminal WSL Ubuntu) ===
#   cd backend
#   source .venv/bin/activate
#   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
#
# === BƯỚC 4: Flutter web (terminal khác, có thể Windows native) ===
#   cd frontend
#   flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 \
#     --dart-define=API_BASE=http://192.168.1.63:8000
#
# === BƯỚC 5: iPhone Safari (cùng WiFi router 192.168.1.x) ===
#   http://192.168.1.63:3000
#   Bonus: Share → Add to Home Screen → app chạy như native, ẩn URL bar
#
# === Trouble-shooting ===
# - Safari load trắng / loading mãi: kiểm tra firewall + portproxy đã thêm chưa
#   (test từ Windows: curl http://192.168.1.63:3000/  → phải 200)
# - Login fail / không call được API: mở DevTools Safari (cần Mac) hoặc xem
#   Console của Flutter terminal — chú ý CORS error
# - WSL khởi động lại → IP WSL đổi → phải chạy lại lệnh netsh ở BƯỚC 2

echo "Đây là file hướng dẫn, không phải script tự chạy. Đọc các comment phía trên."
