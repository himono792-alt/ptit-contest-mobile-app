/* global React */
const { useState, useMemo } = React;

/* ============================================================
   SHARED CHROME — Browser, Sidebar, ScreenWrap
   ============================================================ */

function Browser({ url, children }) {
  return (
    <div className="browser">
      <div className="browser-bar">
        <div className="dots"><div className="dot" /><div className="dot" /><div className="dot" /></div>
        <div className="url">contest.ptit.edu.vn{url}</div>
        <div className="actions"><span>⤓</span><span>⋯</span></div>
      </div>
      <div className="layout">{children}</div>
    </div>
  );
}

function Sidebar({ items, active, role, who }) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <div className="logo">P</div>
        <div>
          <b>PTIT Contest</b>
          <div className="role">{role}</div>
        </div>
      </div>
      <nav>
        {items.map((it, i) => it.section ? (
          <div className="section" key={i}>{it.section}</div>
        ) : (
          <div className={`item ${active === it.href ? 'active' : ''}`} key={i}>
            <span className="ico">{it.ico}</span>
            <span>{it.label}</span>
            {it.badge && <span className={`badge-num ${it.badgeGray ? 'gray' : ''}`}>{it.badge}</span>}
          </div>
        ))}
      </nav>
      <div className="footer">
        <div className="avatar">{who.initials}</div>
        <div className="who"><b>{who.name}</b><span>{who.sub}</span></div>
        <span className="icon-btn">⏻</span>
      </div>
    </aside>
  );
}

function ScreenWrap({ label, code, children }) {
  return (
    <div className="screen-wrap">
      {children}
      <div className="screen-label">{label}<span className="code">{code}</span></div>
    </div>
  );
}

function PageHead({ crumbs, title, badge, actions }) {
  return (
    <div className="page-head">
      <div>
        <div className="crumbs">
          {crumbs.map((c, i) => (
            <React.Fragment key={i}>
              {i > 0 && <span className="sep">›</span>}
              <span>{c}</span>
            </React.Fragment>
          ))}
        </div>
        <h2>{title}{badge}</h2>
      </div>
      <div className="actions">{actions}</div>
    </div>
  );
}

/* GV chrome */
const GVWHO = { initials: 'NT', name: 'TS. Nguyễn Tuấn', sub: 'Khoa CNTT' };
function GVShell({ active, url, children }) {
  return (
    <Browser url={url}>
      <Sidebar items={window.WEB.NAV_GV} active={active} role="Giảng viên / BTC" who={GVWHO} />
      <div className="main">{children}</div>
    </Browser>
  );
}

/* ============================================================
   SCREEN 1 — LOGIN (chung 3 role)
   ============================================================ */
