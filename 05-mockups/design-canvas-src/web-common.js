// Common helpers — plain JS so all screens can reuse without re-declaration.
window.WEB = (function () {
  return {
    NAV_GV: [
      { section: 'Tổng quan' },
      { ico: '🏠', label: 'Dashboard', href: '/dashboard' },
      { ico: '📅', label: 'Lịch & deadline', href: '/calendar' },
      { section: 'Cuộc thi' },
      { ico: '🏆', label: 'Cuộc thi của tôi', href: '/contests', badge: '4' },
      { ico: '➕', label: 'Tạo cuộc thi', href: '/contests/new' },
      { ico: '⚖️', label: 'Chấm bài', href: '/judge', badge: '12' },
      { ico: '📊', label: 'Kết quả', href: '/results' },
      { section: 'Báo cáo' },
      { ico: '📈', label: 'Thống kê', href: '/stats' },
      { ico: '📥', label: 'Xuất báo cáo', href: '/export' },
    ],
    NAV_BCN: [
      { section: 'Tổng quan' },
      { ico: '🏠', label: 'Dashboard', href: '/dashboard' },
      { section: 'Phê duyệt' },
      { ico: '📋', label: 'Đề xuất cuộc thi', href: '/approve/proposals', badge: '7' },
      { ico: '🏅', label: 'Kết quả cuộc thi', href: '/approve/results', badge: '3' },
      { ico: '📜', label: 'Mẫu chứng nhận', href: '/approve/certs', badge: '2' },
      { section: 'Theo dõi' },
      { ico: '👁️', label: 'Giám sát', href: '/monitor' },
      { ico: '📈', label: 'Thống kê khoa', href: '/stats' },
      { ico: '📥', label: 'Báo cáo BGH', href: '/reports' },
    ],
    NAV_AD: [
      { section: 'Tổng quan' },
      { ico: '🏠', label: 'Dashboard', href: '/dashboard' },
      { section: 'Người dùng' },
      { ico: '👥', label: 'Tài khoản', href: '/users', badge: '1.8K', badgeGray: true },
      { ico: '🔑', label: 'Roles & Permission', href: '/rbac' },
      { ico: '🏛️', label: 'Khoa / Ngành / Lớp', href: '/master' },
      { section: 'Hệ thống' },
      { ico: '⚙️', label: 'Cấu hình', href: '/configs' },
      { ico: '📋', label: 'Audit log', href: '/audit' },
      { ico: '💾', label: 'Backup & Restore', href: '/backup' },
      { section: 'Báo cáo' },
      { ico: '📈', label: 'Thống kê hệ thống', href: '/stats' },
    ],
  };
})();
