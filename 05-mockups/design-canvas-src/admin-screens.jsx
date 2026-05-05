/* global React */
const { Browser, Sidebar, ScreenWrap, PageHead } = window;

const ADWHO = { initials: 'AD', name: 'Admin Hệ thống', sub: 'sysadmin@ptit.edu.vn' };
function AdShell({ active, url, children }) {
  return (
    <Browser url={url}>
      <Sidebar items={window.WEB.NAV_AD} active={active} role="Quản trị" who={ADWHO} />
      <div className="main">{children}</div>
    </Browser>
  );
}

/* ============================================================ */
function AD01_Dashboard() {
  return (
    <ScreenWrap label="Admin Dashboard" code="AD-01 (sau login) + AD-05 summary">
      <AdShell active="/dashboard" url="/dashboard">
        <PageHead
          crumbs={["Trang chủ"]}
          title="Admin Dashboard"
          actions={<div className="muted text-sm mono">📅 04/05/2026 · Last backup: 03/05 02:00 ✓</div>}
        />

        <div className="stats">
          <div className="stat"><div className="label-mono">Tổng tài khoản</div><div className="num">1,847</div><div className="delta">▲ +47 tháng này</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Đang hoạt động (24h)</div><div className="num">1,212</div><div className="delta">▲ 65.6%</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Cuộc thi 2026</div><div className="num">42</div><div className="delta">▲ +12 vs 2025</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Storage dùng</div><div className="num">412 <span style={{ fontSize: 14, color: 'var(--fg-muted)' }}>GB</span></div><div className="delta flat">— 41% / 1TB</div><div className="accent-bar" /></div>
        </div>

        <div className="grid-21" style={{ alignItems: 'stretch' }}>
          <div className="col">
            <div className="card">
              <div className="title">System health <span className="right text-xs muted mono">cập nhật 12s trước</span></div>
              <div className="grid-3">
                <div className="health-card">
                  <div className="row between"><div className="name"><span className="dot-status ok"></span>API gateway</div><span className="text-xs mono" style={{ color: 'var(--ok)' }}>OK</span></div>
                  <div className="val">142<span style={{ fontSize: 12, color: 'var(--fg-muted)', fontWeight: 500 }}>ms</span></div>
                  <div className="meta">p95 latency · 12 nodes</div>
                </div>
                <div className="health-card">
                  <div className="row between"><div className="name"><span className="dot-status ok"></span>Database</div><span className="text-xs mono" style={{ color: 'var(--ok)' }}>OK</span></div>
                  <div className="val">62<span style={{ fontSize: 12, color: 'var(--fg-muted)', fontWeight: 500 }}>%</span></div>
                  <div className="meta">CPU · primary + 2 replica</div>
                </div>
                <div className="health-card warn">
                  <div className="row between"><div className="name"><span className="dot-status warn"></span>Mail queue</div><span className="text-xs mono" style={{ color: 'var(--warn)' }}>WARN</span></div>
                  <div className="val">418</div>
                  <div className="meta">đang chờ gửi · backlog +12%</div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Audit log live <span className="right text-xs muted">10 entries gần nhất</span></div>
              <div className="audit-log" style={{ maxHeight: 280 }}>
                <div className="row"><span className="ts">11:42:18</span><span className="lvl ok">OK</span><span className="who">gv.tuan@ptit</span><span className="msg">contest.create <span className="arg">"Hackathon 2026"</span> <span className="id">id=#42</span></span></div>
                <div className="row"><span className="ts">11:38:02</span><span className="lvl info">INFO</span><span className="who">bcn.hoang@ptit</span><span className="msg">approval.decide <span className="arg">APPROVE</span> <span className="id">id=#7</span></span></div>
                <div className="row"><span className="ts">11:32:55</span><span className="lvl ok">OK</span><span className="who">sv.B23DCCN112</span><span className="msg">contest.register <span className="arg">"Olympic 2026"</span> <span className="id">entry=#2087</span></span></div>
                <div className="row"><span className="ts">11:28:14</span><span className="lvl warn">WARN</span><span className="who">system</span><span className="msg">mail.queue.backlog <span className="arg">418 pending</span></span></div>
                <div className="row"><span className="ts">11:24:31</span><span className="lvl ok">OK</span><span className="who">gv.vinh@ptit</span><span className="msg">judge.score.submit <span className="arg">entry=#87 score=80</span></span></div>
                <div className="row"><span className="ts">11:21:08</span><span className="lvl info">INFO</span><span className="who">admin</span><span className="msg">user.create <span className="arg">role=BCN</span> <span className="id">id=#1848</span></span></div>
                <div className="row"><span className="ts">11:17:42</span><span className="lvl err">ERR</span><span className="who">sv.B22DCCN044</span><span className="msg">auth.login <span className="arg">3 fails</span> <span className="id">ip=10.20.4.18</span></span></div>
                <div className="row"><span className="ts">11:12:29</span><span className="lvl ok">OK</span><span className="who">cron</span><span className="msg">backup.incremental <span className="arg">2.4 GB</span> <span className="id">elapsed=14s</span></span></div>
                <div className="row"><span className="ts">11:08:11</span><span className="lvl ok">OK</span><span className="who">gv.thanh@ptit</span><span className="msg">contest.update <span className="arg">"Web Design 2026"</span></span></div>
                <div className="row"><span className="ts">11:04:52</span><span className="lvl info">INFO</span><span className="who">system</span><span className="msg">cert.batch.issue <span className="arg">218 certs</span> <span className="id">contest=#OLY-2025</span></span></div>
              </div>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Phân bổ vai trò</div>
              <div className="row gap-3 mb-3">
                <div className="donut">
                  <svg viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--bg-sunken)" strokeWidth="14" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--accent)" strokeWidth="14" strokeDasharray="220 240" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="oklch(0.6 0.15 250)" strokeWidth="14" strokeDasharray="14 240" strokeDashoffset="-220" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="oklch(0.7 0.15 80)" strokeWidth="14" strokeDasharray="4 240" strokeDashoffset="-234" strokeLinecap="round" />
                  </svg>
                  <div className="label"><div><div className="num">1,847</div><div className="lbl">Users</div></div></div>
                </div>
                <div style={{ flex: 1, fontSize: 12, lineHeight: 2 }}>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--accent)' }} /> Sinh viên <b className="mono" style={{ marginLeft: 'auto' }}>1,712</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'oklch(0.6 0.15 250)' }} /> GV/BTC <b className="mono" style={{ marginLeft: 'auto' }}>108</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'oklch(0.7 0.15 80)' }} /> BCN <b className="mono" style={{ marginLeft: 'auto' }}>24</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'oklch(0.5 0.18 290)' }} /> Admin <b className="mono" style={{ marginLeft: 'auto' }}>3</b></div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Cảnh báo</div>
              <div className="banner warn mb-2"><span>⚠</span><span>3 đăng nhập thất bại lặp từ 1 IP</span></div>
              <div className="banner info mb-2"><span>🔄</span><span>Backup incremental thành công lúc 02:00</span></div>
              <div className="banner ok"><span>✓</span><span>SSL renew tự động · còn 87 ngày</span></div>
            </div>
          </div>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD02_Users() {
  const users = [
    { id: 1, code: 'GV-2018-0042', name: 'Nguyễn Tuấn', email: 'nguyen.t@ptit.edu.vn', role: 'GV', dept: 'CNTT', last: '2 phút', status: 'ACTIVE' },
    { id: 2, code: 'BCN-K-CNTT', name: 'Lê Hoàng', email: 'le.h@ptit.edu.vn', role: 'BCN', dept: 'CNTT', last: '14 phút', status: 'ACTIVE' },
    { id: 3, code: 'B23DCCN112', name: 'Phạm Minh Anh', email: 'anhpm.b23@ptit.edu.vn', role: 'SV', dept: 'CNTT', last: '1 giờ', status: 'ACTIVE' },
    { id: 4, code: 'GV-2020-0118', name: 'Trần Vinh', email: 'tran.v@ptit.edu.vn', role: 'GV', dept: 'CNTT', last: '3 giờ', status: 'ACTIVE' },
    { id: 5, code: 'B22DCCN044', name: 'Vũ Hồng Linh', email: 'linhvh.b22@ptit.edu.vn', role: 'SV', dept: 'CNTT', last: '5 giờ', status: 'LOCKED' },
    { id: 6, code: 'GV-2019-0067', name: 'Phạm Hùng', email: 'pham.h@ptit.edu.vn', role: 'GV', dept: 'CNTT', last: '1 ngày', status: 'ACTIVE' },
    { id: 7, code: 'B23DCDT008', name: 'Nguyễn Đức Hải', email: 'haind.b23@ptit.edu.vn', role: 'SV', dept: 'ĐTVT', last: '2 ngày', status: 'INACTIVE' },
  ];
  const roleStyle = { GV: 'blue', BCN: 'purple', SV: 'gray', ADMIN: 'red' };
  return (
    <ScreenWrap label="Quản lý tài khoản" code="AD-02 · GET/POST/PATCH /api/admin/users">
      <AdShell active="/users" url="/users">
        <PageHead
          crumbs={["Người dùng", "Tài khoản"]}
          title="Quản lý tài khoản (1,847)"
          actions={<>
            <button className="btn outline">📥 Import CSV</button>
            <button className="btn outline">📤 Export</button>
            <button className="btn">➕ Tạo tài khoản</button>
          </>}
        />

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 320 }}><span className="ico">🔍</span><input placeholder="Mã, tên, email..." /><span className="kbd">⌘K</span></div>
          <select className="select" style={{ width: 130 }}><option>Mọi role</option><option>GV</option><option>BCN</option><option>SV</option><option>ADMIN</option></select>
          <select className="select" style={{ width: 130 }}><option>Mọi khoa</option><option>CNTT</option><option>ĐTVT</option></select>
          <select className="select" style={{ width: 130 }}><option>Mọi status</option><option>ACTIVE</option><option>LOCKED</option><option>INACTIVE</option></select>
          <div className="grow" />
          <span className="text-xs muted mono">Hiển thị 7 / 1,847</span>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th style={{ width: 30 }}><input type="checkbox" /></th>
                <th className="code" style={{ width: 140 }}>Mã / Username</th>
                <th>Tên</th>
                <th className="code">Email</th>
                <th style={{ width: 80 }}>Role</th>
                <th className="code center" style={{ width: 80 }}>Khoa</th>
                <th className="code" style={{ width: 100 }}>Online</th>
                <th style={{ width: 110 }}>Status</th>
                <th className="right" style={{ width: 110 }}></th>
              </tr>
            </thead>
            <tbody>
              {users.map(u => (
                <tr key={u.id}>
                  <td><input type="checkbox" /></td>
                  <td className="code">{u.code}</td>
                  <td><div className="row gap-2"><div className="avatar sm">{u.name.split(' ').slice(-1)[0][0]}</div><b>{u.name}</b></div></td>
                  <td className="code">{u.email}</td>
                  <td><span className={`pill ${roleStyle[u.role]}`}>{u.role}</span></td>
                  <td className="code center">{u.dept}</td>
                  <td className="code">{u.last}</td>
                  <td>{u.status === 'ACTIVE' ? <span className="pill green dot">ACTIVE</span> : u.status === 'LOCKED' ? <span className="pill red dot">LOCKED</span> : <span className="pill gray dot">INACTIVE</span>}</td>
                  <td className="right">
                    <div className="row-actions">
                      <button className="btn xs outline">✎</button>
                      <button className="btn xs ghost">⋯</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="row between mt-3 text-xs muted mono">
          <span>1,847 records · 264 pages</span>
          <span>‹ 1 2 3 ... 264 ›</span>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD03_CreateUser() {
  return (
    <ScreenWrap label="Tạo tài khoản mới (vd: BCN)" code="AD-02 · POST /api/admin/users + tạo profile theo role">
      <AdShell active="/users" url="/users/new">
        <PageHead
          crumbs={["Tài khoản", "Tạo mới"]}
          title="Tạo tài khoản mới"
          actions={<>
            <button className="btn outline">Hủy</button>
            <button className="btn">💾 Tạo</button>
          </>}
        />

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="col">
            <div className="card">
              <div className="title">Thông tin chung</div>
              <div className="form-grid-2">
                <div className="form-row"><label className="label">Vai trò *</label>
                  <select className="select"><option>BCN — BCN Khoa</option><option>GV — Giảng viên</option><option>SV — Sinh viên</option><option>ADMIN</option></select>
                </div>
                <div className="form-row"><label className="label">Mã / Username *</label>
                  <input className="input mono" defaultValue="BCN-K-DTVT" />
                </div>
                <div className="form-row"><label className="label">Họ và tên *</label>
                  <input className="input" defaultValue="Bùi Quang Thắng" />
                </div>
                <div className="form-row"><label className="label">Email *</label>
                  <input className="input mono" defaultValue="bui.t@ptit.edu.vn" />
                </div>
                <div className="form-row"><label className="label">SĐT</label>
                  <input className="input mono" defaultValue="+84 912 345 678" />
                </div>
                <div className="form-row"><label className="label">Khoa *</label>
                  <select className="select"><option>ĐTVT — Điện tử Viễn thông</option><option>CNTT</option><option>QTKD</option></select>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Phân quyền BCN</div>
              <div className="form-grid-2">
                <div className="form-row"><label className="label">Chức vụ</label>
                  <select className="select"><option>Trưởng khoa</option><option>Phó khoa</option></select>
                </div>
                <div className="form-row"><label className="label">Phạm vi quản lý</label>
                  <input className="input" defaultValue="Khoa ĐTVT (toàn khoa)" />
                </div>
                <div className="form-row"><label className="label">Quyền QĐ1 (đề xuất)</label>
                  <select className="select"><option>✓ Được duyệt</option><option>Chỉ xem</option></select>
                </div>
                <div className="form-row"><label className="label">Quyền QĐ2 (kết quả)</label>
                  <select className="select"><option>✓ Được duyệt</option><option>Chỉ xem</option></select>
                </div>
                <div className="form-row"><label className="label">Quyền QĐ3 (mẫu CN)</label>
                  <select className="select"><option>✓ Được duyệt</option><option>Chỉ xem</option></select>
                </div>
                <div className="form-row"><label className="label">Hiệu lực từ</label>
                  <input className="input mono" defaultValue="04/05/2026" />
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Mật khẩu & Truy cập</div>
              <div className="form-grid-2">
                <div className="form-row"><label className="label">Phương thức</label>
                  <select className="select"><option>Tự sinh + gửi email</option><option>Đặt thủ công</option><option>SSO PTIT only</option></select>
                </div>
                <div className="form-row"><label className="label">Bắt buộc đổi mk lần đầu</label>
                  <select className="select"><option>✓ Có</option><option>Không</option></select>
                </div>
              </div>
              <label className="row gap-2 text-sm mt-2"><input type="checkbox" defaultChecked /> Gửi email kích hoạt sau khi tạo</label>
              <label className="row gap-2 text-sm mt-2"><input type="checkbox" defaultChecked /> Bật 2FA bắt buộc cho role BCN</label>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Preview tài khoản</div>
              <div className="row gap-3 mb-3" style={{ padding: 14, background: 'var(--bg-sunken)', borderRadius: 10 }}>
                <div className="avatar lg">B</div>
                <div>
                  <b>Bùi Quang Thắng</b>
                  <div className="text-xs muted mono mt-1">BCN-K-DTVT</div>
                  <div className="row gap-2 mt-2">
                    <span className="pill purple">BCN</span>
                    <span className="pill">ĐTVT</span>
                  </div>
                </div>
              </div>
              <div className="text-xs muted">Tài khoản sẽ được kích hoạt qua email <b className="mono" style={{ color: 'var(--fg)' }}>bui.t@ptit.edu.vn</b> trong vòng 5 phút.</div>
            </div>

            <div className="card">
              <div className="title">Validate</div>
              <div className="col gap-2 text-sm">
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Mã chưa tồn tại</div>
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Email chưa tồn tại</div>
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Khoa hợp lệ</div>
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Đủ trường bắt buộc</div>
              </div>
            </div>

            <div className="banner info"><span>📨</span><span>Email kích hoạt sẽ gửi từ <b>noreply@ptit.edu.vn</b></span></div>
          </div>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD04_Master() {
  return (
    <ScreenWrap label="Quản lý Khoa / Ngành / Lớp" code="AD-03 · CRUD /api/admin/faculties + /majors + /classes">
      <AdShell active="/master" url="/master">
        <PageHead
          crumbs={["Master data"]}
          title="Khoa / Ngành / Lớp"
          actions={<button className="btn">➕ Thêm khoa</button>}
        />

        <div className="grid-12" style={{ alignItems: 'flex-start' }}>
          <div className="card">
            <div className="title">Cây tổ chức <span className="right text-xs muted mono">12 khoa · 38 ngành · 142 lớp</span></div>
            <div className="search mb-3" style={{ minWidth: 'auto' }}><span className="ico">🔍</span><input placeholder="Tìm khoa, ngành, lớp..." /></div>
            <div className="tree-row l1">▼ 🏛️ Khoa CNTT <span className="badge">412 SV · 24 GV</span></div>
            <div className="tree-row l2">▼ Công nghệ phần mềm <span className="badge">5 lớp</span></div>
            <div className="tree-row l3">D23CN01 · 32 SV</div>
            <div className="tree-row l3">D23CN02 · 31 SV</div>
            <div className="tree-row l3">D23CN03 · 30 SV</div>
            <div className="tree-row l2">▶ Hệ thống thông tin <span className="badge">4 lớp</span></div>
            <div className="tree-row l2">▶ An toàn thông tin <span className="badge">3 lớp</span></div>
            <div className="tree-row l1">▶ 🏛️ Khoa ĐTVT <span className="badge">288 SV · 18 GV</span></div>
            <div className="tree-row l1">▶ 🏛️ Khoa Viễn thông <span className="badge">312 SV · 21 GV</span></div>
            <div className="tree-row l1">▶ 🏛️ Khoa QTKD <span className="badge">198 SV · 14 GV</span></div>
            <div className="tree-row l1">▶ 🏛️ Khoa Đa phương tiện <span className="badge">156 SV · 11 GV</span></div>
            <div className="tree-row l1">▶ 🏛️ Khoa CB1 (Cơ bản) <span className="badge">— · 18 GV</span></div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Khoa CNTT <span className="right"><button className="btn xs outline">✎ Sửa</button></span></div>
              <div className="form-grid-2 text-sm">
                <div><span className="label">Mã khoa</span><b className="mono">CNTT</b></div>
                <div><span className="label">Tên đầy đủ</span><b>Công nghệ Thông tin</b></div>
                <div><span className="label">Trưởng khoa</span><div className="row gap-2 mt-1"><div className="avatar sm">L</div>PGS. Lê Hoàng</div></div>
                <div><span className="label">Email khoa</span><span className="mono">cntt@ptit.edu.vn</span></div>
                <div><span className="label">Số ngành</span><span className="mono">3</span></div>
                <div><span className="label">Số lớp</span><span className="mono">12</span></div>
                <div><span className="label">Số SV</span><span className="mono">412</span></div>
                <div><span className="label">Số GV</span><span className="mono">24</span></div>
              </div>
            </div>

            <div className="card">
              <div className="title">D23CN01 — Lớp đang chọn <span className="right"><button className="btn xs outline">✎ Sửa</button></span></div>
              <div className="form-grid-2 text-sm">
                <div><span className="label">Mã lớp</span><b className="mono">D23CN01</b></div>
                <div><span className="label">Khoá</span><span className="mono">2023-2027</span></div>
                <div><span className="label">Ngành</span>Công nghệ phần mềm</div>
                <div><span className="label">GV chủ nhiệm</span>TS. Nguyễn Tuấn</div>
                <div><span className="label">Số SV</span><span className="mono">32</span></div>
                <div><span className="label">SV active</span><span className="mono">31</span></div>
              </div>
              <div className="divider" />
              <button className="btn outline sm" style={{ width: '100%', justifyContent: 'center' }}>👥 Xem 32 sinh viên</button>
            </div>
          </div>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD05_Configs() {
  const configs = [
    { key: 'contest.max_concurrent_per_dept', desc: 'Số CT đồng thời tối đa của 1 khoa', val: '5', type: 'int' },
    { key: 'approval.qd1.sla_hours', desc: 'SLA xét QĐ1 (giờ)', val: '48', type: 'int' },
    { key: 'approval.qd2.sla_hours', desc: 'SLA xét QĐ2 (giờ)', val: '72', type: 'int' },
    { key: 'mail.smtp.host', desc: 'SMTP server', val: 'smtp.ptit.edu.vn', type: 'string' },
    { key: 'mail.smtp.port', desc: 'SMTP port', val: '587', type: 'int' },
    { key: 'cert.qr.verify_url', desc: 'Base URL xác thực CN', val: 'https://contest.ptit.edu.vn/v', type: 'string' },
    { key: 'auth.session_timeout_min', desc: 'Hết phiên (phút)', val: '60', type: 'int' },
    { key: 'auth.failed_login_lockout', desc: 'Khoá sau N lần fail', val: '5', type: 'int' },
    { key: 'storage.max_upload_mb', desc: 'Upload tối đa (MB)', val: '50', type: 'int' },
    { key: 'feature.blind_judging', desc: 'Bật chấm ẩn danh', val: 'true', type: 'bool' },
    { key: 'feature.public_leaderboard', desc: 'Hiện BXH công khai', val: 'true', type: 'bool' },
    { key: 'system.maintenance_mode', desc: 'Chế độ bảo trì', val: 'false', type: 'bool' },
  ];
  return (
    <ScreenWrap label="Cấu hình hệ thống" code="AD-04 · GET/PATCH /api/admin/configs/{key}">
      <AdShell active="/configs" url="/configs">
        <PageHead
          crumbs={["Hệ thống", "Cấu hình"]}
          title="Cấu hình hệ thống (system_configs)"
          actions={<>
            <button className="btn outline">📥 Export YAML</button>
            <button className="btn">➕ Thêm config</button>
          </>}
        />

        <div className="banner warn mb-3"><span>⚠</span><span>Mọi thay đổi sẽ được audit. <b>Maintenance mode</b> sẽ đăng xuất toàn hệ thống.</span></div>

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 320 }}><span className="ico">🔍</span><input placeholder="Tìm theo key (vd: mail.*)..." /></div>
          <select className="select" style={{ width: 130 }}><option>Mọi nhóm</option><option>contest.*</option><option>approval.*</option><option>mail.*</option><option>auth.*</option><option>feature.*</option></select>
          <select className="select" style={{ width: 110 }}><option>Mọi type</option><option>int</option><option>string</option><option>bool</option></select>
        </div>

        <div className="card" style={{ padding: 0 }}>
          <div className="config-row" style={{ background: 'var(--bg-sunken)', fontSize: 11, color: 'var(--fg-muted)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 600 }}>
            <span>Key</span><span>Mô tả</span><span>Giá trị</span><span>Type</span>
          </div>
          {configs.map((c, i) => (
            <div className="config-row" key={i}>
              <div>
                <div className="key">{c.key}</div>
                <div className="desc">{c.desc}</div>
              </div>
              <div></div>
              <div className="v">{c.val}</div>
              <div className="row between">
                <span className="pill" style={{ fontSize: 9 }}>{c.type}</span>
                <button className="btn xs ghost">✎</button>
              </div>
            </div>
          ))}
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD06_Audit() {
  const logs = [
    { ts: '11:42:18.21', lvl: 'INFO', who: 'gv.tuan@ptit', msg: 'contest.create', arg: '"Hackathon 2026"', id: 'id=#42 ip=10.20.4.11' },
    { ts: '11:38:02.88', lvl: 'OK', who: 'bcn.hoang@ptit', msg: 'approval.decide', arg: 'APPROVE', id: 'approval_id=#7' },
    { ts: '11:32:55.04', lvl: 'OK', who: 'sv.B23DCCN112', msg: 'contest.register', arg: '"Olympic 2026"', id: 'entry=#2087' },
    { ts: '11:28:14.55', lvl: 'WARN', who: 'system', msg: 'mail.queue.backlog', arg: '418 pending', id: 'svc=mailer' },
    { ts: '11:24:31.10', lvl: 'OK', who: 'gv.vinh@ptit', msg: 'judge.score.submit', arg: 'entry=#87 score=80', id: 'round=r-1' },
    { ts: '11:21:08.92', lvl: 'INFO', who: 'admin', msg: 'user.create', arg: 'role=BCN dept=DTVT', id: 'user_id=#1848' },
    { ts: '11:17:42.31', lvl: 'ERR', who: 'sv.B22DCCN044', msg: 'auth.login.fail', arg: 'attempt=3', id: 'ip=10.20.4.18 ua=iOS' },
    { ts: '11:12:29.78', lvl: 'OK', who: 'cron', msg: 'backup.incremental', arg: '2.4 GB', id: 'elapsed=14s' },
    { ts: '11:08:11.40', lvl: 'OK', who: 'gv.thanh@ptit', msg: 'contest.update', arg: '"Web Design 2026"', id: 'fields=[time]' },
    { ts: '11:04:52.18', lvl: 'INFO', who: 'system', msg: 'cert.batch.issue', arg: '218 certs', id: 'contest=#OLY-2025' },
    { ts: '11:01:05.62', lvl: 'OK', who: 'admin', msg: 'config.update', arg: 'approval.qd1.sla_hours: 24 → 48', id: 'config_id=#7' },
    { ts: '10:58:33.04', lvl: 'WARN', who: 'sv.B23DCCN081', msg: 'auth.login.fail', arg: 'attempt=1', id: 'ip=14.232.99.4' },
    { ts: '10:54:12.81', lvl: 'OK', who: 'gv.hung@ptit', msg: 'approval.submit', arg: 'CONTEST_PROPOSAL revision=3', id: 'approval_id=#5' },
    { ts: '10:48:55.20', lvl: 'INFO', who: 'system', msg: 'session.expire', arg: '47 sessions', id: 'reason=timeout' },
    { ts: '10:45:11.07', lvl: 'OK', who: 'sv.B22DCCN199', msg: 'cert.download', arg: 'cert_id=CN-2025-0044', id: 'format=pdf' },
  ];
  return (
    <ScreenWrap label="Audit log" code="AD-06 · GET /api/admin/audit-logs">
      <AdShell active="/audit" url="/audit">
        <PageHead
          crumbs={["Hệ thống", "Audit log"]}
          title="Audit log toàn hệ thống"
          actions={<>
            <button className="btn outline">📥 Export .xlsx</button>
            <button className="btn outline">⚠️ Anomaly report</button>
          </>}
        />

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 320 }}><span className="ico">🔍</span><input placeholder="Tìm theo user, msg, IP..." /></div>
          <select className="select" style={{ width: 110 }}><option>Mọi level</option><option>OK</option><option>INFO</option><option>WARN</option><option>ERR</option></select>
          <select className="select" style={{ width: 130 }}><option>Mọi action</option><option>auth.*</option><option>contest.*</option><option>approval.*</option><option>config.*</option></select>
          <input className="input mono" defaultValue="04/05/2026" style={{ width: 130 }} />
          <span className="text-xs muted">→</span>
          <input className="input mono" defaultValue="04/05/2026" style={{ width: 130 }} />
          <div className="grow" />
          <span className="text-xs muted mono">15 / 28,412 entries</span>
        </div>

        <div className="audit-log">
          <div className="row" style={{ borderBottom: '1px solid oklch(0.250 0.010 60)', paddingBottom: 6, marginBottom: 6, color: 'oklch(0.560 0.012 60)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 700 }}>
            <span>TIMESTAMP</span><span>LEVEL</span><span>USER</span><span>EVENT</span>
          </div>
          {logs.map((l, i) => (
            <div className="row" key={i}>
              <span className="ts">{l.ts}</span>
              <span className={`lvl ${l.lvl.toLowerCase()}`}>{l.lvl}</span>
              <span className="who">{l.who}</span>
              <span className="msg">{l.msg} <span className="arg">{l.arg}</span> <span className="id">{l.id}</span></span>
            </div>
          ))}
        </div>

        <div className="row between mt-3 text-xs muted mono">
          <span>Realtime stream · 2-3 entries/giây</span>
          <span>‹ 1 2 ... 1,894 ›</span>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AD07_Stats() {
  return (
    <ScreenWrap label="Thống kê toàn hệ thống" code="AD-05 · GET /api/admin/reports/system-summary">
      <AdShell active="/stats" url="/stats">
        <PageHead
          crumbs={["Báo cáo"]}
          title="Thống kê toàn hệ thống — 2026"
          actions={<>
            <select className="select" style={{ width: 110 }}><option>2026</option><option>2025</option></select>
            <button className="btn outline">📥 Export .xlsx</button>
          </>}
        />

        <div className="stats">
          <div className="stat"><div className="label-mono">Tổng cuộc thi</div><div className="num">42</div><div className="delta">▲ +12 vs 2025</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">SV tham gia</div><div className="num">2,847</div><div className="delta">▲ +18.4%</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">CN cấp ra</div><div className="num">1,124</div><div className="delta">▲ +204</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Khoa active</div><div className="num">9 <span style={{ fontSize: 14, color: 'var(--fg-muted)' }}>/ 12</span></div><div className="delta">▲ +1</div><div className="accent-bar" /></div>
        </div>

        <div className="grid-21" style={{ alignItems: 'stretch' }}>
          <div className="card">
            <div className="title">Cuộc thi theo khoa <span className="right text-xs muted">2026</span></div>
            <div className="col gap-3">
              {[
                ['CNTT', 18, 'var(--accent)'],
                ['ĐTVT', 8, 'oklch(0.6 0.15 250)'],
                ['Viễn thông', 6, 'oklch(0.7 0.15 80)'],
                ['QTKD', 5, 'oklch(0.5 0.18 290)'],
                ['Đa phương tiện', 3, 'oklch(0.65 0.13 150)'],
                ['CB1', 2, 'oklch(0.55 0.12 30)'],
              ].map(([n, v, c], i) => (
                <div key={i}>
                  <div className="row between text-sm mb-2"><b>{n}</b><span className="mono">{v} CT</span></div>
                  <div style={{ height: 8, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${v * 5}%`, height: '100%', background: c, borderRadius: 4 }} />
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="col">
            <div className="card">
              <div className="title">Tăng trưởng SV (5 năm)</div>
              <div className="bar-chart" style={{ height: 160 }}>
                {[
                  { y: '2022', v: 1240 }, { y: '2023', v: 1480 }, { y: '2024', v: 1620 },
                  { y: '2025', v: 1820 }, { y: '2026', v: 2847, hl: true },
                ].map((b, i) => (
                  <div className="bar" key={i}>
                    <div className="v" style={{ height: `${b.v / 35}%`, background: b.hl ? 'var(--accent)' : 'var(--accent-soft)' }} />
                    {b.hl && <div className="top">{b.v}</div>}
                    <div className="lbl">{b.y}</div>
                  </div>
                ))}
              </div>
              <div className="text-xs muted mt-4 mono">CAGR: <b style={{ color: 'var(--ok)' }}>+23%/năm</b></div>
            </div>
            <div className="card">
              <div className="title">RBAC hoạt động</div>
              <div className="text-sm">
                <div className="config-row" style={{ display: 'grid', gridTemplateColumns: '1fr auto', padding: '8px 0' }}><span>SV actions / ngày</span><span className="mono">8,420</span></div>
                <div className="config-row" style={{ display: 'grid', gridTemplateColumns: '1fr auto', padding: '8px 0' }}><span>GV actions / ngày</span><span className="mono">912</span></div>
                <div className="config-row" style={{ display: 'grid', gridTemplateColumns: '1fr auto', padding: '8px 0' }}><span>BCN actions / ngày</span><span className="mono">142</span></div>
                <div className="config-row" style={{ display: 'grid', gridTemplateColumns: '1fr auto', padding: '8px 0' }}><span>Admin actions / ngày</span><span className="mono">28</span></div>
                <div className="config-row" style={{ display: 'grid', gridTemplateColumns: '1fr auto', padding: '8px 0', borderBottom: 0 }}><b>Tổng</b><b className="mono" style={{ color: 'var(--accent)' }}>9,502</b></div>
              </div>
            </div>
          </div>
        </div>
      </AdShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function AdminApp() {
  return (
    <>
      <AD01_Dashboard />
      <AD02_Users />
      <AD03_CreateUser />
      <AD04_Master />
      <AD05_Configs />
      <AD06_Audit />
      <AD07_Stats />
    </>
  );
}

Object.assign(window, { AdminApp });