function GV01_Login() {
  return (
    <ScreenWrap label="Đăng nhập (chung GV / BCN / Admin)" code="GV-01 / BCN-01 / AD-01 · POST /api/auth/login">
      <Browser url="/login">
        <div className="login-split" style={{ flex: 1 }}>
          <div className="login-hero">
            <div className="brand-row">
              <div className="mark">P</div>
              <span>PTIT Contest</span>
            </div>
            <div>
              <h1>Hệ thống quản lý<br />cuộc thi của<br /><span style={{ color: 'oklch(0.95 0.05 19)' }}>Học viện CNBCVT</span></h1>
              <p>Đăng nhập bằng tài khoản nội bộ. Hệ thống phân quyền theo vai trò: Giảng viên / BTC, Ban Chủ nhiệm khoa, Ban Quản trị.</p>
              <div className="meta-grid">
                <div className="meta-item"><div className="num">1,847</div><div className="lbl">Tài khoản</div></div>
                <div className="meta-item"><div className="num">42</div><div className="lbl">Cuộc thi 2026</div></div>
                <div className="meta-item"><div className="num">12</div><div className="lbl">Khoa</div></div>
                <div className="meta-item"><div className="num">99.9%</div><div className="lbl">Uptime</div></div>
              </div>
            </div>
            <div className="footer-mark">© 2026 PTIT · v1.0.0 · build #2026.05.04</div>
          </div>
          <div className="login-form-wrap">
            <h2>Đăng nhập</h2>
            <p className="sub">Sử dụng tài khoản PTIT để truy cập</p>
            <div className="login-form">
              <div className="role-tabs">
                <div className="role active">Giảng viên / BTC</div>
                <div className="role">BCN khoa</div>
                <div className="role">Quản trị</div>
              </div>
              <div className="form-row">
                <label className="label">Mã CB / Email</label>
                <input className="input" defaultValue="GV-2018-0042 hoặc nguyen.t@ptit.edu.vn" />
              </div>
              <div className="form-row">
                <label className="label">Mật khẩu</label>
                <input type="password" className="input" defaultValue="••••••••••" />
              </div>
              <div className="row between mb-3">
                <label className="row gap-2 text-sm" style={{ color: 'var(--fg-muted)' }}>
                  <input type="checkbox" defaultChecked /> Ghi nhớ
                </label>
                <a className="text-sm" style={{ color: 'var(--accent)', fontWeight: 600 }}>Quên mật khẩu?</a>
              </div>
              <button className="btn lg" style={{ width: '100%', justifyContent: 'center' }}>Đăng nhập <span className="kbd">⏎</span></button>
              <div className="divider mt-4"></div>
              <button className="btn outline" style={{ width: '100%', justifyContent: 'center' }}>🏛️  Đăng nhập SSO PTIT</button>
              <p className="text-xs muted mt-3" style={{ textAlign: 'center' }}>Sinh viên vui lòng dùng app mobile PTIT Contest.</p>
            </div>
          </div>
        </div>
      </Browser>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 2 — DASHBOARD
   ============================================================ */
function GV02_Dashboard() {
  return (
    <ScreenWrap label="Dashboard tổng quan" code="GV (sau login)">
      <GVShell active="/dashboard" url="/dashboard">
        <PageHead
          crumbs={["Trang chủ"]}
          title="Dashboard"
          actions={<>
            <div className="muted text-sm mono">📅 04/05/2026 · Tuần 18</div>
            <button className="btn">➕ Tạo cuộc thi</button>
          </>}
        />

        <div className="stats">
          <div className="stat">
            <div className="label-mono">CT đang diễn ra</div>
            <div className="num">3</div>
            <div className="delta">▲ 1 mới tuần này</div>
            <div className="accent-bar" />
          </div>
          <div className="stat">
            <div className="label-mono">Bài chờ chấm</div>
            <div className="num">12</div>
            <div className="delta down">▼ 8 đã chấm hôm qua</div>
            <div className="accent-bar" />
          </div>
          <div className="stat">
            <div className="label-mono">Đăng ký pending</div>
            <div className="num">47</div>
            <div className="delta">▲ +12 trong 24h</div>
            <div className="accent-bar" />
          </div>
          <div className="stat">
            <div className="label-mono">Sinh viên tham gia</div>
            <div className="num">312</div>
            <div className="delta flat">— ổn định</div>
            <div className="accent-bar" />
          </div>
        </div>

        <div className="grid-21" style={{ alignItems: 'stretch' }}>
          <div className="card">
            <div className="title">Cuộc thi của tôi <span className="right"><a style={{ color: 'var(--accent)' }}>Xem tất cả →</a></span></div>
            <div className="contest-grid">
              <div className="contest-card ongoing">
                <div className="row between">
                  <span className="pill green dot">ONGOING</span>
                  <span className="text-xs muted mono">#OLY-2026</span>
                </div>
                <div className="title" style={{ margin: 0 }}>Olympic Tin học 2026</div>
                <div className="sub">Vòng loại · 03/05 → 10/05</div>
                <div className="progress"><div style={{ width: '62%' }} /></div>
                <div className="meta-row">
                  <span><b>187</b> SV</span>
                  <span><b>12</b> chờ chấm</span>
                  <span><b>62%</b> tiến độ</span>
                </div>
              </div>
              <div className="contest-card judging">
                <div className="row between">
                  <span className="pill blue dot">JUDGING</span>
                  <span className="text-xs muted mono">#HACK-2026</span>
                </div>
                <div className="title" style={{ margin: 0 }}>Hackathon Mùa hè 2026</div>
                <div className="sub">Chung kết · 28/04 → 02/05</div>
                <div className="progress"><div style={{ width: '88%' }} /></div>
                <div className="meta-row">
                  <span><b>40</b> đội</span>
                  <span><b>0</b> chờ chấm</span>
                  <span><b>88%</b> tiến độ</span>
                </div>
              </div>
              <div className="contest-card draft">
                <div className="row between">
                  <span className="pill gray dot">DRAFT</span>
                  <span className="text-xs muted mono">#CPP-2026</span>
                </div>
                <div className="title" style={{ margin: 0 }}>Cuộc thi LT C++ 2026</div>
                <div className="sub">Đợi BCN duyệt · Lần 3 / PR</div>
                <div className="progress"><div style={{ width: '15%' }} /></div>
                <div className="meta-row">
                  <span><b>0</b> SV</span>
                  <span className="pill yellow" style={{ padding: '0 6px' }}>PR_REQ</span>
                </div>
              </div>
            </div>

            <div className="divider" />
            <div className="title" style={{ marginTop: 4 }}>Hoạt động gần đây</div>
            <div className="log" style={{ background: 'var(--bg-sunken)', color: 'var(--fg)', border: '1px solid var(--border)' }}>
              <div className="row"><span className="ts" style={{ color: 'var(--fg-faint)' }}>10:42</span> <span className="lvl ok" style={{ color: 'var(--ok)' }}>✓</span> <span className="msg" style={{ color: 'var(--fg)' }}>Đăng ký <span className="arg" style={{ color: 'var(--accent)' }}>SV B23DCCN112</span> đã được duyệt vào Olympic Tin học 2026</span></div>
              <div className="row"><span className="ts" style={{ color: 'var(--fg-faint)' }}>09:18</span> <span className="lvl info" style={{ color: 'var(--info)' }}>▶</span> <span className="msg" style={{ color: 'var(--fg)' }}>BCN duyệt <span className="arg" style={{ color: 'var(--accent)' }}>QĐ1</span> cho Hackathon Mùa hè 2026</span></div>
              <div className="row"><span className="ts" style={{ color: 'var(--fg-faint)' }}>Hôm qua</span> <span className="lvl warn" style={{ color: 'var(--warn)' }}>!</span> <span className="msg" style={{ color: 'var(--fg)' }}>BCN yêu cầu chỉnh sửa đề xuất <span className="arg" style={{ color: 'var(--accent)' }}>Cuộc thi LT C++ 2026</span> (lần 3)</span></div>
              <div className="row"><span className="ts" style={{ color: 'var(--fg-faint)' }}>02/05</span> <span className="lvl ok" style={{ color: 'var(--ok)' }}>✓</span> <span className="msg" style={{ color: 'var(--fg)' }}>Hoàn tất chấm 8 bài Olympic Tin học 2026 / Vòng loại</span></div>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Lịch sắp tới</div>
              <div className="schedule-row">
                <div className="when"><b>05/05</b>09:00</div>
                <div className="body">
                  <b>Họp BTC Olympic Tin học</b>
                  <div className="meta">P.305 nhà A1 · 8 người</div>
                </div>
              </div>
              <div className="schedule-row">
                <div className="when"><b>07/05</b>23:59</div>
                <div className="body">
                  <b>Hạn chấm vòng loại Olympic</b>
                  <div className="meta">12 bài còn lại</div>
                </div>
              </div>
              <div className="schedule-row">
                <div className="when"><b>10/05</b>17:00</div>
                <div className="body">
                  <b>Chung kết Olympic Tin học</b>
                  <div className="meta">Hội trường A1 · 50 SV</div>
                </div>
              </div>
              <div className="schedule-row">
                <div className="when"><b>15/05</b>—</div>
                <div className="body">
                  <b>Submit kết quả Hackathon (QĐ2)</b>
                  <div className="meta">Cần BCN ký duyệt</div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Trạng thái duyệt</div>
              <div className="row gap-3 mb-3">
                <div className="donut">
                  <svg viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--bg-sunken)" strokeWidth="14" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--ok)" strokeWidth="14" strokeDasharray="170 240" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--warn)" strokeWidth="14" strokeDasharray="40 240" strokeDashoffset="-170" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--err)" strokeWidth="14" strokeDasharray="20 240" strokeDashoffset="-210" strokeLinecap="round" />
                  </svg>
                  <div className="label"><div><div className="num">5</div><div className="lbl">Đề xuất</div></div></div>
                </div>
                <div style={{ flex: 1, fontSize: 12, lineHeight: 2 }}>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--ok)' }} /> Đã duyệt <b className="mono" style={{ marginLeft: 'auto' }}>3</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--warn)' }} /> Pending <b className="mono" style={{ marginLeft: 'auto' }}>1</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--err)' }} /> PR_REQ <b className="mono" style={{ marginLeft: 'auto' }}>1</b></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 3 — CUỘC THI CỦA TÔI
   ============================================================ */
