/* global React */
const { Browser, Sidebar, ScreenWrap, PageHead } = window;

const BCNWHO = { initials: 'LH', name: 'PGS. Lê Hoàng', sub: 'BCN Khoa CNTT' };
function BCNShell({ active, url, children }) {
  return (
    <Browser url={url}>
      <Sidebar items={window.WEB.NAV_BCN} active={active} role="BCN Khoa" who={BCNWHO} />
      <div className="main">{children}</div>
    </Browser>
  );
}

/* ============================================================
   1 — DASHBOARD với queue ưu tiên
   ============================================================ */
function BCN01_Dashboard() {
  return (
    <ScreenWrap label="Dashboard BCN với queue ưu tiên" code="BCN-01 (sau login) + summary BCN-02/04">
      <BCNShell active="/dashboard" url="/dashboard">
        <PageHead
          crumbs={["Trang chủ"]}
          title="Dashboard — Khoa CNTT"
          actions={<div className="muted text-sm mono">📅 04/05/2026 · Tuần 18</div>}
        />

        <div className="stats">
          <div className="stat"><div className="label-mono">Queue chờ duyệt</div><div className="num">12</div><div className="delta down">▼ -3 hôm qua</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">Sắp hạn (≤ 24h)</div><div className="num" style={{ color: 'var(--err)' }}>3</div><div className="delta down">⚠ Cần xử lý</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">CT đang diễn ra</div><div className="num">8</div><div className="delta">▲ +2 tuần này</div><div className="accent-bar" /></div>
          <div className="stat"><div className="label-mono">SV khoa</div><div className="num">412</div><div className="delta">▲ +47</div><div className="accent-bar" /></div>
        </div>

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="card">
            <div className="title">Queue ưu tiên <span className="right"><span className="pill red">3 sắp hết hạn</span></span></div>
            <div className="queue-lane" style={{ border: 0 }}>
              <div className="queue-item urgent">
                <div className="num-tag">QĐ1</div>
                <div className="body">
                  <b>Hackathon Mùa hè 2026</b>
                  <div className="meta">GV Nguyễn Tuấn · Đề xuất lần 1 · 15/05 → 30/06</div>
                </div>
                <div className="right-meta"><b style={{ color: 'var(--err)' }}>còn 18h</b><span>05/05 09:00</span></div>
              </div>
              <div className="queue-item urgent">
                <div className="num-tag">QĐ2</div>
                <div className="body">
                  <b>Olympic Tin học 2025 — KQ chung cuộc</b>
                  <div className="meta">GV Trần Vinh · 245 SV · 8 giải thưởng</div>
                </div>
                <div className="right-meta"><b style={{ color: 'var(--err)' }}>còn 22h</b><span>05/05 13:00</span></div>
              </div>
              <div className="queue-item urgent">
                <div className="num-tag" style={{ background: 'oklch(0.95 0.05 290)', color: 'oklch(0.50 0.18 290)' }}>QĐ3</div>
                <div className="body">
                  <b>Mẫu CN Hackathon Mùa hè 2026</b>
                  <div className="meta">GV Nguyễn Tuấn · Template v2 · A4 ngang</div>
                </div>
                <div className="right-meta"><b style={{ color: 'var(--warn)' }}>còn 1d 4h</b><span>06/05 12:00</span></div>
              </div>
              <div className="queue-item">
                <div className="num-tag">QĐ1</div>
                <div className="body">
                  <b>Cuộc thi LT C++ 2026 (lần 3)</b>
                  <div className="meta">GV Phạm Hùng · PR_REQ · revision 3</div>
                </div>
                <div className="right-meta"><b>2 ngày</b><span>06/05 17:00</span></div>
              </div>
              <div className="queue-item">
                <div className="num-tag">QĐ1</div>
                <div className="body">
                  <b>Web Design Challenge 2026</b>
                  <div className="meta">GV Lê Thanh · Đề xuất lần 1</div>
                </div>
                <div className="right-meta"><b>3 ngày</b><span>07/05 12:00</span></div>
              </div>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Hiệu suất duyệt (30d)</div>
              <div className="row gap-3 mb-3">
                <div className="donut">
                  <svg viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--bg-sunken)" strokeWidth="14" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--ok)" strokeWidth="14" strokeDasharray="200 240" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="38" fill="none" stroke="var(--warn)" strokeWidth="14" strokeDasharray="20 240" strokeDashoffset="-200" strokeLinecap="round" />
                  </svg>
                  <div className="label"><div><div className="num">42</div><div className="lbl">Đã duyệt</div></div></div>
                </div>
                <div style={{ flex: 1, fontSize: 12, lineHeight: 2 }}>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--ok)' }} /> Approved <b className="mono" style={{ marginLeft: 'auto' }}>36</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--warn)' }} /> Yêu cầu sửa <b className="mono" style={{ marginLeft: 'auto' }}>4</b></div>
                  <div className="row gap-2"><span style={{ width: 10, height: 10, borderRadius: 3, background: 'var(--err)' }} /> Reject <b className="mono" style={{ marginLeft: 'auto' }}>2</b></div>
                </div>
              </div>
              <div className="text-xs muted mt-2">TB thời gian xử lý: <b className="mono" style={{ color: 'var(--fg)' }}>3.4h</b></div>
            </div>

            <div className="card">
              <div className="title">Cảnh báo</div>
              <div className="banner warn mb-2"><span>⏰</span><span>3 đề xuất sắp hết SLA 24h</span></div>
              <div className="banner info"><span>📊</span><span>Báo cáo BGH tháng 5 đến hạn 10/05</span></div>
            </div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   2 — QUEUE QĐ1
   ============================================================ */
