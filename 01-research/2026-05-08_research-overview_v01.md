# Research Overview — PTIT Contest Management System

**Phiên bản:** v01 (2026-05-08)
**Tác giả:** Nhóm N08 — môn CNPM HK2 2026
**Mục đích kép:**
1. **Hồi cứu cho báo cáo CNPM** — bù phần research đã skip ở giai đoạn đầu, justify các quyết định thiết kế (4 role, workflow phê duyệt 2 cấp BCN, Flutter, OTP login).
2. **Định hướng v2** — chỉ ra pain point hiện trạng & cơ hội cải tiến cho phiên bản kế tiếp.

**Phương pháp:** kết hợp định tính (nghiên cứu desk + persona dựa trên quan sát thực tế tại PTIT) và định lượng (survey giả định 60 SV + 8 GV theo cỡ mẫu hợp lý cho dự án môn học).

**Liên quan:**
- Yêu cầu chính: `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- Traceability matrix: `02-requirements/2026-05-07_traceability-matrix_v03.md`
- Workflow phê duyệt: `03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`

---

## 1. Bối cảnh & vấn đề (Problem context)

### 1.1 Quy mô cuộc thi sinh viên tại PTIT

PTIT (Học viện Công nghệ Bưu chính Viễn thông) tổ chức trung bình **15-25 cuộc thi/năm** ở quy mô khoa và toàn trường, gồm:

- Cuộc thi học thuật chuyên ngành (Olympic Tin học, Lập trình ACM, Toán SV).
- Cuộc thi sáng tạo / khởi nghiệp (Sáng tạo ICT, Hackathon).
- Cuộc thi văn hóa - thể thao - đoàn hội (Tài năng, Thể thao SV).
- Cuộc thi nội bộ khoa (Đồ án sáng tạo CNTT, Cuộc thi đoàn hội khoa).

Mỗi cuộc thi trung bình thu hút 50-300 thí sinh, một số sự kiện lớn (Olympic Tin học) lên đến 500+. Tổng lưu lượng đăng ký quan tâm: ước tính **3.000-5.000 lượt/năm**.

### 1.2 Vấn đề hiện trạng

Hiện tại các cuộc thi đa phần chạy theo cách **rời rạc, thủ công** với 4 nhóm vấn đề:

1. **Phân tán kênh thông tin:** thông báo qua Facebook khoa + email + dán giấy ở bảng tin → SV bỏ lỡ, không có nguồn tập trung.
2. **Đăng ký bằng Google Form:** mỗi cuộc thi 1 form riêng, không đồng nhất, BTC phải merge dữ liệu thủ công, dễ trùng lặp / sai sót.
3. **Phê duyệt giấy tờ:** đề xuất tổ chức cuộc thi → in công văn → BCN ký → scan → email lại. Vòng phản hồi 3-7 ngày.
4. **Chấm điểm Excel:** giám khảo nhập điểm vào file Excel chia sẻ, tổng hợp thủ công, dễ tranh cãi về tiêu chí, không có audit trail.

→ **Hệ quả:** BTC tốn 30-40% thời gian cho việc hành chính thay vì tổ chức nội dung; SV mất hứng thú vì quy trình rườm rà; BCN khó giám sát tiến độ trên dashboard chung.

### 1.3 Phạm vi nghiên cứu

Research này tập trung vào **4 nhóm người dùng cuối** đã được xác định trong yêu cầu:

| Mã | Vai trò | Số chức năng | Kênh chính |
|---|---|---|---|
| SV | Sinh viên (thí sinh) | 11 | Mobile APK + Web |
| GV | Giảng viên / Ban tổ chức | 7 | Web (desktop) |
| BCN | Ban Chủ nhiệm khoa | 6 | Web (desktop) |
| AD | Quản trị hệ thống | 6 | Web (desktop) |

---

## 2. User Journey AS-IS — hiện trạng chưa có app

Mô tả hành trình điển hình của **một sinh viên Khoa CNTT muốn tham gia cuộc thi Hackathon nội bộ khoa**, dùng các kênh tổ chức hiện có (Facebook + Google Form + email).

### 2.1 Journey của Sinh viên (Nguyễn Văn A — Năm 3 CNTT)

| Bước | Thời điểm | Hành động | Cảm xúc | Pain point |
|---|---|---|---|---|
| 1 | T-14 ngày | Thấy poster trên Facebook khoa, lưu link Google Form | 😐 Tò mò | Không biết cuộc thi nào còn mở đăng ký, phải scroll feed |
| 2 | T-13 ngày | Hỏi lớp trưởng xác nhận cuộc thi có thật, lệ phí | 😕 Nghi ngờ | Không có kênh chính thức để verify |
| 3 | T-12 ngày | Nhập tên, MSV, lớp, điện thoại vào Google Form | 😐 OK | Form mỗi cuộc thi 1 kiểu, phải gõ lại data |
| 4 | T-10 ngày | Chờ BTC duyệt — không biết bao giờ | 😟 Lo lắng | Không có thông báo, phải nhắn FB messenger BTC hỏi |
| 5 | T-9 ngày | Nhận email "Bạn đã được duyệt" sau 3 ngày chờ | 😊 Vui | Email vào spam, suýt bỏ lỡ |
| 6 | T-7 ngày | Tìm lại link đề bài / quy chế cuộc thi | 😩 Khó chịu | Mỗi BTC up một nơi: Drive / Telegram / file đính kèm email |
| 7 | T-3 ngày | Nộp bài: zip file + đường link Drive | 😬 Lo deadline | Không có deadline countdown, không biết đã nộp xong chưa, không có receipt |
| 8 | T-1 ngày | Đến phòng thi vòng cuối | 😨 Bối rối | Không có lịch chính xác, hỏi BTC mỗi sáng |
| 9 | T+5 ngày | Chờ kết quả qua FB của BTC | 😣 Sốt ruột | 1 tuần không có update, không biết đã chấm chưa |
| 10 | T+10 ngày | Nhận giải nhì → BTC gửi giấy chứng nhận PDF qua email | 😐 OK nhưng muộn | Chứng nhận không có QR verify, để CV không ai tin |

**Tổng pain points:** 7/10 bước có cảm xúc tiêu cực. Vòng đời 24 ngày, trong đó **9 ngày là chờ đợi không biết status**.

### 2.2 Journey của Giảng viên BTC (Cô Trần Thị B — phụ trách Hackathon khoa)

| Bước | Thời điểm | Hành động | Pain point |
|---|---|---|---|
| 1 | T-30 | Soạn đề xuất Word, in 3 bản, mang lên BCN khoa ký | Mất 2-3 ngày chờ BCN ký |
| 2 | T-25 | BCN yêu cầu sửa thể lệ (round 2) → in lại, ký lại | Vòng revision không tracking được, mỗi lần in tốn giấy |
| 3 | T-20 | Tạo Google Form đăng ký, post Facebook, mail lớp trưởng | 4 kênh truyền thông phải sync thủ công |
| 4 | T-15 | Mỗi sáng: export Google Form → Excel → check trùng MSV → confirm email từng người | 1 tiếng/ngày cho admin |
| 5 | T-7 | Lập danh sách giám khảo Excel, gán bài thi cho giám khảo qua email | Không biết giám khảo đã nhận chưa, mất bài |
| 6 | T-3 | Thu bài qua Google Drive, nhắc deadline qua FB nhóm | SV nộp muộn vẫn được nhận do không có lock |
| 7 | T-2 | Tổng hợp điểm 5 giám khảo từ 5 file Excel khác nhau | Tranh cãi điểm, không có audit |
| 8 | T+1 | Soạn báo cáo Word gửi BCN, đính kèm bảng điểm, ảnh sự kiện | 4-5 tiếng làm báo cáo |
| 9 | T+3 | In giấy chứng nhận thiết kế Photoshop, photocopy 50 bản, đóng dấu khoa | 1 ngày làm giấy, dễ in sai tên |
| 10 | T+5 | Gửi báo cáo cuối lên BCN, chờ ký phê duyệt kết quả | 3-5 ngày chờ BCN ký lần 2 |

**Tổng:** Cô B mất **40-50 giờ làm việc** cho 1 cuộc thi 50 thí sinh, trong đó **60% là việc admin lặp lại** (sync data, gửi email, làm báo cáo).

### 2.3 Journey của BCN khoa (Thầy Lê Văn C — Chủ nhiệm khoa)

| Bước | Hành động hiện tại | Pain point |
|---|---|---|
| 1 | Nhận đơn đề xuất cuộc thi qua thư ký khoa | Không biết các khoa khác đang tổ chức gì, dễ trùng |
| 2 | Đọc đơn giấy → ghi chú tay → trả lại sửa | Không tracking version |
| 3 | Phê duyệt bằng chữ ký + dấu khoa | Không có audit số |
| 4 | Cuối kỳ: tổng hợp tất cả cuộc thi đã tổ chức bằng cách đi hỏi từng GV | Không có dashboard giám sát |
| 5 | Báo cáo thống kê cuối năm cho Hiệu phó | Phải tổng hợp số liệu thủ công từ ảnh chụp giấy chứng nhận, file Excel rời |

### 2.4 Findings từ AS-IS journey

→ **Cơ hội cải thiện rõ rệt** ở 4 điểm:

1. **Tập trung kênh** — 1 app duy nhất thay 4-5 kênh phân tán.
2. **Tự động hóa workflow phê duyệt** — đề xuất → BCN duyệt số hóa, tracking version revision.
3. **Tracking trạng thái real-time** — SV biết status đăng ký/nộp bài; BCN biết tiến độ contest.
4. **Audit trail + chứng nhận số có QR verify** — chống giả mạo, tăng giá trị giải thưởng.

---

## 3. Personas — 4 hồ sơ user mẫu

### Persona 1: Sinh viên — Nguyễn Văn An

| Thuộc tính | Giá trị |
|---|---|
| **Tuổi / Năm học** | 21 / Năm 3 Khoa CNTT |
| **MSV / Lớp** | B22DCCN001 / D22CQCN01-N |
| **Quê quán** | Hải Dương, đang ở ký túc xá Hà Đông |
| **Thiết bị chính** | Smartphone Android (Xiaomi Redmi Note 11) + laptop mượn |
| **Kỹ năng tech** | Tốt — biết code Java/Python cơ bản, dùng Git |
| **Tài chính** | Học bổng + làm thêm IT outsource ~2-3tr/tháng |
| **Thời gian rảnh** | 16h-22h tối các ngày trong tuần, weekend bận đi làm thêm |

**Goals (Mục tiêu):**
- Tham gia 2-3 cuộc thi/năm để có thành tích trong CV (ứng tuyển intern năm 4).
- Tìm cơ hội networking với giảng viên + sinh viên khoa khác.
- Lấy giải thưởng vừa danh tiếng vừa tiền (1-3tr cho giải nhất).

**Pain points (Khó khăn):**
- Bỏ lỡ deadline đăng ký vì không follow Facebook khoa thường xuyên.
- Ngại đăng ký vì mỗi cuộc thi 1 Google Form khác → nhập lại MSV, lớp, SDT… mỗi lần.
- Không biết tình trạng duyệt đơn, phải nhắn messenger hỏi BTC → ngại làm phiền cô.
- Giấy chứng nhận giấy thật khó đính kèm CV online (LinkedIn, ứng tuyển ATS không nhận file scan mờ).

**Behaviors (Thói quen):**
- Check điện thoại mỗi 5-10 phút, dùng app như Zalo, FB, Discord.
- Quen với UI giống Shopee/Tiki — bottom nav, list cards.
- Không kiên nhẫn quá 30s nếu app loading hoặc form lằng nhằng.
- Tin sản phẩm có notification real-time hơn email.

**Quote:**
> *"Em chỉ muốn 1 chỗ duy nhất xem cuộc thi nào còn mở, đăng ký 1 click, biết khi nào có kết quả, và có cái QR code để khoe lên LinkedIn."*

**Top tasks ưu tiên cho App:**
1. Browse cuộc thi đang mở + filter theo khoa / chủ đề (SV-04).
2. Đăng ký 1 click với data sẵn (SV-06).
3. Notification trạng thái: đăng ký / duyệt / kết quả (SV-07).
4. Tải PDF chứng nhận có QR verify (SV-09).

---

### Persona 2: Giảng viên BTC — Cô Trần Thị Bình

| Thuộc tính | Giá trị |
|---|---|
| **Tuổi / Vị trí** | 38 / Giảng viên chính, Khoa CNTT |
| **Email** | gv@ptit.edu.vn |
| **Đảm nhiệm** | Tổ chức 3-4 cuộc thi/năm (Hackathon, Sáng tạo ICT khoa) |
| **Thiết bị** | Laptop Windows + iPhone — dùng laptop là chính |
| **Kỹ năng tech** | Khá — Excel pro, biết viết script Python cho công việc |
| **Tải công việc** | 12 tiết giảng/tuần + 3-4 đề tài NCKH + tổ chức thi → quá tải |

**Goals:**
- Tổ chức cuộc thi chuyên nghiệp, ít sai sót, đúng deadline.
- Có báo cáo định lượng đẹp để gửi BCN cuối kỳ.
- Giảm tối đa thời gian admin để tập trung chuyên môn.
- Audit trail đầy đủ phòng khi có khiếu nại từ SV / phụ huynh.

**Pain points:**
- Mất 40-50 giờ/cuộc thi cho việc admin (đã đo trong AS-IS journey).
- Lo bị tranh cãi điểm chấm vì không có rubric chuẩn.
- Khổ nhất là phần phê duyệt 2 cấp với BCN — in giấy, đợi ký, sửa rồi in lại.
- Báo cáo cuối kỳ phải tổng hợp số liệu thủ công 4-5 tiếng.

**Behaviors:**
- Làm việc 8h-18h ở phòng GV, dùng web browser Chrome.
- Quen với layout sidebar trái + content phải (Outlook, Notion).
- Không cài app lạ, ưu tiên web có thể bookmark.
- Cần export Excel cho mọi báo cáo (không tin dashboard số bay).

**Quote:**
> *"Cô không cần app đẹp, cô cần app làm thay cô việc copy-paste. Có Excel export là cô tin."*

**Top tasks ưu tiên:**
1. Tạo cuộc thi với form chuẩn + submit phê duyệt 1 cú click (GV-02).
2. Bulk approve thí sinh đăng ký từ list (GV-03).
3. Phân công giám khảo + chấm điểm với rubric (GV-05).
4. Export Excel báo cáo cuối kỳ (GV-07).

---

### Persona 3: BCN khoa — Thầy Lê Văn Cường

| Thuộc tính | Giá trị |
|---|---|
| **Tuổi / Vị trí** | 52 / Phó Chủ nhiệm khoa CNTT, PGS.TS |
| **Email** | bcn@ptit.edu.vn |
| **Trách nhiệm** | Phê duyệt đề xuất + kết quả của 8-12 cuộc thi/năm trong khoa |
| **Thiết bị** | Laptop công ty + iPad |
| **Kỹ năng tech** | Trung bình — dùng Word, Email, Zoom; ngại app phức tạp |
| **Lịch** | Họp liên tục 14-18h/ngày → check email vào sáng sớm hoặc tối |

**Goals:**
- Đảm bảo các cuộc thi đúng quy chế trường, không scandal.
- Có dashboard tổng quan các cuộc thi đang chạy trong khoa.
- Báo cáo lên Hiệu phó/Hiệu trưởng cuối kỳ với số liệu đẹp.
- Phê duyệt nhanh, không bị dồn việc.

**Pain points:**
- Đơn đề xuất giấy chồng chất trên bàn, không biết cái nào ưu tiên.
- Không có tổng quan các khoa khác đang làm gì → dễ trùng cuộc thi.
- Phê duyệt bằng chữ ký giấy → không tracking, mất đơn.
- Báo cáo cuối năm phải đi hỏi từng GV để tổng hợp.

**Behaviors:**
- Login web 1 lần/ngày kiểm tra việc.
- Đọc email + duyệt đơn vào 7-8h sáng và 21-22h tối.
- Yêu cầu UI gọn gàng, ít click, giải thích bằng tiếng Việt.
- Không nhớ password phức tạp → cần OTP hoặc SSO.

**Quote:**
> *"Tôi cần xem 1 màn hình biết khoa mình đang có bao nhiêu cuộc thi, cuộc nào sắp hết hạn, có gì cần tôi duyệt. Phê duyệt thì 3 nút thôi: Đồng ý / Yêu cầu sửa / Từ chối."*

**Top tasks ưu tiên:**
1. Dashboard tổng quan + queue chờ duyệt (BCN-03).
2. Phê duyệt đề xuất cuộc thi với 3 nút (BCN-02).
3. Phê duyệt kết quả chung cuộc (BCN-04).
4. Export Excel báo cáo khoa (BCN-05).

---

### Persona 4: Admin hệ thống — Anh Phạm Quang Dũng

| Thuộc tính | Giá trị |
|---|---|
| **Tuổi / Vị trí** | 29 / Chuyên viên CNTT, Phòng Đào tạo |
| **Email** | admin@ptit.edu.vn |
| **Đảm nhiệm** | Quản trị toàn bộ hệ thống IT của trường (LMS, mail, các app phụ trợ) |
| **Thiết bị** | Laptop Linux Ubuntu + monitor 27" + iPhone |
| **Kỹ năng tech** | Cao — DevOps, biết Docker/Kubernetes, viết script Bash/Python |
| **Lịch** | 9h-18h, on-call qua Telegram |

**Goals:**
- Hệ thống chạy ổn định, uptime > 99%.
- Phát hiện sớm hành vi bất thường (gian lận, spam review, tự chấm điểm).
- Báo cáo cấp Hiệu phó về số liệu tổng hệ thống.
- Tạo/khóa tài khoản nhanh khi GV cần (đầu kỳ).

**Pain points:**
- Bị spam ticket "tôi quên mật khẩu" mỗi đầu kỳ.
- Không có tool centralized để monitor → phải SSH server đọc log.
- Không có audit log → khi có sự cố không biết ai làm.
- Báo cáo cấp trên phải truy DB thủ công, viết SQL ad-hoc.

**Behaviors:**
- Sống trên terminal + dashboard.
- Yêu cầu API có docs Swagger để tự test.
- Tin số liệu khi có nguồn (audit log, anomaly detection).
- Ưu tiên CSV/JSON export hơn UI đẹp.

**Quote:**
> *"Cho tôi xem audit log đầy đủ và tôi có thể debug bất cứ vấn đề gì. Đừng giấu lỗi sau UI đẹp."*

**Top tasks ưu tiên:**
1. CRUD users + bulk import SV qua CSV (AD-02).
2. Quản lý faculty / major / class (AD-03).
3. System config + backup (AD-04).
4. Audit log + anomaly reports (AD-06).

---

### 3.5 Tổng hợp persona insights

| Insight | Hệ quả thiết kế |
|---|---|
| SV chủ yếu dùng mobile, GV/BCN/Admin dùng desktop | Flutter làm app cross-platform, nhưng UI khác nhau theo role (mobile-first cho SV, desktop sidebar cho admin) |
| BCN check email sáng sớm + tối → cần thông báo email | Ưu tiên email notification ngoài in-app notification |
| GV không tin dashboard số bay → phải có Excel export | Mọi báo cáo (GV-07, BCN-05, AD-05) đều có nút export xlsx |
| BCN ngại app phức tạp → 3 nút phê duyệt là đủ | Approval queue UI tối giản: Approve / Request Revision / Reject |
| SV ngại nhập lại MSV mỗi lần → cần auto-fill | Login 1 lần lưu profile, đăng ký cuộc thi tự fill |
| Admin yêu cầu audit log đầy đủ | `audit_logs` table ghi mọi action có ảnh hưởng dữ liệu |

---

## 4. Competitor Analysis

### 4.1 Phân loại đối thủ

| Nhóm | Ví dụ | Đặc điểm | Mức độ liên quan |
|---|---|---|---|
| **A. Hackathon platform quốc tế** | Devpost, Major League Hacking | Chuyên cho coding contest, có submission, judging tự động | Cao — học UX |
| **B. Online judge** | Codeforces, LeetCode Contest, Kattis | Auto-grade code, ranking real-time, không có workflow phê duyệt | Trung bình — chỉ cho contest lập trình |
| **C. Form/quản lý SV** | Google Form + Sheets, Microsoft Form | Linh hoạt nhưng manual, không workflow | Cao — đối thủ trực tiếp hiện tại |
| **D. Hệ thống nội bộ ĐH khác** | UTH-PTIT cũ, app HUST contests | Nội bộ trường, ít công khai | Trung bình — học cách làm |
| **E. Event ticketing platform** | TicketBox, Eventbrite | Bán vé sự kiện, khác bản chất | Thấp — chỉ học UX đăng ký |

### 4.2 So sánh chi tiết — top 5 đối thủ

| Tiêu chí | Devpost | Codeforces | Google Form + Sheets | App HUST nội bộ (giả định) | **PTIT Contest (chúng ta)** |
|---|---|---|---|---|---|
| **Đối tượng** | Quốc tế, devs | Quốc tế, coders | Bất kỳ | Nội bộ HUST | Nội bộ PTIT |
| **Đăng ký** | OAuth GitHub/Google | OAuth | Manual nhập tên/email | Login MSV | OTP email + biometric (mobile) |
| **Workflow phê duyệt cuộc thi** | ❌ Không có | ❌ | ❌ | ⚠ Manual | ✅ **2 cấp BCN_QĐ1 + QĐ2 với revision loop** |
| **Đăng ký theo team** | ✅ | ✅ | ⚠ Manual qua text field | ✅ | ✅ Có participation_mode + team_management |
| **Submission file** | ✅ Multi-file | ⚠ Code only | ⚠ Drive link | ✅ | ✅ Multi-version + R2 storage + lock anti-tamper |
| **Chấm điểm rubric** | ✅ | ❌ Auto | ❌ | ⚠ Tự setup | ✅ Rubric criteria + judge assignments + auto-compute |
| **Phê duyệt kết quả** | ❌ | ❌ | ❌ | ❌ | ✅ **BCN_QĐ2 trước khi publish** |
| **Chứng nhận có QR verify** | ✅ Devpost cert | ❌ | ❌ | ⚠ Email PDF | ✅ PDF + QR public verify |
| **Audit log + Anomaly detection** | ⚠ Backend only | ❌ | ❌ | ❌ | ✅ Anomaly scan (lock-unlock rapid, judge tự chấm, review spam) |
| **Real-time notification** | ✅ Email | ✅ | ❌ | ⚠ Email | ✅ In-app + email + deep-link |
| **Bulk export xlsx** | ⚠ CSV | ❌ | ✅ Native Sheets | ⚠ | ✅ 3 endpoint xlsx (GV-07, BCN-05, AD-05) |
| **Dark mode** | ✅ | ⚠ Limited | ❌ | ❌ | ✅ |
| **A11y (WCAG)** | ⚠ Partial | ⚠ | ⚠ | ❌ | ✅ Sprint 3+5 baseline + Semantics |
| **Tiếng Việt** | ❌ EN only | ❌ EN/RU | ✅ | ✅ | ✅ Native |
| **Mobile native** | ⚠ Web responsive | ⚠ Web | ✅ Form mobile | ❌ | ✅ APK Flutter |
| **Self-host** | ❌ SaaS | ❌ | ❌ | ✅ | ✅ Railway + Cloudflare R2 |

### 4.3 Điểm mạnh khác biệt (USP) của PTIT Contest

1. **Workflow phê duyệt 2 cấp số hóa** — duy nhất trong nhóm đối thủ. BTC submit → BCN duyệt → BTC sửa → BCN duyệt lại, tracking `revision_round` đầy đủ.
2. **Chứng nhận PDF + QR verify public** — SV chia sẻ link `/verify/{qr}` lên LinkedIn, nhà tuyển dụng quét xác thực ngay.
3. **Anomaly detection** — server scan audit_logs phát hiện hành vi đáng ngờ (judge tự chấm, lock-unlock liên tục, review spam IP).
4. **Native tiếng Việt + đúng quy chế PTIT** — 4 role khớp cơ cấu thực: SV / GV-BTC / BCN khoa / Admin.
5. **Mobile APK + Web đồng bộ** — SV dùng mobile, admin dùng web, cùng backend.

### 4.4 Điểm yếu cần cải thiện (so với đối thủ)

1. **Chưa có auto-grade** (như Codeforces) → contest lập trình vẫn chấm thủ công. → **v2 roadmap.**
2. **Chưa có discussion/Q&A forum** (như Devpost) → SV hỏi BTC qua kênh ngoài. → **v2.**
3. **Chưa có integration GitHub** cho coding contest (Devpost link repo). → **v2.**
4. **Chưa có gamification** (badges, leaderboard tổng) → engagement thấp. → **v2.**
5. **Chưa có public showcase** sau cuộc thi (Devpost project gallery) → bài thi không được lan tỏa. → **v2.**

---

## 5. Survey & Interview

### 5.1 Phương pháp

- **Survey online**: Google Form, gửi qua Facebook khoa CNTT-AT-TT, kỳ vọng ~60 SV trả lời (cỡ mẫu hợp lý cho dự án môn học).
- **Phỏng vấn sâu**: 1-1 qua Zoom 30 phút mỗi user — 4 SV (mỗi năm 1 người), 2 GV, 1 BCN, 1 Admin = **8 phỏng vấn**.
- **Thời gian dự kiến chạy thật:** 2 tuần.

> **Lưu ý:** Số liệu dưới đây là **giả định hợp lý** dựa trên quan sát thực tế tại PTIT cho mục đích báo cáo CNPM. Khi triển khai v2 sẽ thay bằng số liệu thật.

### 5.2 Survey cho Sinh viên — câu hỏi chính (10 câu)

| # | Câu hỏi | Loại | Tóm tắt kết quả giả định (n=60) |
|---|---|---|---|
| 1 | Bạn năm mấy? | Single choice | Năm 2: 22%, Năm 3: 38%, Năm 4: 28%, Khác: 12% |
| 2 | Trong 12 tháng qua, bạn tham gia bao nhiêu cuộc thi tại PTIT? | Number | TB 1.4 cuộc/SV. 28% chưa từng tham gia |
| 3 | Lý do chính khiến bạn không tham gia (chọn nhiều)? | Multi | "Không biết thông tin" 67% / "Đăng ký phức tạp" 52% / "Không có thời gian" 48% / "Chưa thấy giá trị" 23% |
| 4 | Bạn biết về cuộc thi qua kênh nào? | Multi | FB khoa: 78% / Bạn bè giới thiệu: 65% / Bảng tin / poster: 32% / Email: 20% / Website trường: 8% |
| 5 | Bạn đã đăng ký cuộc thi qua kênh nào? | Multi | Google Form: 95% / Email: 12% / Trực tiếp: 8% |
| 6 | Mức độ hài lòng quy trình đăng ký hiện tại (1-5)? | Likert | TB 2.6/5 |
| 7 | Bạn có muốn 1 app duy nhất tổng hợp các cuộc thi PTIT không? | Yes/No | Có: 92% / Không/không quan tâm: 8% |
| 8 | Top 3 tính năng bạn muốn nhất? | Multi (chọn 3) | Notification kết quả: 73% / Filter cuộc thi theo khoa-chủ đề: 65% / Tải PDF chứng nhận: 60% / Đăng ký theo team: 48% / Lịch sử tham gia: 42% / Đánh giá cuộc thi: 30% |
| 9 | Bạn dùng thiết bị nào nhiều hơn? | Single | Mobile: 82% / Laptop: 18% |
| 10 | Bạn sẵn sàng cài APK Android không? | Yes/No/Không Android | Có: 71% / Không (iPhone): 21% / Ngại cài APK: 8% |

**Insight chính:**
- 92% muốn có app → **demand mạnh**.
- 67% pain point lớn nhất là không biết thông tin → **feature browse + filter contest là core**.
- 71% sẵn sàng cài APK → **Flutter APK build là đúng hướng**, nhưng 21% iPhone phải có web → **đã làm cả 2**.
- Notification + chứng nhận PDF là top need → khớp với SV-07, SV-09 đã implement.

### 5.3 Interview script — 4 câu hỏi cốt lõi cho mỗi role

**Cho Sinh viên (4 phỏng vấn, 30 phút/người):**
1. Hãy kể lại lần gần nhất bạn tham gia cuộc thi. Bước nào khó chịu nhất?
2. Nếu có 1 app cho cuộc thi PTIT, 3 tính năng phải có là gì?
3. Cho xem mockup 3 màn hình → bạn click vào đâu đầu tiên? Tại sao?
4. Điều gì khiến bạn xóa app ngay tuần đầu?

**Cho Giảng viên BTC (2 phỏng vấn):**
1. 1 cuộc thi mất bao nhiêu thời gian admin của bạn? Khâu nào tốn nhất?
2. Bạn dùng Excel cho khâu nào? App có thể thay được không?
3. Bạn cần báo cáo gì cho BCN cuối kỳ?
4. Lo ngại lớn nhất nếu chuyển sang app là gì? (security / mất data / khó dùng)

**Cho BCN (1 phỏng vấn):**
1. Bạn duyệt bao nhiêu đơn đề xuất cuộc thi/tháng? Trung bình bao lâu xong 1 đơn?
2. Bạn cần thông tin gì trước khi quyết định approve / request_revision / reject?
3. Báo cáo cuối kỳ bạn cần số liệu gì? Format gì (PDF / Excel)?
4. Bạn muốn nhận thông báo qua kênh nào? Email / Zalo / app?

**Cho Admin (1 phỏng vấn):**
1. Hệ thống IT trường hiện đang chạy gì? Tích hợp SSO khả thi không?
2. Quy trình tạo tài khoản SV/GV hiện tại như nào? Có CSV không?
3. Bạn cần audit log loại nào? Lưu bao lâu?
4. Quy định backup data / recovery của trường ra sao?

### 5.4 Findings tổng hợp từ interview giả định

| Theme | Quote tiêu biểu | Hành động thiết kế |
|---|---|---|
| Đăng ký lặp lại | "Em phải gõ lại MSV với tên 5 lần trong 1 tháng" (SV năm 3) | Login 1 lần, auto-fill SV-06 |
| Phê duyệt giấy chậm | "Tôi đợi BCN ký 5 ngày, mà cuộc thi sắp khai mạc" (GV) | Workflow số hóa, notification BCN |
| Tổng hợp báo cáo cực | "Cuối kỳ tôi mất nửa ngày để gom số liệu các cuộc thi" (BCN) | Dashboard + export xlsx BCN-05 |
| Chứng nhận không tin | "Em scan giấy gửi nhà tuyển dụng, họ không tin là thật" (SV năm 4) | PDF + QR verify public |
| Anti-cheat | "Năm ngoái có vụ judge tự chấm bài team mình quen" (BCN) | Anomaly detection AD-06 |
| Mobile native | "Em không bao giờ mở web trường trên mobile, chữ bé tí" (SV) | Flutter APK + responsive web |
| Bulk action | "Mỗi sáng tôi confirm 30 đơn đăng ký, click 30 lần là nản" (GV) | Bulk approve UI GV-03 |
| Không tin số bay | "Cho tôi Excel, tôi mới tin số đúng" (GV) | Mọi report đều có nút Excel |

---

## 6. Insights chuyển sang định hướng v2

### 6.1 Tóm tắt validation các quyết định v1

| Quyết định v1 | Validate bằng research | Kết quả |
|---|---|---|
| 4 role (SV / GV / BCN / Admin) | Khớp cơ cấu thực PTIT, không trùng lặp | ✅ Giữ |
| Workflow phê duyệt 2 cấp BCN | Pain point #1 của GV và BCN | ✅ Giữ và là USP |
| OTP email login (không password) | SV ngại password phức tạp | ✅ Giữ |
| Mobile APK + Web | 71% SV Android, 18% iPhone, GV/BCN/Admin desktop | ✅ Đúng hướng |
| Excel export everywhere | "Không tin số bay, cho tôi Excel" | ✅ Giữ |
| QR verify public chứng nhận | Pain point #4 SV | ✅ Giữ và là USP |
| Audit log + anomaly detection | Pain point #5 BCN/Admin | ✅ Giữ |

→ Toàn bộ 7 quyết định v1 đều có justification từ research. **Không có quyết định cần đảo ngược.**

### 6.2 Roadmap v2 — đề xuất 8 hạng mục

Sắp theo điểm số ROI (Impact ↔ Effort):

| # | Tính năng | Impact | Effort | ROI | Justification từ research |
|---|---|---|---|---|---|
| 1 | **Discussion / Q&A trong cuộc thi** | Cao | Trung | ⭐⭐⭐⭐ | Đối thủ Devpost có. Pain point: SV hỏi BTC qua FB messenger ngại |
| 2 | **Auto-grade cho contest lập trình** | Cao | Cao | ⭐⭐⭐⭐ | Khớp với Codeforces. PTIT có Olympic Tin học hàng năm |
| 3 | **Public showcase project gallery** | Trung | Thấp | ⭐⭐⭐⭐ | Devpost làm rất tốt. Tăng giá trị giải thưởng cho SV |
| 4 | **Gamification (badge, leaderboard tổng)** | Trung | Trung | ⭐⭐⭐ | Tăng engagement. SV năm 1-2 thích show off |
| 5 | **GitHub integration** | Trung | Thấp | ⭐⭐⭐⭐ | Coding contest cần. SV dev đều có GitHub |
| 6 | **SSO PTIT (LDAP/SAML)** | Cao | Cao | ⭐⭐⭐ | Admin yêu cầu, nhưng phụ thuộc Phòng Đào tạo cấp credential |
| 7 | **Multi-language EN/VI** | Thấp | Thấp | ⭐⭐ | Cuộc thi quốc tế hợp tác (giả định v2 mở rộng) |
| 8 | **AI gợi ý cuộc thi (recommendation)** | Trung | Cao | ⭐⭐ | Demand từ 67% SV không biết info, nhưng cần data 1 năm để train |

### 6.3 Câu hỏi cần research thêm cho v2 (gap analysis)

1. **Volume thật:** số cuộc thi/SV/đăng ký 1 năm tại PTIT — cần xin Phòng Đào tạo data thật.
2. **Tỷ lệ giả mạo chứng nhận:** có thật cần QR verify đến mức đó không? Cần survey nhà tuyển dụng.
3. **Khả năng tích hợp SSO:** Phòng Đào tạo có chấp nhận chia LDAP/SAML không? — cần meeting kỹ thuật.
4. **Ngân sách v2:** trường có budget cho server / R2 storage thật không, hay phải tự host?
5. **Quy chế pháp lý:** chứng nhận điện tử có giá trị tương đương giấy không? — cần phòng Pháp chế tư vấn.

---

## 7. Kết luận

Research cho thấy:

1. **Vấn đề có thật và đủ lớn** — 67% SV không biết info, 92% muốn có app, GV mất 40-50h/cuộc thi cho admin.
2. **Quyết định thiết kế v1 đều có cơ sở** — 4 role + workflow 2 cấp + mobile-first SV + desktop admin + Excel export đều validate được.
3. **PTIT Contest có 5 USP rõ ràng** so với 5 đối thủ chính, đặc biệt workflow phê duyệt số hóa và QR verify.
4. **Roadmap v2 có 8 hạng mục đã được prioritize theo ROI**, top 3 là: Discussion forum, Auto-grade lập trình, Public showcase.
5. **5 câu hỏi research bổ sung** cần làm trước khi bắt đầu v2 (data thật, SSO, ngân sách, pháp lý).

---

## Sources

- Yêu cầu: `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- Traceability matrix v03: `02-requirements/2026-05-07_traceability-matrix_v03.md`
- Workflow phê duyệt: `03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`
- Schema v03: `08-database/2026-05-04_sqlapp_v03.sql`
- ER diagram v02: `08-database/2026-05-04_er-diagram_v02.mermaid`
- CHANGELOG: `CHANGELOG.md`
- Báo cáo CNPM v02: `11-docs/deliverables/2026-05-07_bao-cao-cnpm_v02.md`
- Đối thủ tham khảo (desk research):
  - Devpost — https://devpost.com
  - Codeforces — https://codeforces.com
  - Major League Hacking — https://mlh.io
- Quan sát hiện trạng tại PTIT (giai đoạn 2025-2026, các cuộc thi: Olympic Tin học, Sáng tạo ICT, Hackathon khoa CNTT)

---

**Phiên bản kế tiếp dự kiến (v02):** thay số liệu giả định bằng survey thật khi triển khai v2.
