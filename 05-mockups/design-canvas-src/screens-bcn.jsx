/* global React, Phone, AppBar, Body, NavBar, Card, Btn, Field, Input, Badge,
   Avatar, Icon, IconBtn, IconTile, ListRow, SectionHead, ChipRow, Progress,
   Stat, Segmented */
// ============================================================
// BCN KHOA SCREENS — phê duyệt & giám sát
// ============================================================

const BCN_NAV = [
  { key: "dash", label: "Tổng quan", icon: "home" },
  { key: "approval", label: "Duyệt", icon: "approve" },
  { key: "report", label: "Báo cáo", icon: "chart" },
  { key: "me", label: "Tôi", icon: "user" },
];

const bcn_screens = [
  /* ───────── 01 Tổng quan BCN ───────── */
  { id: "bcn-01", label: "01 · Tổng quan BCN", code: "BCN1", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ padding: "12px 18px", flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Avatar name="Phan Hung" size={42} color="var(--brand-700)"/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11.5, color: "var(--fg-muted)" }}>BCN Khoa CNTT</div>
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: "-0.02em" }}>PGS. Phan Đăng Hưng</div>
          </div>
          <button style={{ width: 38, height: 38, borderRadius: 99, border: "1px solid var(--border)", background: "var(--bg-elev)", color: "var(--fg)", display: "grid", placeItems: "center", position: "relative" }}>
            <Icon name="bell" size={18}/>
            <span style={{ position: "absolute", top: 8, right: 9, width: 7, height: 7, borderRadius: 99, background: "var(--err)", border: "1.5px solid var(--bg-elev)" }}/>
          </button>
        </div>
      </div>
      <Body>
        <Card style={{ marginBottom: 14, padding: 16, background: "linear-gradient(135deg, var(--brand-800) 0%, var(--brand-600) 100%)", color: "#fff", border: "none", position: "relative", overflow: "hidden" }}>
          <Badge tone="outline" style={{ background: "rgba(255,255,255,0.18)", color: "#fff", border: "none" }} dot>Cần xử lý ngay</Badge>
          <div style={{ display: "flex", alignItems: "baseline", gap: 12, marginTop: 12 }}>
            <span style={{ fontSize: 44, fontWeight: 800, letterSpacing: "-0.04em", lineHeight: 1, fontFamily: "var(--font-display)" }}>7</span>
            <span style={{ fontSize: 13, opacity: 0.9 }}>đề xuất chờ phê duyệt</span>
          </div>
          <Btn variant="secondary" size="sm" style={{ background: "#fff", color: "var(--accent)", border: "none", marginTop: 12 }}>Mở danh sách →</Btn>
        </Card>

        <SectionHead>Tổng quan học kỳ</SectionHead>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 14 }}>
          <Stat value="32" label="Cuộc thi" tone="brand" icon="trophy"/>
          <Stat value="1.2K" label="Lượt đăng ký" tone="info" icon="users"/>
          <Stat value="86%" label="Tỉ lệ hoàn thành" tone="ok" icon="check-circle"/>
          <Stat value="142" label="Giải thưởng" tone="warn" icon="cert"/>
        </div>

        <SectionHead action="Xem báo cáo ›">Tham gia theo tháng</SectionHead>
        <Card style={{ marginBottom: 12, padding: 14 }}>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: 90, marginBottom: 8 }}>
            {[40, 56, 48, 72, 68, 88, 95].map((v, i) => (
              <div key={i} style={{ flex: 1, height: `${v}%`, background: i === 6 ? "var(--accent)" : "var(--accent-soft)", borderRadius: "4px 4px 0 0", position: "relative" }}>
                {i === 6 && <span style={{ position: "absolute", bottom: "100%", left: "50%", transform: "translateX(-50%)", marginBottom: 4, fontSize: 10, fontWeight: 700, color: "var(--accent)", fontFamily: "var(--font-mono)" }}>342</span>}
              </div>
            ))}
          </div>
          <div style={{ display: "flex", gap: 8, fontSize: 9.5, color: "var(--fg-faint)", textAlign: "center", fontFamily: "var(--font-mono)" }}>
            {["T11","T12","T1","T2","T3","T4","T5"].map(m => <div key={m} style={{ flex: 1 }}>{m}</div>)}
          </div>
        </Card>

        <SectionHead>Cuộc thi nổi bật</SectionHead>
        <Card style={{ padding: 14 }}>
          <div style={{ display: "flex", gap: 12 }}>
            <IconTile name="code" color="var(--accent)" bg="var(--accent-soft)" size={42}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: "-0.015em" }}>PTIT Code Hunt 2026</div>
              <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>142 thí sinh · vòng sơ loại</div>
              <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
                <Badge tone="ok" dot>On track</Badge>
                <Badge tone="neutral">Ngân sách 30tr</Badge>
              </div>
            </div>
          </div>
        </Card>
      </Body>
      <NavBar items={BCN_NAV} active="dash"/>
    </Phone>
  )},

  /* ───────── 02 Hàng đợi phê duyệt ───────── */
  { id: "bcn-02", label: "02 · Phê duyệt", code: "BCN2", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Phê duyệt đề xuất" subtitle="7 đang chờ"/>
      <Body>
        <ChipRow value="pending" chips={[
          { value: "pending", label: "Chờ duyệt · 7" },
          { value: "approved", label: "Đã duyệt · 18" },
          { value: "rejected", label: "Từ chối · 2" },
        ]} style={{ marginBottom: 14 }}/>

        {[
          { t: "Cuộc thi 'Robot mini' 2026", who: "Đoàn Khoa CNTT", when: "5 phút", money: "12.000.000đ", urgent: true },
          { t: "Workshop ML cho năm nhất", who: "CLB AI Club", when: "2 giờ", money: "5.500.000đ" },
          { t: "Hội thảo An toàn TT 2026", who: "Bộ môn ATTT", when: "1 ngày", money: "8.000.000đ" },
          { t: "Cuộc thi UI/UX Design", who: "CLB Design", when: "2 ngày", money: "6.500.000đ" },
        ].map((p, i) => (
          <Card key={i} style={{ marginBottom: 10, padding: 14 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
              <Badge tone={p.urgent ? "err" : "warn"} dot>{p.urgent ? "Khẩn" : "Chờ duyệt"}</Badge>
              <span style={{ fontSize: 10.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>{p.when} trước</span>
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.015em", marginBottom: 4 }}>{p.t}</div>
            <div style={{ fontSize: 11.5, color: "var(--fg-muted)" }}>Đề xuất bởi <b style={{ color: "var(--fg)" }}>{p.who}</b></div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 10, padding: "8px 10px", background: "var(--bg-sunken)", borderRadius: 10 }}>
              <span style={{ fontSize: 11, color: "var(--fg-muted)" }}>Ngân sách</span>
              <span style={{ fontSize: 12.5, fontWeight: 700, color: "var(--accent)", fontFamily: "var(--font-mono)" }}>{p.money}</span>
            </div>
            <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
              <Btn variant="outline" size="sm" style={{ flex: 1 }}>Xem chi tiết</Btn>
              <Btn variant="danger" size="sm" icon="close" style={{ flex: 0 }}>Từ chối</Btn>
              <Btn size="sm" icon="check" style={{ flex: 0 }}>Duyệt</Btn>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={BCN_NAV} active="approval"/>
    </Phone>
  )},

  /* ───────── 03 Chi tiết duyệt ───────── */
  { id: "bcn-03", label: "03 · Chi tiết đề xuất", code: "BCN3", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Chi tiết đề xuất" subtitle="Đề xuất mở cuộc thi" trailing={<IconBtn name="more-v"/>}/>
      <Body>
        <Card style={{ marginBottom: 12 }}>
          <Badge tone="err" dot>Khẩn · 5 phút trước</Badge>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: "-0.025em", margin: "10px 0 6px" }}>Cuộc thi 'Robot mini' 2026</div>
          <div style={{ fontSize: 12, color: "var(--fg-muted)", lineHeight: 1.55 }}>
            Cuộc thi thiết kế robot mini cho SV năm 2-3 ngành CNTT/Điện tử. Dự kiến 60-80 thí sinh, hình thức theo nhóm 3 người.
          </div>
        </Card>

        <SectionHead>Người đề xuất</SectionHead>
        <ListRow
          leading={<Avatar name="Doan Khoa" size={40} color="var(--info)"/>}
          title="Đoàn Khoa CNTT"
          subtitle="ThS. Lê Văn Bình · Bí thư"
          trailing={<Badge tone="ok" dot>Đã xác minh</Badge>}
          style={{ marginBottom: 12 }}
        />

        <SectionHead>Thông tin cuộc thi</SectionHead>
        <Card style={{ marginBottom: 12 }}>
          {[
            { k: "Thời gian", v: "01/06 → 30/06/2026" },
            { k: "Đối tượng", v: "SV năm 2-3" },
            { k: "Hình thức", v: "Nhóm 3 TV · Offline" },
            { k: "Dự kiến tham gia", v: "60-80 thí sinh" },
            { k: "Địa điểm", v: "Lab Robot · A2.401" },
          ].map((r, i, arr) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", borderBottom: i < arr.length-1 ? "1px solid var(--border)" : "none", fontSize: 12.5 }}>
              <span style={{ color: "var(--fg-muted)" }}>{r.k}</span>
              <span style={{ fontWeight: 600, textAlign: "right" }}>{r.v}</span>
            </div>
          ))}
        </Card>

        <SectionHead>Ngân sách dự toán</SectionHead>
        <Card style={{ marginBottom: 12 }}>
          {[
            { k: "Phần thưởng", v: "8.000.000đ" },
            { k: "Linh kiện hỗ trợ", v: "2.500.000đ" },
            { k: "Truyền thông", v: "1.000.000đ" },
            { k: "Khác", v: "500.000đ" },
          ].map((r, i) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", fontSize: 12 }}>
              <span style={{ color: "var(--fg-muted)" }}>{r.k}</span>
              <span style={{ fontWeight: 600, fontFamily: "var(--font-mono)" }}>{r.v}</span>
            </div>
          ))}
          <div style={{ height: 1, background: "var(--border)", margin: "6px 0" }}/>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", fontSize: 13.5, fontWeight: 700 }}>
            <span>Tổng</span>
            <span style={{ color: "var(--accent)", fontFamily: "var(--font-mono)" }}>12.000.000đ</span>
          </div>
        </Card>

        <SectionHead>Tệp đính kèm</SectionHead>
        <ListRow
          leading={<IconTile name="doc" color="var(--err)" bg="var(--err-bg)" size={36}/>}
          title="de-cuong-cuoc-thi.pdf"
          subtitle="2.1 MB"
          trailing={<Icon name="download" size={16} color="var(--fg-faint)"/>}
          style={{ marginBottom: 14 }}
        />

        <Field label="Ghi chú phê duyệt (tuỳ chọn)">
          <div style={{ padding: 12, border: "1px solid var(--border)", borderRadius: 12, background: "var(--bg-elev)", fontSize: 12.5, color: "var(--fg-muted)", minHeight: 50, fontStyle: "italic" }}>
            Đồng ý chủ trương. Đề nghị làm rõ phương án an toàn lao động khi thi đấu...
          </div>
        </Field>

        <div style={{ display: "flex", gap: 8 }}>
          <Btn variant="danger" icon="close" style={{ flex: 1 }}>Từ chối</Btn>
          <Btn icon="check" style={{ flex: 1.5 }}>Phê duyệt</Btn>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 04 Báo cáo tổng hợp ───────── */
  { id: "bcn-04", label: "04 · Báo cáo", code: "BCN4", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Báo cáo" subtitle="HK2 · 2025-2026" large trailing={<IconBtn name="download"/>}/>
      <Body>
        <ChipRow value="hk2" chips={["HK2 2025-26", "HK1 2025-26", "Năm 2024"]} style={{ marginBottom: 14 }}/>

        <SectionHead>Tham gia theo ngành</SectionHead>
        <Card style={{ marginBottom: 14 }}>
          {[
            { l: "CNTT", v: 480, p: 100, color: "var(--accent)" },
            { l: "ATTT", v: 220, p: 46, color: "var(--info)" },
            { l: "ĐTVT", v: 195, p: 41, color: "var(--ok)" },
            { l: "Đa Phương Tiện", v: 168, p: 35, color: "var(--warn)" },
            { l: "QTKD", v: 140, p: 29, color: "#7C3AED" },
          ].map((r, i) => (
            <div key={i} style={{ marginBottom: i === 4 ? 0 : 10 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ fontSize: 12, fontWeight: 600 }}>{r.l}</span>
                <span style={{ fontSize: 11.5, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{r.v} SV</span>
              </div>
              <div style={{ height: 8, background: "var(--ink-150)", borderRadius: 99, overflow: "hidden" }}>
                <div style={{ width: `${r.p}%`, height: "100%", background: r.color, borderRadius: 99 }}/>
              </div>
            </div>
          ))}
        </Card>

        <SectionHead>Loại hình cuộc thi</SectionHead>
        <Card style={{ marginBottom: 14, padding: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <svg viewBox="0 0 36 36" style={{ width: 100, height: 100, transform: "rotate(-90deg)" }}>
              <circle cx="18" cy="18" r="14" fill="none" stroke="var(--ink-150)" strokeWidth="6"/>
              <circle cx="18" cy="18" r="14" fill="none" stroke="var(--accent)" strokeWidth="6" strokeDasharray="40 88" strokeLinecap="round"/>
              <circle cx="18" cy="18" r="14" fill="none" stroke="var(--info)" strokeWidth="6" strokeDasharray="22 88" strokeDashoffset="-40" strokeLinecap="round"/>
              <circle cx="18" cy="18" r="14" fill="none" stroke="var(--ok)" strokeWidth="6" strokeDasharray="16 88" strokeDashoffset="-62" strokeLinecap="round"/>
            </svg>
            <div style={{ flex: 1 }}>
              {[
                { l: "CNTT (45%)", c: "var(--accent)" },
                { l: "Học thuật (25%)", c: "var(--info)" },
                { l: "Văn-Thể (18%)", c: "var(--ok)" },
                { l: "Khác (12%)", c: "var(--ink-300)" },
              ].map((r, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4, fontSize: 11.5 }}>
                  <span style={{ width: 10, height: 10, borderRadius: 3, background: r.c }}/>
                  <span style={{ color: "var(--fg-muted)" }}>{r.l}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>

        <SectionHead>Tài chính</SectionHead>
        <Card style={{ padding: 14 }}>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", fontSize: 12.5 }}>
            <span style={{ color: "var(--fg-muted)" }}>Ngân sách phân bổ</span>
            <span style={{ fontWeight: 600, fontFamily: "var(--font-mono)" }}>240.000.000đ</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", fontSize: 12.5 }}>
            <span style={{ color: "var(--fg-muted)" }}>Đã sử dụng</span>
            <span style={{ fontWeight: 600, fontFamily: "var(--font-mono)" }}>168.500.000đ</span>
          </div>
          <div style={{ marginTop: 8 }}><Progress value={70} color="var(--accent)"/></div>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6, fontSize: 11, color: "var(--fg-muted)" }}>
            <span>70% · còn 71.5tr</span>
            <span style={{ color: "var(--ok)", fontWeight: 600 }}>+ Đúng kế hoạch</span>
          </div>
        </Card>
      </Body>
      <NavBar items={BCN_NAV} active="report"/>
    </Phone>
  )},

  /* ───────── 05 Lịch hoạt động ───────── */
  { id: "bcn-05", label: "05 · Lịch hoạt động", code: "BCN5", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Lịch hoạt động" subtitle="Tháng 5 · 2026"/>
      <Body padding={0}>
        <div style={{ padding: "8px 16px 12px", borderBottom: "1px solid var(--border)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
            <button style={{ background: "transparent", border: "none", color: "var(--fg-muted)" }}><Icon name="back" size={18}/></button>
            <span style={{ fontSize: 14, fontWeight: 700 }}>Tháng 5, 2026</span>
            <button style={{ background: "transparent", border: "none", color: "var(--fg-muted)" }}><Icon name="fwd" size={18}/></button>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 4 }}>
            {["T2","T3","T4","T5","T6","T7","CN"].map(d => <div key={d} style={{ fontSize: 9.5, color: "var(--fg-faint)", textAlign: "center", fontWeight: 700, fontFamily: "var(--font-mono)" }}>{d}</div>)}
            {Array.from({length: 35}).map((_, i) => {
              const day = i - 2;
              const isMonth = day >= 1 && day <= 31;
              const today = day === 9;
              const hasEvent = [10, 12, 15, 20, 22].includes(day);
              const eventTone = day === 10 ? "var(--accent)" : day === 22 ? "var(--ok)" : "var(--info)";
              return (
                <div key={i} style={{
                  aspectRatio: "1", display: "grid", placeItems: "center", borderRadius: 8,
                  fontSize: 11.5, fontWeight: today ? 700 : 500,
                  background: today ? "var(--accent)" : "transparent",
                  color: today ? "#fff" : (isMonth ? "var(--fg)" : "var(--fg-faint)"),
                  position: "relative",
                  fontFamily: "var(--font-mono)",
                }}>
                  {isMonth ? day : ""}
                  {hasEvent && !today && <span style={{ position: "absolute", bottom: 4, width: 4, height: 4, borderRadius: 99, background: eventTone }}/>}
                </div>
              );
            })}
          </div>
        </div>
        <div style={{ padding: 14 }}>
          <SectionHead>Sắp tới</SectionHead>
          {[
            { d: "10", m: "Th 5", t: "Khai mạc Code Hunt 2026", time: "08:00 · A2", color: "var(--accent)" },
            { d: "12", m: "Th 5", t: "Hackathon Khởi nghiệp", time: "08:00 · D9", color: "var(--info)" },
            { d: "15", m: "Th 5", t: "Họp BCN tháng", time: "14:00 · Phòng họp", color: "var(--info)" },
            { d: "22", m: "Th 5", t: "Trao giải Code Hunt", time: "18:30 · Hội trường", color: "var(--ok)" },
          ].map((e, i) => (
            <div key={i} style={{ display: "flex", gap: 12, marginBottom: 10, alignItems: "stretch" }}>
              <div style={{ width: 48, padding: 8, borderRadius: 12, background: "var(--bg-elev)", border: "1px solid var(--border)", borderLeft: `3px solid ${e.color}`, textAlign: "center" }}>
                <div style={{ fontSize: 17, fontWeight: 800, color: e.color, fontFamily: "var(--font-display)", letterSpacing: "-0.03em" }}>{e.d}</div>
                <div style={{ fontSize: 9, color: "var(--fg-muted)", textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 600 }}>{e.m}</div>
              </div>
              <div style={{ flex: 1, padding: 10, background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 12 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600 }}>{e.t}</div>
                <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 3 }}>{e.time}</div>
              </div>
            </div>
          ))}
        </div>
      </Body>
    </Phone>
  )},
];

window.BCN_SCREENS = bcn_screens;