function BCN02_QueueQD1() {
  const rows = [
    { id: 7, name: 'Hackathon Mùa hè 2026', gv: 'Nguyễn Tuấn', dept: 'CNTT', round: '1', sub: '03/05 14:22', sla: '18h', urgent: true },
    { id: 5, name: 'Cuộc thi LT C++ 2026', gv: 'Phạm Hùng', dept: 'CNTT', round: '3', sub: '02/05 09:11', sla: '2d', warn: true },
    { id: 8, name: 'Web Design Challenge 2026', gv: 'Lê Thanh', dept: 'CNTT', round: '1', sub: '02/05 16:30', sla: '3d', },
    { id: 9, name: 'AI Workshop Spring 2026', gv: 'Trần Vinh', dept: 'CNTT', round: '1', sub: '01/05 11:00', sla: '4d' },
    { id: 11, name: 'Mobile App Contest 2026', gv: 'Đặng Khoa', dept: 'CNTT', round: '2', sub: '30/04 18:14', sla: '5d' },
    { id: 12, name: 'Cybersecurity CTF 2026', gv: 'Vũ Mai', dept: 'CNTT', round: '1', sub: '30/04 09:08', sla: '6d' },
  ];
  return (
    <ScreenWrap label="Queue đề xuất chờ duyệt QĐ1" code="BCN-02 · GET /api/me/pending-approvals?type=CONTEST_PROPOSAL">
      <BCNShell active="/approve/proposals" url="/approve/proposals">
        <PageHead
          crumbs={["Phê duyệt", "Đề xuất cuộc thi"]}
          title={<>Queue đề xuất chờ duyệt <span className="pill solid">QĐ1</span></>}
          actions={<>
            <select className="select" style={{ width: 160 }}><option>Tất cả lần submit</option><option>Lần 1</option><option>Lần ≥2</option></select>
            <button className="btn outline">📥 Export</button>
          </>}
        />

        <div className="row gap-2 mb-3">
          <div className="search" style={{ minWidth: 320 }}><span className="ico">🔍</span><input placeholder="Tên cuộc thi, GV..." /></div>
          <select className="select" style={{ width: 140 }}><option>Mọi GV</option></select>
          <select className="select" style={{ width: 130 }}><option>SLA: Tất cả</option><option>≤ 24h</option><option>≤ 48h</option></select>
          <div className="grow" />
          <span className="text-xs muted mono">Hiển thị 6 / 7</span>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th className="code" style={{ width: 50 }}>#</th>
                <th>Cuộc thi</th>
                <th style={{ width: 140 }}>GV đề xuất</th>
                <th className="code center" style={{ width: 70 }}>Lần</th>
                <th className="code" style={{ width: 130 }}>Submit lúc</th>
                <th className="code" style={{ width: 90 }}>Còn</th>
                <th className="right" style={{ width: 130 }}></th>
              </tr>
            </thead>
            <tbody>
              {rows.map(r => (
                <tr key={r.id}>
                  <td className="code">#{r.id}</td>
                  <td>
                    <div className="row gap-2">
                      <b>{r.name}</b>
                      {r.urgent && <span className="pill red">⏰ urgent</span>}
                      {r.warn && <span className="pill yellow">↻ revision</span>}
                    </div>
                    <div className="text-xs muted mono mt-1">Khoa {r.dept}</div>
                  </td>
                  <td>
                    <div className="row gap-2">
                      <div className="avatar sm">{r.gv.split(' ').slice(-1)[0][0]}</div>
                      <span>{r.gv}</span>
                    </div>
                  </td>
                  <td className="code center">{r.round}</td>
                  <td className="code">{r.sub}</td>
                  <td className="code"><b style={{ color: r.urgent ? 'var(--err)' : r.warn ? 'var(--warn)' : 'var(--fg)' }}>{r.sla}</b></td>
                  <td className="right">
                    <button className="btn sm">Xét duyệt →</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   3 — DETAIL ĐỀ XUẤT + 3 NÚT
   ============================================================ */
function BCN03_Detail() {
  return (
    <ScreenWrap label="Detail đề xuất + 3 nút quyết định" code="BCN-02 · GET /api/approvals/{id} + POST /api/approvals/{id}/decide">
      <BCNShell active="/approve/proposals" url="/approve/proposals/7">
        <PageHead
          crumbs={["Phê duyệt", "Đề xuất", "#7 Hackathon Mùa hè 2026"]}
          title={<>Xét duyệt: Hackathon Mùa hè 2026 <span className="pill yellow">⏱ Lần 1</span></>}
          actions={<button className="btn outline">← Queue</button>}
        />

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="col">
            <div className="card">
              <div className="title">Thông tin chung <span className="right mono">#APPROVAL-7 · type=CONTEST_PROPOSAL</span></div>
              <div className="grid-2">
                <div><span className="label">Tên cuộc thi</span><b>Hackathon Mùa hè 2026</b></div>
                <div><span className="label">Mã</span><span className="mono">HACK-2026</span></div>
                <div><span className="label">Cấp</span><span className="pill solid">Cấp khoa</span></div>
                <div><span className="label">Khoa chủ trì</span>Khoa CNTT</div>
                <div><span className="label">Thời gian ĐK</span><span className="mono">15/05 → 14/06/2026</span></div>
                <div><span className="label">Diễn ra</span><span className="mono">15/06 → 30/06/2026</span></div>
                <div><span className="label">Số SV tối đa</span><span className="mono">200</span></div>
                <div><span className="label">Đề xuất bởi</span>
                  <div className="row gap-2 mt-1"><div className="avatar sm">N</div>TS. Nguyễn Tuấn</div>
                </div>
              </div>
              <div className="divider" />
              <div className="label">Mô tả</div>
              <p style={{ fontSize: 12.5, color: 'var(--fg-muted)', lineHeight: 1.6 }}>
                Hackathon 48 giờ liên tục với chủ đề "AI vì cộng đồng". Sinh viên các năm 2-4 toàn trường có thể tham gia theo đội 3-5 người. Có giải thưởng tổng trị giá 50 triệu. Đối tác: VNPT, Viettel, FPT.
              </p>
            </div>

            <div className="card">
              <div className="title">3 vòng thi</div>
              <div className="grid-3">
                <div className="round-card" style={{ margin: 0 }}>
                  <div className="row gap-2 mb-2"><span className="pill solid">V1</span><b>Sàng lọc</b></div>
                  <div className="text-xs mono muted">15/05 → 30/05 · ONLINE_QUIZ · 30%</div>
                </div>
                <div className="round-card" style={{ margin: 0 }}>
                  <div className="row gap-2 mb-2"><span className="pill solid">V2</span><b>Code đêm</b></div>
                  <div className="text-xs mono muted">15/06 09:00 → 17/06 09:00 · ONLINE_CODE · 50%</div>
                </div>
                <div className="round-card" style={{ margin: 0 }}>
                  <div className="row gap-2 mb-2"><span className="pill solid">V3</span><b>Demo</b></div>
                  <div className="text-xs mono muted">30/06 13:30 · OFFLINE_PITCH · 20%</div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">Giải thưởng dự kiến</div>
              <div className="table-wrap" style={{ borderRadius: 8 }}>
                <table>
                  <thead><tr><th>Hạng mục</th><th className="num right">SL</th><th className="num right">Giá trị / giải</th><th className="num right">Tổng</th></tr></thead>
                  <tbody>
                    <tr><td>🥇 Giải Nhất</td><td className="num right">1</td><td className="num right">15,000,000₫</td><td className="num right"><b>15,000,000₫</b></td></tr>
                    <tr><td>🥈 Giải Nhì</td><td className="num right">2</td><td className="num right">8,000,000₫</td><td className="num right"><b>16,000,000₫</b></td></tr>
                    <tr><td>🥉 Giải Ba</td><td className="num right">3</td><td className="num right">4,000,000₫</td><td className="num right"><b>12,000,000₫</b></td></tr>
                    <tr><td>🎖 Khuyến khích</td><td className="num right">7</td><td className="num right">1,000,000₫</td><td className="num right"><b>7,000,000₫</b></td></tr>
                    <tr style={{ background: 'var(--bg-sunken)' }}><td colSpan="3"><b>Tổng giá trị</b></td><td className="num right"><b style={{ color: 'var(--accent)' }}>50,000,000₫</b></td></tr>
                  </tbody>
                </table>
              </div>
              <div className="text-xs muted mt-2 mono">Nguồn: Tài trợ VNPT (30M) + Viettel (15M) + Khoa (5M)</div>
            </div>

            <div className="card">
              <div className="title">Tài liệu đính kèm (3)</div>
              <div className="col gap-2">
                {[
                  ['📄 The_le_Hackathon_2026.pdf', '288 KB'],
                  ['📊 Du_toan_kinh_phi.xlsx', '46 KB'],
                  ['📋 Cam_ket_tai_tro_VNPT.pdf', '178 KB'],
                ].map(([n, s], i) => (
                  <div key={i} className="row between" style={{ padding: '10px 12px', background: 'var(--bg-sunken)', borderRadius: 8 }}>
                    <span className="text-sm">{n}</span>
                    <div className="row gap-3">
                      <span className="text-xs muted mono">{s}</span>
                      <a className="text-xs" style={{ color: 'var(--accent)', fontWeight: 600 }}>Xem →</a>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="col">
            <div className="decision-panel">
              <h3>Quyết định</h3>
              <button className="btn success decision-btn">
                <span className="ico">✓</span>
                <div><b>Phê duyệt</b><div className="desc">Mở đăng ký SV ngay</div></div>
              </button>
              <button className="btn warn decision-btn">
                <span className="ico">↻</span>
                <div><b>Yêu cầu chỉnh sửa</b><div className="desc">Trả về GV revise</div></div>
              </button>
              <button className="btn danger decision-btn">
                <span className="ico">✗</span>
                <div><b>Từ chối</b><div className="desc">Đóng đề xuất</div></div>
              </button>

              <div className="divider mt-3" />
              <label className="label">Ghi chú / lý do</label>
              <textarea className="textarea" rows={5} placeholder="Bắt buộc nhập khi yêu cầu sửa hoặc từ chối..." />

              <div className="divider mt-3" />
              <div className="text-xs muted">SLA còn <b className="mono" style={{ color: 'var(--err)' }}>18h 22m</b></div>
              <div className="text-xs muted mt-2">Mọi quyết định được ghi audit log.</div>
            </div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   4 — DETAIL với revision history (lần 3)
   ============================================================ */
function BCN04_Revision() {
  return (
    <ScreenWrap label="Detail đề xuất với lịch sử revision (lần 3)" code="BCN-02 với revision_round = 3">
      <BCNShell active="/approve/proposals" url="/approve/proposals/5">
        <PageHead
          crumbs={["Phê duyệt", "Đề xuất", "#5 LT C++ 2026"]}
          title={<>Cuộc thi LT C++ 2026 <span className="pill yellow">↻ Lần 3 / PR_REQ</span></>}
          actions={<button className="btn outline">← Queue</button>}
        />

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="col">
            <div className="card">
              <div className="title">Lịch sử submit (3 lần) <span className="right mono">approval_id #5</span></div>
              <div className="timeline">
                <div className="timeline-item info">
                  <div className="ts">04/05/2026 09:30 · Lần 3</div>
                  <div className="head">GV Phạm Hùng nộp lại lần 3 <span className="pill yellow">đang xét</span></div>
                  <div className="desc">Đã chỉnh sửa: <b>thời gian vòng 2</b>, <b>cơ cấu giải thưởng</b>. Phản hồi đầy đủ ý kiến của BCN ở lần 2.</div>
                </div>
                <div className="timeline-item warn">
                  <div className="ts">02/05/2026 14:18 · Lần 2 → PR_REQ</div>
                  <div className="head">BCN yêu cầu chỉnh sửa</div>
                  <div className="desc">"Giải Nhất 20M cao hơn tiêu chuẩn cấp khoa. Thời gian vòng 2 chồng vào lịch thi cuối kỳ. <b>Đề nghị giảm còn 10M và dời sang sau 30/05.</b>"</div>
                </div>
                <div className="timeline-item">
                  <div className="ts">01/05/2026 11:02 · Lần 2</div>
                  <div className="head">GV Phạm Hùng nộp lại lần 2</div>
                  <div className="desc">Đã sửa: bổ sung kế hoạch vận hành, thêm giảng viên đồng tổ chức.</div>
                </div>
                <div className="timeline-item warn">
                  <div className="ts">29/04/2026 15:40 · Lần 1 → PR_REQ</div>
                  <div className="head">BCN yêu cầu chỉnh sửa</div>
                  <div className="desc">"Thiếu kế hoạch vận hành chi tiết, không có người đồng tổ chức."</div>
                </div>
                <div className="timeline-item">
                  <div className="ts">28/04/2026 09:11 · Lần 1</div>
                  <div className="head">GV Phạm Hùng nộp lần 1</div>
                  <div className="desc">Đề xuất ban đầu.</div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="title">So sánh thay đổi (Lần 2 → Lần 3) <span className="right pill yellow">2 thay đổi</span></div>
              <div className="diff-row">
                <div className="field">Vòng 2 — Bắt đầu</div>
                <div className="old">15/05/2026 09:00</div>
                <div className="new">→ 05/06/2026 09:00</div>
              </div>
              <div className="diff-row">
                <div className="field">Vòng 2 — Kết thúc</div>
                <div className="old">15/05/2026 17:00</div>
                <div className="new">→ 05/06/2026 17:00</div>
              </div>
              <div className="diff-row">
                <div className="field">Giải Nhất</div>
                <div className="old">20,000,000₫</div>
                <div className="new">→ 10,000,000₫</div>
              </div>
              <div className="diff-row">
                <div className="field">Tổng giải</div>
                <div className="old">42,000,000₫</div>
                <div className="new">→ 28,000,000₫</div>
              </div>
              <div className="diff-row">
                <div className="field">Khác</div>
                <div className="same" style={{ gridColumn: 'span 2' }}>17 trường khác — không đổi</div>
              </div>
            </div>
          </div>

          <div className="decision-panel">
            <h3>Quyết định lần 3</h3>
            <button className="btn success decision-btn">
              <span className="ico">✓</span>
              <div><b>Phê duyệt</b><div className="desc">Đã đáp ứng ý kiến lần 2</div></div>
            </button>
            <button className="btn warn decision-btn">
              <span className="ico">↻</span>
              <div><b>Yêu cầu sửa lần 4</b><div className="desc">Trả về GV</div></div>
            </button>
            <button className="btn danger decision-btn">
              <span className="ico">✗</span>
              <div><b>Từ chối</b><div className="desc">Sau 3 lần vẫn không đạt</div></div>
            </button>

            <div className="divider mt-3" />
            <label className="label">Ghi chú</label>
            <textarea className="textarea" rows={4} defaultValue="Đã đáp ứng đầy đủ 2 ý kiến của BCN ở lần 2 (giảm giải Nhất, dời lịch). Đồng ý phê duyệt." />

            <div className="divider mt-3" />
            <div className="banner warn"><span>⚠</span><span className="text-xs">Đây là lần thứ 3 — khuyến nghị quyết định dứt khoát.</span></div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   5 — DETAIL QĐ2 (Kết quả)
   ============================================================ */
function BCN05_QD2() {
  const top = [
    { rank: 1, name: 'Phạm Minh Anh', class: 'D23CN02', total: 90.4, prize: '🥇 Nhất' },
    { rank: 2, name: 'Trần Quốc Bảo', class: 'D23CN01', total: 88.8, prize: '🥇 Nhất' },
    { rank: 3, name: 'Nguyễn Thu Hà', class: 'D22CN03', total: 85.2, prize: '🥈 Nhì' },
    { rank: 4, name: 'Lê Văn Dũng', class: 'D23CN04', total: 83.2, prize: '🥈 Nhì' },
    { rank: 5, name: 'Vũ Hồng Linh', class: 'D22CN02', total: 80.4, prize: '🥉 Ba' },
  ];
  return (
    <ScreenWrap label="Detail kết quả chờ duyệt QĐ2" code="BCN-04 · GET /api/approvals/{id} (CONTEST_RESULT)">
      <BCNShell active="/approve/results" url="/approve/results/12">
        <PageHead
          crumbs={["Phê duyệt", "Kết quả", "#12 Olympic Tin học 2025"]}
          title={<>Kết quả: Olympic Tin học 2025 <span className="pill blue">QĐ2</span></>}
          actions={<button className="btn outline">← Queue</button>}
        />

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="col">
            <div className="stats" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
              <div className="stat"><div className="label-mono">SV dự thi</div><div className="num">245</div></div>
              <div className="stat"><div className="label-mono">SV được giải</div><div className="num">8</div></div>
              <div className="stat"><div className="label-mono">Điểm cao nhất</div><div className="num">90.4</div></div>
              <div className="stat"><div className="label-mono">Điểm TB</div><div className="num">68.4</div></div>
            </div>

            <div className="card">
              <div className="title">Top 5 + xác nhận giải <span className="right text-xs muted">3 vòng đã chấm xong, công thức R1×0.4 + R2×0.4 + R3×0.2</span></div>
              <div className="table-wrap" style={{ borderRadius: 8 }}>
                <table>
                  <thead><tr><th style={{ width: 50 }}>#</th><th>Họ tên</th><th className="code" style={{ width: 90 }}>Lớp</th><th className="num right" style={{ width: 80 }}>Điểm</th><th style={{ width: 110 }}>Giải</th></tr></thead>
                  <tbody>
                    {top.map(r => (
                      <tr key={r.rank}>
                        <td className="num"><b>{r.rank}</b></td>
                        <td><b>{r.name}</b></td>
                        <td className="code">{r.class}</td>
                        <td className="num right"><b style={{ color: 'var(--accent)' }}>{r.total}</b></td>
                        <td><span className="pill yellow">{r.prize}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="text-xs muted mt-3 mono">Hiển thị 5 / 245 · <a style={{ color: 'var(--accent)' }}>Xem tất cả →</a></div>
            </div>

            <div className="card">
              <div className="title">Phân bổ điểm</div>
              <div className="bar-chart">
                {[14, 28, 48, 72, 48, 26, 9].map((v, i) => (
                  <div className="bar" key={i}>
                    <div className="v" style={{ height: `${v * 1.1}%` }} />
                    <div className="lbl">{['<40','40-50','50-60','60-70','70-80','80-90','90+'][i]}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="col">
            <div className="decision-panel">
              <h3>Duyệt kết quả</h3>
              <button className="btn success decision-btn">
                <span className="ico">✓</span>
                <div><b>Phê duyệt QĐ2</b><div className="desc">Công bố + tạo CN</div></div>
              </button>
              <button className="btn warn decision-btn">
                <span className="ico">↻</span>
                <div><b>Yêu cầu xác minh</b><div className="desc">Trả về GV kiểm tra</div></div>
              </button>

              <div className="divider mt-3" />
              <div className="text-sm">
                <div className="row between mb-2"><span className="muted">Người gửi</span><span>GV Trần Vinh</span></div>
                <div className="row between mb-2"><span className="muted">Lúc</span><span className="mono">04/05 11:08</span></div>
                <div className="row between mb-2"><span className="muted">Số giải</span><span className="mono">8 / 20</span></div>
                <div className="row between"><span className="muted">SLA</span><b className="mono" style={{ color: 'var(--err)' }}>22h</b></div>
              </div>

              <div className="divider mt-3" />
              <div className="banner info"><span>📜</span><span className="text-xs">Sau khi duyệt, hệ thống tự sinh <b>245 chứng nhận</b> theo template đã duyệt.</span></div>
            </div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   6 — DUYỆT MẪU CHỨNG NHẬN
   ============================================================ */
function BCN06_Cert() {
  return (
    <ScreenWrap label="Duyệt mẫu chứng nhận (BCN_QĐ3)" code="BCN-06 · GET/PATCH /api/certificates/templates/{id}">
      <BCNShell active="/approve/certs" url="/approve/certs/template-2026-04">
        <PageHead
          crumbs={["Mẫu chứng nhận", "Hackathon 2026"]}
          title="Duyệt mẫu chứng nhận"
          actions={<button className="btn outline">← Templates</button>}
        />

        <div className="grid-21" style={{ alignItems: 'flex-start' }}>
          <div className="card" style={{ padding: 24 }}>
            <div className="title">Preview <span className="right text-xs mono">A4 ngang · 297×210mm</span></div>
            <div className="cert">
              <div className="sealRow">
                <div className="seal">P</div>
                <div className="deptmark">HỌC VIỆN CÔNG NGHỆ BCVT<br />KHOA CÔNG NGHỆ THÔNG TIN</div>
              </div>
              <div className="sub">Certificate of Achievement</div>
              <h1>GIẤY CHỨNG NHẬN</h1>
              <div className="sub">được trao cho</div>
              <div className="name">{`<TÊN SINH VIÊN>`}</div>
              <div className="desc">đã đạt <b>{`<GIẢI THƯỞNG>`}</b> trong cuộc thi <b>Hackathon Mùa hè 2026</b><br />tổ chức từ ngày 15/06/2026 đến ngày 30/06/2026 tại Học viện Công nghệ BCVT.</div>
              <div className="footer">
                <div>
                  <div className="signature">Lê Hoàng</div>
                  <div className="mono" style={{ borderTop: '1px solid var(--brand-700)', paddingTop: 4, marginTop: 2 }}>BCN Khoa CNTT</div>
                </div>
                <div className="qr"></div>
                <div>
                  <div className="signature">Nguyễn Tuấn</div>
                  <div className="mono" style={{ borderTop: '1px solid var(--brand-700)', paddingTop: 4, marginTop: 2 }}>Trưởng BTC</div>
                </div>
              </div>
            </div>

            <div className="row gap-2 mt-4">
              <button className="btn outline sm">📥 Tải PDF mẫu</button>
              <button className="btn outline sm">🔍 Xem các trường động</button>
              <div className="grow" />
              <span className="text-xs muted">Template v2.1 · cập nhật 04/05</span>
            </div>
          </div>

          <div className="col">
            <div className="card">
              <div className="title">Trường động</div>
              <div className="col gap-2 text-sm">
                {[
                  ['{`<TÊN SINH VIÊN>`}', 'student.full_name'],
                  ['{`<GIẢI THƯỞNG>`}', 'result.prize_label'],
                  ['{`<TÊN CUỘC THI>`}', 'contest.name'],
                  ['{`<NGÀY>`}', 'contest.date_range'],
                  ['{`<QR>`}', 'cert.verify_url'],
                ].map(([f, k], i) => (
                  <div key={i} className="row between" style={{ padding: '8px 10px', background: 'var(--bg-sunken)', borderRadius: 6 }}>
                    <span className="mono text-xs" style={{ color: 'var(--accent)' }}>{f}</span>
                    <span className="mono text-xs muted">{k}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="decision-panel" style={{ position: 'static' }}>
              <h3>Duyệt mẫu</h3>
              <button className="btn success decision-btn">
                <span className="ico">✓</span><div><b>Phê duyệt</b><div className="desc">Cho phép cấp CN</div></div>
              </button>
              <button className="btn warn decision-btn">
                <span className="ico">↻</span><div><b>Yêu cầu sửa</b><div className="desc">Trả về GV</div></div>
              </button>

              <div className="divider mt-3" />
              <label className="label">Checklist</label>
              <div className="col gap-2 text-sm">
                <label className="row gap-2"><input type="checkbox" defaultChecked /> Logo PTIT đúng quy chuẩn</label>
                <label className="row gap-2"><input type="checkbox" defaultChecked /> Có chữ ký BCN khoa</label>
                <label className="row gap-2"><input type="checkbox" defaultChecked /> Có QR xác thực</label>
                <label className="row gap-2"><input type="checkbox" /> Đã thử in giấy A4</label>
              </div>

              <div className="divider mt-3" />
              <label className="label">Ghi chú</label>
              <textarea className="textarea" rows={3} placeholder="Tùy chọn..." />
            </div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================
   7 — GIÁM SÁT + STATS
   ============================================================ */
function BCN07_Monitor() {
  return (
    <ScreenWrap label="Giám sát + Thống kê khoa" code="BCN-03 + BCN-05 · GET /api/admin/contests/monitor + /reports/faculty-summary">
      <BCNShell active="/monitor" url="/monitor">
        <PageHead
          crumbs={["Theo dõi", "Giám sát"]}
          title="Giám sát cuộc thi (Khoa CNTT)"
          actions={<>
            <select className="select" style={{ width: 130 }}><option>Mọi status</option><option>REG_OPEN</option><option>ONGOING</option></select>
            <button className="btn outline">📥 Báo cáo</button>
          </>}
        />

        <div className="grid-3 mb-3">
          <div className="monitor-card ok">
            <div className="row between">
              <span className="pill green dot">ONGOING</span>
              <span className="live">LIVE</span>
            </div>
            <b style={{ fontSize: 14 }}>Olympic Tin học 2026</b>
            <div className="text-xs muted mono">Vòng loại · 03/05 → 10/05</div>
            <div className="progress" style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: '62%', height: '100%', background: 'var(--ok)' }} />
            </div>
            <div className="row between text-xs mono"><span className="muted">187 SV · 42 chấm xong</span><b style={{ color: 'var(--ok)' }}>62%</b></div>
          </div>
          <div className="monitor-card">
            <div className="row between">
              <span className="pill blue dot">JUDGING</span>
              <span className="live">LIVE</span>
            </div>
            <b style={{ fontSize: 14 }}>Hackathon Mùa hè 2026</b>
            <div className="text-xs muted mono">Demo · 28/04 → 02/05</div>
            <div className="progress" style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: '88%', height: '100%', background: 'var(--info)' }} />
            </div>
            <div className="row between text-xs mono"><span className="muted">40 đội · 35 đã chấm</span><b style={{ color: 'var(--info)' }}>88%</b></div>
          </div>
          <div className="monitor-card warn">
            <div className="row between">
              <span className="pill yellow dot">REG_OPEN</span>
              <span className="text-xs mono muted">⚠ chậm</span>
            </div>
            <b style={{ fontSize: 14 }}>Web Design Challenge 2026</b>
            <div className="text-xs muted mono">ĐK · 02/05 → 14/05</div>
            <div className="progress" style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: '32%', height: '100%', background: 'var(--warn)' }} />
            </div>
            <div className="row between text-xs mono"><span className="muted">32 / 100 SV (mục tiêu)</span><b style={{ color: 'var(--warn)' }}>32%</b></div>
          </div>
        </div>

        <div className="grid-21" style={{ alignItems: 'stretch' }}>
          <div className="card">
            <div className="title">Số CT theo tháng (Khoa CNTT 2026)</div>
            <div className="bar-chart" style={{ height: 200 }}>
              {[1, 2, 4, 3, 6, 4, 2, 3, 5, 4, 2, 1].map((v, i) => (
                <div className="bar" key={i}>
                  <div className="v" style={{ height: `${v * 14}%` }} />
                  <div className="top">{v}</div>
                  <div className="lbl">T{i + 1}</div>
                </div>
              ))}
            </div>
          </div>
          <div className="card">
            <div className="title">Top GV năng động</div>
            <div className="col gap-3">
              {[
                ['Nguyễn Tuấn', 6], ['Phạm Hùng', 4], ['Trần Vinh', 3], ['Lê Thanh', 2], ['Vũ Mai', 2],
              ].map(([n, v], i) => (
                <div key={i}>
                  <div className="row between text-sm mb-2">
                    <div className="row gap-2"><div className="avatar sm">{n.split(' ').slice(-1)[0][0]}</div>{n}</div>
                    <span className="mono">{v} CT</span>
                  </div>
                  <div style={{ height: 6, background: 'var(--bg-sunken)', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${v * 16}%`, height: '100%', background: 'var(--accent)' }} />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </BCNShell>
    </ScreenWrap>
  );
}

/* ============================================================ */
function BCNApp() {
  return (
    <>
      <BCN01_Dashboard />
      <BCN02_QueueQD1 />
      <BCN03_Detail />
      <BCN04_Revision />
      <BCN05_QD2 />
      <BCN06_Cert />
      <BCN07_Monitor />
    </>
  );
}

Object.assign(window, { BCNApp });