function GV03_Contests() {
  const data = [
    { code: 'OLY-2026', name: 'Olympic Tin học PTIT 2026', status: 'ONGOING', sv: 187, rounds: '2/3', from: '03/05/2026', to: '20/05/2026' },
    { code: 'HACK-2026', name: 'Hackathon Mùa hè 2026', status: 'JUDGING', sv: 40, rounds: '3/3', from: '20/04/2026', to: '02/05/2026' },
    { code: 'CPP-2026', name: 'Cuộc thi Lập trình C++ 2026', status: 'PR_REQ', sv: 0, rounds: '0/2', from: '15/05/2026', to: '30/05/2026' },
    { code: 'WEB-2026', name: 'Web Design Challenge 2026', status: 'REG_OPEN', sv: 32, rounds: '0/1', from: '10/05/2026', to: '25/05/2026' },
    { code: 'OLY-2025', name: 'Olympic Tin học 2025', status: 'COMPLETED', sv: 245, rounds: '3/3', from: '03/05/2025', to: '25/05/2025' },
    { code: 'AI-2025', name: 'AI Challenge 2025', status: 'COMPLETED', sv: 88, rounds: '2/2', from: '10/03/2025', to: '30/03/2025' },
  ];
  const statusMap = {
    ONGOING: ['green', '🟢 ONGOING'],
    JUDGING: ['blue', '⚖️ JUDGING'],
    PR_REQ: ['yellow', '⚠ PR_REQ'],
    REG_OPEN: ['blue', '📝 REG_OPEN'],
    COMPLETED: ['gray', '✓ COMPLETED'],
  };
  return (
    <ScreenWrap label="Danh sách cuộc thi của GV" code="GV-02 · GET /api/contests?created_by=me">
      <GVShell active="/contests" url="/contests">
        <PageHead
          crumbs={["Cuộc thi"]}
          title="Cuộc thi của tôi"
          actions={<button className="btn">➕ Tạo cuộc thi mới</button>}
        />

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 320 }}>
            <span className="ico">🔍</span>
            <input placeholder="Tìm theo tên, mã cuộc thi..." />
            <span className="kbd">⌘K</span>
          </div>
          <select className="select" style={{ width: 160 }}>
            <option>Tất cả trạng thái</option>
            <option>Đang diễn ra</option>
            <option>Pending</option>
            <option>Đã kết thúc</option>
          </select>
          <select className="select" style={{ width: 140 }}>
            <option>Năm 2026</option>
            <option>Năm 2025</option>
          </select>
          <div className="grow"></div>
          <button className="btn outline">📥 Export</button>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th className="code" style={{ width: 110 }}>MÃ</th>
                <th>Tên cuộc thi</th>
                <th style={{ width: 130 }}>Trạng thái</th>
                <th className="num right" style={{ width: 70 }}>SV</th>
                <th className="code center" style={{ width: 80 }}>Vòng</th>
                <th className="code" style={{ width: 200 }}>Thời gian</th>
                <th className="right" style={{ width: 110 }}></th>
              </tr>
            </thead>
            <tbody>
              {data.map((r, i) => (
                <tr key={i}>
                  <td className="code">#{r.code}</td>
                  <td><b>{r.name}</b></td>
                  <td><span className={`pill ${statusMap[r.status][0]}`}>{statusMap[r.status][1]}</span></td>
                  <td className="num right"><b>{r.sv}</b></td>
                  <td className="code center">{r.rounds}</td>
                  <td className="code">{r.from} → {r.to}</td>
                  <td className="right">
                    <div className="row-actions">
                      <button className="btn xs outline">Xem</button>
                      <button className="btn xs ghost">⋯</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="row between mt-3 text-xs muted">
          <span>Hiển thị 6 / 6 cuộc thi</span>
          <span className="mono">‹ 1 ›</span>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 4 — TẠO CUỘC THI
   ============================================================ */
function GV04_Create() {
  return (
    <ScreenWrap label="Tạo cuộc thi mới" code="GV-02 · POST /api/contests + /rounds + /submit-for-approval">
      <GVShell active="/contests/new" url="/contests/new">
        <PageHead
          crumbs={["Cuộc thi", "Tạo mới"]}
          title="Tạo cuộc thi mới"
          actions={<>
            <button className="btn outline">💾 Lưu nháp</button>
            <button className="btn">📤 Gửi BCN duyệt (QĐ1)</button>
          </>}
        />

        <div className="wizard-steps">
          <div className="step done"><div className="num">✓</div>Thông tin chung</div>
          <div className="conn done" />
          <div className="step active"><div className="num">2</div>Vòng thi & Thể lệ</div>
          <div className="conn" />
          <div className="step"><div className="num">3</div>Giải thưởng</div>
          <div className="conn" />
          <div className="step"><div className="num">4</div>Xác nhận & Gửi duyệt</div>
        </div>

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="col">
            <div className="card">
              <div className="title">Thông tin chung</div>
              <div className="grid-2">
                <div className="form-row">
                  <label className="label">Tên cuộc thi *</label>
                  <input className="input" defaultValue="Cuộc thi Lập trình C++ 2026" />
                </div>
                <div className="form-row">
                  <label className="label">Mã cuộc thi *</label>
                  <input className="input mono" defaultValue="CPP-2026" />
                </div>
                <div className="form-row">
                  <label className="label">Khoa chủ trì</label>
                  <select className="select"><option>Khoa CNTT</option></select>
                </div>
                <div className="form-row">
                  <label className="label">Loại</label>
                  <select className="select"><option>Cấp khoa</option><option>Cấp trường</option><option>Cấp quốc gia</option></select>
                </div>
                <div className="form-row">
                  <label className="label">Thời gian đăng ký</label>
                  <div className="row gap-2">
                    <input className="input mono" defaultValue="01/05/2026" />
                    <span className="muted">→</span>
                    <input className="input mono" defaultValue="14/05/2026" />
                  </div>
                </div>
                <div className="form-row">
                  <label className="label">Số SV tối đa</label>
                  <input className="input mono" defaultValue="200" />
                </div>
              </div>
              <div className="form-row">
                <label className="label">Mô tả ngắn</label>
                <textarea className="textarea" rows={2} defaultValue="Cuộc thi lập trình C++ dành cho SV năm 2-4 Khoa CNTT. Gồm 2 vòng: thi viết code và phỏng vấn." />
              </div>
            </div>

            <div className="card">
              <div className="title">Vòng thi (2)<button className="btn xs outline" style={{ position: 'absolute', right: 18, top: 14 }}>➕ Thêm vòng</button></div>

              <div className="round-card">
                <div className="head">
                  <div>
                    <div className="row gap-2"><span className="pill solid">Vòng 1</span><b>Thi viết code (online)</b></div>
                    <div className="text-xs muted mt-1 mono">round_id: r-1 · type=ONLINE_CODE</div>
                  </div>
                  <div className="row gap-2"><button className="btn xs ghost">✎</button><button className="btn xs ghost">🗑</button></div>
                </div>
                <div className="grid-3">
                  <div><span className="text-xs muted">Bắt đầu</span><div className="mono">15/05 09:00</div></div>
                  <div><span className="text-xs muted">Kết thúc</span><div className="mono">15/05 12:00</div></div>
                  <div><span className="text-xs muted">Trọng số</span><div className="mono">60%</div></div>
                </div>
              </div>

              <div className="round-card">
                <div className="head">
                  <div>
                    <div className="row gap-2"><span className="pill solid">Vòng 2</span><b>Phỏng vấn (offline)</b></div>
                    <div className="text-xs muted mt-1 mono">round_id: r-2 · type=INTERVIEW</div>
                  </div>
                  <div className="row gap-2"><button className="btn xs ghost">✎</button><button className="btn xs ghost">🗑</button></div>
                </div>
                <div className="grid-3">
                  <div><span className="text-xs muted">Bắt đầu</span><div className="mono">22/05 13:30</div></div>
                  <div><span className="text-xs muted">Kết thúc</span><div className="mono">22/05 17:30</div></div>
                  <div><span className="text-xs muted">Trọng số</span><div className="mono">40%</div></div>
                </div>
              </div>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Tài liệu đính kèm</div>
              <div className="col gap-2 text-sm">
                <div className="row between" style={{ padding: '8px 10px', background: 'var(--bg-sunken)', borderRadius: 8 }}>
                  <span>📄 The_le_CPP2026.pdf</span>
                  <span className="text-xs muted mono">142 KB</span>
                </div>
                <div className="row between" style={{ padding: '8px 10px', background: 'var(--bg-sunken)', borderRadius: 8 }}>
                  <span>📊 Bang_diem_mau.xlsx</span>
                  <span className="text-xs muted mono">28 KB</span>
                </div>
                <button className="btn outline sm" style={{ justifyContent: 'center' }}>📎 Đính kèm thêm</button>
              </div>
            </div>

            <div className="card">
              <div className="title">Validate</div>
              <div className="col gap-2 text-sm">
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Tên cuộc thi (≥10 ký tự)</div>
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Mã không trùng</div>
                <div className="row gap-2"><span style={{ color: 'var(--ok)' }}>✓</span> Có ≥1 vòng thi</div>
                <div className="row gap-2"><span style={{ color: 'var(--warn)' }}>!</span> <span className="muted">Trọng số 2 vòng = 100%</span></div>
                <div className="row gap-2"><span style={{ color: 'var(--fg-faint)' }}>○</span> <span className="muted">Chưa khai báo giải thưởng</span></div>
              </div>
            </div>

            <div className="banner info">
              <span style={{ fontSize: 16 }}>ℹ️</span>
              <span>Sau khi gửi duyệt, đề xuất sẽ chờ <b>BCN khoa</b> ký <b>QĐ1</b> trước khi mở đăng ký.</span>
            </div>
          </div>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 5 — DETAIL CONTEST · TAB ĐĂNG KÝ
   ============================================================ */
function GV05_ContestDetail() {
  const entries = [
    { id: 'B23DCCN112', name: 'Phạm Minh Anh', class: 'D23CN02', when: '02/05 14:22', status: 'PENDING' },
    { id: 'B23DCCN056', name: 'Trần Quốc Bảo', class: 'D23CN01', when: '02/05 13:11', status: 'PENDING' },
    { id: 'B22DCCN199', name: 'Nguyễn Thu Hà', class: 'D22CN03', when: '02/05 12:08', status: 'APPROVED' },
    { id: 'B23DCCN081', name: 'Lê Văn Dũng', class: 'D23CN04', when: '01/05 22:54', status: 'PENDING' },
    { id: 'B22DCCN044', name: 'Vũ Hồng Linh', class: 'D22CN02', when: '01/05 19:36', status: 'APPROVED' },
    { id: 'B23DCCN203', name: 'Đỗ Khánh Mai', class: 'D23CN03', when: '01/05 18:02', status: 'REJECTED' },
    { id: 'B22DCCN012', name: 'Hoàng Thanh Nga', class: 'D22CN01', when: '01/05 16:14', status: 'APPROVED' },
  ];
  return (
    <ScreenWrap label="Quản lý đăng ký SV (tab “Đăng ký”)" code="GV-03 · GET/PATCH /api/contests/{id}/entries">
      <GVShell active="/contests" url="/contests/oly-2026">
        <PageHead
          crumbs={["Cuộc thi", "Olympic Tin học 2026"]}
          title={<>Olympic Tin học PTIT 2026 <span className="pill green dot">REG_OPEN</span></>}
          actions={<>
            <button className="btn outline">📥 Export DSĐK</button>
            <button className="btn">⚙️ Cấu hình</button>
          </>}
        />

        <div className="tabs">
          <div className="tab">📋 Tổng quan</div>
          <div className="tab active">👥 Đăng ký <span className="count">47</span></div>
          <div className="tab">⚖️ Chấm bài <span className="count">12</span></div>
          <div className="tab">🏆 Kết quả</div>
          <div className="tab">📜 Chứng nhận</div>
          <div className="tab">⚙️ Cấu hình</div>
        </div>

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 280 }}><span className="ico">🔍</span><input placeholder="Mã SV, tên, lớp..." /></div>
          <select className="select" style={{ width: 140 }}><option>Tất cả status</option><option>PENDING</option><option>APPROVED</option><option>REJECTED</option></select>
          <select className="select" style={{ width: 130 }}><option>Mọi lớp</option></select>
          <div className="grow" />
          <button className="btn outline sm">☑ Chọn tất cả PENDING</button>
          <button className="btn success sm">✓ Duyệt đã chọn (4)</button>
          <button className="btn danger sm">✗ Từ chối</button>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th style={{ width: 30 }}><input type="checkbox" /></th>
                <th className="code" style={{ width: 130 }}>Mã SV</th>
                <th>Họ tên</th>
                <th className="code" style={{ width: 100 }}>Lớp</th>
                <th className="code" style={{ width: 130 }}>Thời gian ĐK</th>
                <th style={{ width: 130 }}>Trạng thái</th>
                <th className="right" style={{ width: 160 }}></th>
              </tr>
            </thead>
            <tbody>
              {entries.map((e, i) => (
                <tr key={i}>
                  <td><input type="checkbox" defaultChecked={e.status === 'PENDING' && i < 4} /></td>
                  <td className="code">{e.id}</td>
                  <td>
                    <div className="row gap-2">
                      <div className="avatar sm">{e.name.split(' ').slice(-1)[0][0]}</div>
                      <b>{e.name}</b>
                    </div>
                  </td>
                  <td className="code">{e.class}</td>
                  <td className="code">{e.when}</td>
                  <td>{e.status === 'PENDING' ? <span className="pill yellow">⏱ PENDING</span> : e.status === 'APPROVED' ? <span className="pill green">✓ APPROVED</span> : <span className="pill red">✗ REJECTED</span>}</td>
                  <td className="right">
                    <div className="row-actions">
                      {e.status === 'PENDING' ? <>
                        <button className="btn xs success">✓</button>
                        <button className="btn xs danger">✗</button>
                      </> : <button className="btn xs outline">Xem</button>}
                      <button className="btn xs ghost">⋯</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 6 — CHẤM BÀI (BLIND)
   ============================================================ */
function GV06_Judging() {
  return (
    <ScreenWrap label="Chấm bài (blind judging)" code="GV-05 · GET /api/me/judge-assignments + POST /assignments/{id}/scores">
      <GVShell active="/judge" url="/judge/87">
        <PageHead
          crumbs={["Chấm bài", "Olympic 2026 / Vòng loại / Entry #87"]}
          title="Chấm bài thi #87"
          badge={<span className="pill blue mono">ANONYMIZED</span>}
          actions={<>
            <button className="btn outline">← Bài trước</button>
            <button className="btn">Bài sau →</button>
          </>}
        />

        <div className="judge-grid">
          <div className="judge-paper">
            <div className="anon-banner">🔒 Đây là chế độ chấm ẩn danh — bạn không thấy thông tin SV cho đến khi gửi điểm.</div>
            <h3>Bài thi vòng loại #87</h3>

            <h4>Đề bài</h4>
            <p>Cho mảng <code>n</code> số nguyên. Hãy viết hàm tìm cặp số có tổng bằng <code>k</code> với độ phức tạp <code>O(n)</code>.</p>

            <h4>Lời giải của thí sinh</h4>
            <div className="code-block">
              <div><span className="ln">1</span><span className="kw">function</span> <span className="fn">findPair</span>(arr, k) {`{`}</div>
              <div><span className="ln">2</span>  <span className="kw">const</span> seen = <span className="kw">new</span> <span className="fn">Set</span>();</div>
              <div><span className="ln">3</span>  <span className="kw">for</span> (<span className="kw">const</span> x <span className="kw">of</span> arr) {`{`}</div>
              <div><span className="ln">4</span>    <span className="kw">if</span> (seen.<span className="fn">has</span>(k - x)) <span className="kw">return</span> [k - x, x];</div>
              <div><span className="ln">5</span>    seen.<span className="fn">add</span>(x);</div>
              <div><span className="ln">6</span>  {`}`}</div>
              <div><span className="ln">7</span>  <span className="kw">return</span> <span className="kw">null</span>;</div>
              <div><span className="ln">8</span>{`}`}</div>
              <div><span className="ln"></span><span className="com">// Test: findPair([2,7,11,15], 9) → [2,7] ✓</span></div>
            </div>

            <h4>Kết quả test (auto)</h4>
            <div className="row gap-2 mb-2">
              <span className="pill green">✓ test 1 · 12ms</span>
              <span className="pill green">✓ test 2 · 18ms</span>
              <span className="pill green">✓ test 3 · 24ms</span>
              <span className="pill green">✓ test 4 · 31ms</span>
              <span className="pill red">✗ test 5 · TLE</span>
            </div>
            <p className="text-xs muted">4/5 test passed · TLE ở test array 10⁶ phần tử</p>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Cho điểm theo rubric</div>
              <div className="score-input">
                <div>
                  <b>Tính đúng đắn</b>
                  <div className="meta">Tests passed, edge cases</div>
                </div>
                <div className="field"><input defaultValue="32" /><span className="max">/ 40</span></div>
              </div>
              <div className="score-input">
                <div>
                  <b>Hiệu năng</b>
                  <div className="meta">Time / space complexity</div>
                </div>
                <div className="field"><input defaultValue="22" /><span className="max">/ 30</span></div>
              </div>
              <div className="score-input">
                <div>
                  <b>Code quality</b>
                  <div className="meta">Style, comments, naming</div>
                </div>
                <div className="field"><input defaultValue="18" /><span className="max">/ 20</span></div>
              </div>
              <div className="score-input">
                <div>
                  <b>Sáng tạo</b>
                  <div className="meta">Approach novelty</div>
                </div>
                <div className="field"><input defaultValue="8" /><span className="max">/ 10</span></div>
              </div>
              <div className="divider" />
              <div className="row between">
                <span className="bold">Tổng điểm</span>
                <span className="mono bold" style={{ fontSize: 22 }}><span style={{ color: 'var(--accent)' }}>80</span> / 100</span>
              </div>
            </div>

            <div className="card">
              <div className="title">Nhận xét cho thí sinh</div>
              <textarea className="textarea" rows={5} defaultValue="Lời giải đúng và súc tích. Cần lưu ý xử lý edge case mảng cực lớn — test 5 TLE do dùng Set thay vì hash table tự cài (overhead JS engine)." />
              <div className="row gap-2 mt-2">
                <button className="btn outline sm">💾 Lưu nháp</button>
                <button className="btn sm grow" style={{ justifyContent: 'center' }}>✓ Gửi điểm <span className="kbd">⌘⏎</span></button>
              </div>
            </div>

            <div className="card text-xs muted">
              <div className="title" style={{ fontSize: 12, marginBottom: 8 }}>Tiến độ chấm</div>
              <div className="row between mb-2"><span>Đã chấm</span><span className="mono bold" style={{ color: 'var(--fg)' }}>15 / 27</span></div>
              <div className="progress" style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
                <div style={{ width: '55%', height: '100%', background: 'var(--accent)' }} />
              </div>
              <div className="mono mt-2">Hạn: 07/05/2026 23:59 · còn 3 ngày</div>
            </div>
          </div>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 7 — TỔNG HỢP KQ + SUBMIT QĐ2
   ============================================================ */
function GV07_Results() {
  const rows = [
    { rank: 1, medal: 'gold', id: 'SV-21', name: 'Phạm Minh Anh', r1: 92, r2: 88, total: 90.4 },
    { rank: 2, medal: 'gold', id: 'SV-08', name: 'Trần Quốc Bảo', r1: 88, r2: 90, total: 88.8 },
    { rank: 3, medal: 'silver', id: 'SV-44', name: 'Nguyễn Thu Hà', r1: 86, r2: 84, total: 85.2 },
    { rank: 4, medal: 'silver', id: 'SV-12', name: 'Lê Văn Dũng', r1: 80, r2: 88, total: 83.2 },
    { rank: 5, medal: 'bronze', id: 'SV-33', name: 'Vũ Hồng Linh', r1: 78, r2: 84, total: 80.4 },
    { rank: 6, medal: 'bronze', id: 'SV-29', name: 'Đỗ Khánh Mai', r1: 76, r2: 82, total: 78.4 },
    { rank: 7, medal: 'bronze', id: 'SV-17', name: 'Hoàng Thanh Nga', r1: 74, r2: 78, total: 75.6 },
    { rank: 8, medal: '', id: 'SV-50', name: 'Bùi Tuấn Phát', r1: 70, r2: 76, total: 72.4 },
  ];
  return (
    <ScreenWrap label="Tổng hợp kết quả + Submit BCN_QĐ2" code="GV-06 · POST /results/compute + /submit-for-approval">
      <GVShell active="/results" url="/contests/oly-2026/results">
        <PageHead
          crumbs={["Cuộc thi", "Olympic 2026", "Kết quả chung cuộc"]}
          title="Kết quả chung cuộc"
          actions={<>
            <button className="btn outline">🔄 Tính lại từ rounds</button>
            <button className="btn outline">📥 Export</button>
            <button className="btn">📤 Gửi BCN duyệt (QĐ2)</button>
          </>}
        />

        <div className="banner info mb-3">
          <span>ℹ️</span>
          <span><b>Công thức:</b> total = R1 × 60% + R2 × 40%. Sau khi gửi duyệt, danh sách sẽ <b>khoá</b> và không thể chỉnh sửa.</span>
        </div>

        <div className="grid-stats-3 mb-3">
          <div className="stat">
            <div className="label-mono">Tổng SV</div>
            <div className="num">187</div>
            <div className="text-xs muted mt-1">Tất cả vòng đã chấm xong</div>
          </div>
          <div className="stat">
            <div className="label-mono">Điểm TB</div>
            <div className="num">68.4</div>
            <div className="delta">▲ +4.2 so với 2025</div>
          </div>
          <div className="stat">
            <div className="label-mono">Pass rate</div>
            <div className="num">73%</div>
            <div className="delta">▲ +5.3%</div>
          </div>
        </div>

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th style={{ width: 60 }}>#</th>
                  <th className="code" style={{ width: 80 }}>ID</th>
                  <th>Họ tên</th>
                  <th className="num right" style={{ width: 70 }}>R1</th>
                  <th className="num right" style={{ width: 70 }}>R2</th>
                  <th className="num right" style={{ width: 90 }}>TỔNG</th>
                  <th style={{ width: 110 }}>Giải</th>
                </tr>
              </thead>
              <tbody>
                {rows.map(r => (
                  <tr key={r.rank}>
                    <td className="num"><span className={`medal ${r.medal}`}>{r.rank <= 3 ? ['🥇','🥈','🥉'][r.rank-1] : ''} {r.rank}</span></td>
                    <td className="code">{r.id}</td>
                    <td><b>{r.name}</b></td>
                    <td className="num right">{r.r1}</td>
                    <td className="num right">{r.r2}</td>
                    <td className="num right"><b style={{ color: 'var(--accent)' }}>{r.total}</b></td>
                    <td>
                      {r.medal === 'gold' ? <span className="pill yellow">🥇 Nhất</span> :
                       r.medal === 'silver' ? <span className="pill gray">🥈 Nhì</span> :
                       r.medal === 'bronze' ? <span className="pill" style={{ background: 'oklch(0.94 0.05 50)', color: 'oklch(0.46 0.10 50)' }}>🥉 Ba</span> :
                       <span className="pill">KK</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Phân bổ giải thưởng</div>
              <div className="col gap-3 text-sm">
                <div className="row between"><span>🥇 Nhất</span><span className="mono">2 / 2</span></div>
                <div className="row between"><span>🥈 Nhì</span><span className="mono">2 / 3</span></div>
                <div className="row between"><span>🥉 Ba</span><span className="mono">3 / 5</span></div>
                <div className="row between"><span>🎖 Khuyến khích</span><span className="mono">1 / 10</span></div>
                <div className="divider" />
                <div className="row between"><b>Tổng giải</b><b className="mono">8 / 20</b></div>
              </div>
            </div>

            <div className="card">
              <div className="title">Phân bố điểm</div>
              <div className="bar-chart">
                {[12, 22, 38, 54, 35, 18, 6].map((v, i) => (
                  <div className="bar" key={i}>
                    <div className="v" style={{ height: `${v * 1.6}%` }} />
                    <div className="lbl">{['<40','40-50','50-60','60-70','70-80','80-90','90+'][i]}</div>
                  </div>
                ))}
              </div>
              <div className="legend-row mt-4 text-xs"><span>Số SV theo khoảng điểm</span></div>
            </div>

            <div className="banner warn">
              <span>⚠</span>
              <span>Khi gửi duyệt QĐ2, hệ thống sẽ <b>khoá kết quả</b> và <b>thông báo cho BCN khoa</b>.</span>
            </div>
          </div>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   SCREEN 8 — STATISTICS
   ============================================================ */
function GV08_Stats() {
  return (
    <ScreenWrap label="Thống kê & báo cáo" code="GV-07 · GET /api/contests/{id}/stats + /report.xlsx">
      <GVShell active="/stats" url="/stats">
        <PageHead
          crumbs={["Thống kê"]}
          title="Thống kê hoạt động"
          actions={<>
            <select className="select" style={{ width: 110 }}><option>2026</option><option>2025</option></select>
            <select className="select" style={{ width: 160 }}><option>Tất cả cuộc thi</option></select>
            <button className="btn outline">📥 Export .xlsx</button>
          </>}
        />

        <div className="stats">
          <div className="stat"><div className="label-mono">CT đã tổ chức</div><div className="num">8</div><div className="delta">▲ +2 so 2025</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">SV tham gia</div><div className="num">632</div><div className="delta">▲ +127</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Bài đã chấm</div><div className="num">1,284</div><div className="delta">▲ +18%</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">CN cấp ra</div><div className="num">218</div><div className="delta">▲ +44</div><div className="accent-bar" /></div>
        </div>

        <div className="grid-21" style={{ alignItems: 'stretch' }}>
          <div className="card">
            <div className="title">Số lượt tham gia theo tháng <span className="right legend-row"><span>SV đăng ký</span></span></div>
            <div className="bar-chart" style={{ height: 220 }}>
              {[
                { m: 'T1', v: 12 }, { m: 'T2', v: 22 }, { m: 'T3', v: 65 }, { m: 'T4', v: 88 },
                { m: 'T5', v: 187, hl: true }, { m: 'T6', v: 102 }, { m: 'T7', v: 35 },
                { m: 'T8', v: 50 }, { m: 'T9', v: 78 }, { m: 'T10', v: 60 }, { m: 'T11', v: 18 }, { m: 'T12', v: 15 },
              ].map((b, i) => (
                <div className="bar" key={i}>
                  <div className="v" style={{ height: `${b.v / 1.9}%`, background: b.hl ? 'var(--accent)' : 'var(--accent-soft)' }} />
                  {b.hl && <div className="top">{b.v}</div>}
                  <div className="lbl">{b.m}</div>
                </div>
              ))}
            </div>
            <div className="text-xs muted mt-4">Cao nhất: tháng 5 (Olympic Tin học) — 187 lượt</div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Top loại cuộc thi</div>
              <div className="col gap-3">
                {[
                  { l: 'Lập trình thi đấu', v: 78, c: 'var(--accent)' },
                  { l: 'Hackathon', v: 56, c: 'oklch(0.6 0.15 250)' },
                  { l: 'Olympic', v: 42, c: 'oklch(0.7 0.15 80)' },
                  { l: 'Web/UI', v: 28, c: 'oklch(0.6 0.13 290)' },
                  { l: 'AI/ML', v: 14, c: 'oklch(0.65 0.13 150)' },
                ].map((row, i) => (
                  <div key={i}>
                    <div className="row between text-sm mb-2"><span>{row.l}</span><span className="mono">{row.v}%</span></div>
                    <div style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
                      <div style={{ width: `${row.v}%`, height: '100%', background: row.c, borderRadius: 4 }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="card">
              <div className="title">Hoạt động chấm bài</div>
              <div className="col gap-3 text-sm">
                <div className="row between"><span>Bài chấm hôm nay</span><b className="mono">8</b></div>
                <div className="row between"><span>TB / ngày (30d)</span><b className="mono">12.4</b></div>
                <div className="row between"><span>Cao điểm</span><b className="mono">42 (02/05)</b></div>
                <svg className="spark" viewBox="0 0 100 30" preserveAspectRatio="none">
                  <path className="area" d="M0 22 L8 18 L16 20 L24 14 L32 10 L40 16 L48 8 L56 12 L64 6 L72 14 L80 10 L88 16 L96 12 L100 14 L100 30 L0 30 Z" />
                  <path className="line" d="M0 22 L8 18 L16 20 L24 14 L32 10 L40 16 L48 8 L56 12 L64 6 L72 14 L80 10 L88 16 L96 12 L100 14" />
                </svg>
                <div className="text-xs muted">30 ngày qua</div>
              </div>
            </div>
          </div>
        </div>
      </GVShell>
    </ScreenWrap>
  );
}

/* ============================================================
   APP ROOT
   ============================================================ */
function GVApp() {
  return (
    <>
      <GV01_Login />
      <GV02_Dashboard />
      <GV03_Contests />
      <GV04_Create />
      <GV05_ContestDetail />
      <GV06_Judging />
      <GV07_Results />
      <GV08_Stats />
    </>
  );
}

Object.assign(window, {
  Browser, Sidebar, ScreenWrap, PageHead,
  GVApp,
});
