// Redesign 2026-06-20: nội dung giải thích nghiệp vụ cho nút (?) ở từng màn.
// Mỗi entry = tiêu đề + đoạn mở đầu + các gạch đầu dòng. Wire qua HelpButton(id:).

class HelpInfo {
  final String title;
  final String intro;
  final List<String> points;
  const HelpInfo({
    required this.title,
    required this.intro,
    required this.points,
  });
}

const Map<String, HelpInfo> kHelpContent = {
  // ================= Sinh viên (SV) =================
  'sv_home': HelpInfo(
    title: 'Trang chủ sinh viên',
    intro:
        'Tổng quan nhanh hoạt động dự thi của bạn: cuộc thi nổi bật, sự kiện sắp tới và lối tắt tới các chức năng chính.',
    points: [
      'Khối nổi bật giới thiệu cuộc thi đang mở đăng ký đáng chú ý.',
      'Mốc thời gian sắp tới nhắc bạn hạn đăng ký, ngày thi.',
      'Bấm vào thẻ bất kỳ để xem chi tiết hoặc đăng ký.',
    ],
  ),
  'sv_contest_list': HelpInfo(
    title: 'Khám phá cuộc thi',
    intro:
        'Nơi xem mọi cuộc thi của trường. Danh sách được gom nhóm theo trạng thái để bạn dễ tìm cuộc thi còn đăng ký được.',
    points: [
      'Strip trên cùng tóm tắt: tổng số, đang mở đăng ký, đang diễn ra.',
      'Nhóm "Đang mở đăng ký" là các cuộc thi bạn có thể ghi danh ngay.',
      'Dùng ô tìm kiếm và bộ lọc (icon phễu) để thu hẹp kết quả.',
      'Bấm một cuộc thi để xem thể lệ, lịch, giải thưởng và nút Đăng ký.',
    ],
  ),
  'sv_my_registrations': HelpInfo(
    title: 'Đăng ký của tôi',
    intro:
        'Theo dõi các cuộc thi bạn đã ghi danh và tiến độ của từng cái — từ lúc chờ BTC duyệt đến khi kết thúc.',
    points: [
      'Nhóm theo giai đoạn: Đang dự thi, Chờ duyệt, Đã hoàn thành.',
      'Thanh tiến độ mỗi thẻ cho biết bạn đang ở bước nào.',
      'Trạng thái "Chờ duyệt" nghĩa là BTC chưa xác nhận đăng ký của bạn.',
      'Khi cuộc thi mở nộp bài, nút "Nộp bài" sẽ xuất hiện trên thẻ.',
    ],
  ),
  'sv_my_results': HelpInfo(
    title: 'Kết quả của tôi',
    intro:
        'Điểm, xếp hạng và giải thưởng của bạn sau khi ban giám khảo chấm và BTC công bố kết quả.',
    points: [
      'Strip tóm tắt: tổng kết quả, số lần có giải, hạng cao nhất.',
      'Kết quả được gom theo tháng công bố.',
      'Thẻ có giải được tô nổi bật kèm huy hiệu.',
      'Bấm "Xác thực / Tải chứng nhận" để lấy chứng nhận điện tử có QR.',
    ],
  ),
  'sv_my_calendar': HelpInfo(
    title: 'Lịch của tôi',
    intro:
        'Tập hợp các mốc thời gian quan trọng của những cuộc thi bạn tham gia, sắp xếp theo thời gian.',
    points: [
      'Gồm hạn đăng ký, ngày bắt đầu/kết thúc, hạn nộp bài.',
      'Giúp bạn không bỏ lỡ deadline của các cuộc thi đã ghi danh.',
    ],
  ),
  'sv_my_certificates': HelpInfo(
    title: 'Chứng nhận',
    intro:
        'Kho chứng nhận điện tử bạn đã được trao. Mỗi chứng nhận có mã QR để bất kỳ ai cũng xác thực được.',
    points: [
      'Chứng nhận phát hành tự động khi bạn đạt giải hoặc hoàn thành.',
      'Bấm một chứng nhận để xem, tải về hoặc lấy link xác thực.',
    ],
  ),
  'sv_notifications': HelpInfo(
    title: 'Thông báo',
    intro:
        'Các cập nhật hệ thống gửi cho bạn về đăng ký, phê duyệt, lịch thi và kết quả.',
    points: [
      'Thông báo nhóm theo thời gian: Hôm nay, Tuần này, Cũ hơn.',
      'Bấm vào một thông báo để tới màn liên quan.',
    ],
  ),
  'sv_profile': HelpInfo(
    title: 'Hồ sơ',
    intro:
        'Thông tin cá nhân và thống kê thành tích của bạn trong hệ thống.',
    points: [
      'Xem nhanh số cuộc thi tham gia, số giải, số chứng nhận.',
      'Vào "Cài đặt" để cập nhật thông tin hoặc đổi giao diện sáng/tối.',
    ],
  ),

  // ================= Giảng viên / BTC =================
  'gv_dashboard': HelpInfo(
    title: 'Bảng điều khiển BTC',
    intro:
        'Tổng quan công việc tổ chức của bạn: số cuộc thi đang chạy, bài chờ chấm, lịch sắp tới và hoạt động gần đây.',
    points: [
      'Các thẻ thống kê lấy số liệu trực tiếp từ cuộc thi bạn phụ trách.',
      '"Cuộc thi của tôi" liệt kê nhanh các cuộc thi với tiến độ.',
      '"Hoạt động gần đây" là nhật ký thao tác trên cuộc thi của bạn.',
    ],
  ),
  'gv_contests': HelpInfo(
    title: 'Quản lý Cuộc thi',
    intro:
        'Tạo và điều hành các cuộc thi do bạn (BTC) tổ chức. Cuộc thi phải được BCN khoa phê duyệt 2 cấp trước khi mở.',
    points: [
      'Strip thống kê + bảng gom nhóm theo trạng thái để dễ theo dõi.',
      'Bản nháp (DRAFT) → bấm gửi để BCN duyệt Quyết định 1, rồi Quyết định 2.',
      'Vạch màu bên trái mỗi hàng cho biết nhóm trạng thái.',
      'Bấm một hàng để vào trang quản lý chi tiết (vòng, tiêu chí, thí sinh).',
    ],
  ),
  'gv_judge': HelpInfo(
    title: 'Chấm bài',
    intro:
        'Các bài bạn được phân công chấm, gom theo cuộc thi và vòng thi. Mỗi nhóm có thanh tiến độ đã chấm.',
    points: [
      'Strip tóm tắt: cần chấm, đã chấm, tiến độ tổng.',
      'Thẻ "Bắt đầu chấm" đưa bạn tới bài chưa chấm đầu tiên.',
      'Bấm tên cuộc thi để thu/mở danh sách bài theo từng vòng.',
      'Mỗi bài chấm theo các tiêu chí (rubric) mà BTC đã thiết lập.',
      'Chế độ "Blind" ẩn danh tính thí sinh để chấm khách quan.',
    ],
  ),
  'gv_calendar': HelpInfo(
    title: 'Lịch & deadline',
    intro:
        'Toàn bộ mốc thời gian của các cuộc thi bạn tổ chức — mở/đóng đăng ký, bắt đầu, kết thúc.',
    points: [
      'Chuyển giữa "Dòng thời gian" (nhóm theo mốc) và "Lịch tháng".',
      'Mốc còn dưới 24h được tô nổi bật để bạn ưu tiên xử lý.',
      'Trong lịch tháng, ngày có deadline được chấm màu; bấm để xem chi tiết.',
    ],
  ),
  'gv_results': HelpInfo(
    title: 'Kết quả',
    intro:
        'Tổng hợp kết quả các cuộc thi đã kết thúc do bạn tổ chức, kèm link bảng xếp hạng và xuất Excel.',
    points: [
      'Strip tóm tắt: số cuộc thi đã xong, tổng thí sinh, lần gần nhất.',
      'Kết quả gom theo tháng kết thúc; dùng ô tìm kiếm để lọc.',
      'Bấm "Xuất Excel" để tải báo cáo kết quả chi tiết của một cuộc thi.',
    ],
  ),
  'gv_stats': HelpInfo(
    title: 'Thống kê',
    intro:
        'Các chỉ số tổng hợp về cuộc thi, thí sinh và tiến độ chấm của bạn.',
    points: [
      'Dùng để nắm bức tranh chung và phục vụ báo cáo.',
    ],
  ),
  'gv_export': HelpInfo(
    title: 'Xuất báo cáo',
    intro:
        'Xuất dữ liệu hệ thống ra file Excel để lưu trữ hoặc nộp cấp trên.',
    points: [
      'Báo cáo tổng hợp toàn hệ thống ở đây.',
      'Để xuất riêng một cuộc thi: vào cuộc thi đó → tab Kết quả → Xuất Excel.',
    ],
  ),

  // ================= Ban chủ nhiệm khoa (BCN) =================
  'bcn_dashboard': HelpInfo(
    title: 'Bảng điều khiển BCN',
    intro:
        'Tổng quan công việc phê duyệt của khoa: hàng chờ duyệt, việc sắp hạn, cuộc thi đang diễn ra và hiệu suất duyệt.',
    points: [
      'Thẻ "Chờ duyệt" và "Sắp hạn ≤24h" giúp ưu tiên xử lý.',
      'Hàng đợi ưu tiên xếp theo thời hạn (SLA) còn lại.',
    ],
  ),
  'bcn_approval': HelpInfo(
    title: 'Phê duyệt',
    intro:
        'Xét duyệt các đề xuất cuộc thi do BTC gửi lên, theo quy trình 2 cấp của khoa.',
    points: [
      'Quyết định 1 (QĐ1): duyệt chủ trương tổ chức cuộc thi.',
      'Quyết định 2 (QĐ2): duyệt kết quả/khen thưởng trước khi công bố.',
      'Có thể Duyệt, Từ chối, hoặc Yêu cầu chỉnh sửa kèm ghi chú cho BTC.',
    ],
  ),
  'bcn_monitor': HelpInfo(
    title: 'Giám sát',
    intro:
        'Theo dõi tình hình các cuộc thi trong khoa và phát hiện bất thường.',
    points: [
      'Giúp BCN nắm tiến độ và can thiệp kịp thời khi cần.',
    ],
  ),
  'bcn_cert_templates': HelpInfo(
    title: 'Mẫu chứng nhận',
    intro:
        'Quản lý các mẫu chứng nhận cấp khoa dùng để phát cho thí sinh đạt giải.',
    points: [
      'Tạo/sửa mẫu: tên, bố cục, người ký, trạng thái sử dụng.',
      'Mẫu đang bật sẽ được dùng khi phát chứng nhận cho cuộc thi của khoa.',
    ],
  ),
  'bcn_faculty_stats': HelpInfo(
    title: 'Thống kê khoa',
    intro:
        'Các chỉ số tổng hợp về cuộc thi và sinh viên thuộc khoa của bạn.',
    points: [
      'Phục vụ đánh giá hoạt động và báo cáo cấp trên.',
    ],
  ),
  'bcn_bgh_report': HelpInfo(
    title: 'Báo cáo BGH',
    intro:
        'Tổng hợp số liệu để báo cáo lên Ban giám hiệu.',
    points: [
      'Xuất các chỉ số chính của khoa theo kỳ.',
    ],
  ),

  // ================= Quản trị (Admin) =================
  'admin_dashboard': HelpInfo(
    title: 'Bảng điều khiển Quản trị',
    intro:
        'Tổng quan sức khỏe hệ thống và hoạt động toàn trường.',
    points: [
      'Theo dõi tình trạng hệ thống và nhật ký kiểm toán gần đây.',
    ],
  ),
  'admin_users': HelpInfo(
    title: 'Quản lý Tài khoản',
    intro:
        'Tạo, phân quyền và quản lý tài khoản người dùng trong hệ thống.',
    points: [
      'Mỗi người dùng có thể mang nhiều vai trò (SV, GV, BCN, Admin).',
      'Dùng tìm kiếm và bộ lọc trạng thái để tìm tài khoản.',
    ],
  ),
  'admin_contests': HelpInfo(
    title: 'Cuộc thi (Quản trị)',
    intro:
        'Xem và can thiệp mọi cuộc thi trên toàn hệ thống, không giới hạn theo khoa.',
    points: [
      'Quyền cao nhất: hỗ trợ xử lý khi BTC/BCN gặp vướng mắc.',
    ],
  ),
  'admin_configs': HelpInfo(
    title: 'Cấu hình hệ thống',
    intro:
        'Thiết lập tham số vận hành và các tác vụ bảo trì hệ thống.',
    points: [
      'Thay đổi ở đây ảnh hưởng toàn hệ thống — thao tác cẩn trọng.',
    ],
  ),
  'admin_audit': HelpInfo(
    title: 'Nhật ký kiểm toán',
    intro:
        'Lịch sử các thao tác quan trọng trong hệ thống để truy vết khi cần.',
    points: [
      'Mỗi bản ghi gồm người thực hiện, hành động và thời điểm.',
    ],
  ),
  'admin_anomaly': HelpInfo(
    title: 'Báo cáo bất thường',
    intro:
        'Tổng hợp các dấu hiệu bất thường cần admin xem xét.',
    points: [
      'Giúp phát hiện sớm gian lận hoặc lỗi vận hành.',
    ],
  ),
};
