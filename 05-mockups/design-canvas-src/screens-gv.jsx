/* global React, Phone, AppBar, Body, NavBar, Card, Btn, Field, Input, Badge,
   Avatar, Icon, IconBtn, IconTile, ListRow, SectionHead, ChipRow, Progress,
   Stat, Segmented */
// ============================================================
// GIẢNG VIÊN / BTC SCREENS — chấm thi & quản lý
// ============================================================

const GV_NAV = [
  { key: "dash", label: "Tổng quan", icon: "home" },
  { key: "judge", label: "Chấm thi", icon: "edit" },
  { key: "events", label: "Sự kiện", icon: "calendar" },
  { key: "me", label: "Tôi", icon: "user" },
];

const gv_screens = [
  /* ───────── Dashboard ───────── */
  { id: "gv-01", label: "01 · Tổng quan GV", code: "GV1", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ padding: "12px 18px", flexShrink: 0, background: "var(--bg)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Avatar name="Pham Hai" size={42} color="var(--info)"/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11.5, color: "var(--fg-muted)" }}>Giám khảo · Khoa CNTT</div>
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: "-0.02em" }}>TS. Phạm Hải</div>
          </div>
          <IconBtn name="bell"/>
        </div>
      </div>
      <Body padding={16}>
        <Card style={{ background: "linear-gradient(135deg, var(--brand-700), var(--brand-600))", color: "#fff", border: "none", marginBottom: 16, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", right: -10, top: -10, opacity: 0.15 }}>
            <Icon name="edit" size={120}/>
          </div>
          <div style={{ fontSize: 11, fontWeight: 700, opacity: 0.85, textTransform: "uppercase", letterSpacing: "0.08em" }}>Hôm nay cần chấm</div>
          <div style={{ fontSize: 36, fontWeight: 800, letterSpacing: "-0.04em", margin: "4px 0 6px", fontFamily: "var(--font-display)" }}>14<span style={{ fontSize: 16, opacity: 0.7, fontWeight: 600 }}> bài</span></div>
          <div style={{ fontSize: 12, opacity: 0.9 }}>3 cuộc thi · hạn 17/05</div>
          <Btn variant="secondary" size="sm" style={{ background: "#fff", color: "var(--accent)", border: "none", marginTop: 12 }}>Bắt đầu chấm →</Btn>
        </Card>

        <SectionHead>Hoạt động · Tuần này</SectionHead>
        <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
          <Stat value="42" label="Đã chấm" tone="ok"/>
          <Stat value="14" label="Còn lại" tone="warn"/>
          <Stat value="86" label="Điểm TB"/>
        </div>

        <SectionHead action="Xem tất cả ›">Cuộc thi đang chấm</SectionHead>
        {[
          { t: "PTIT Code Hunt 2026", s: "Vòng sơ loại · 8/22 bài", p: 36, days: "5 ngày", icon: "code" },
          { t: "Hackathon Khởi nghiệp", s: "Demo day · 3/12 đội", p: 25, days: "12/05", icon: "lightning" },
          { t: "Tiếng Anh PTIT", s: "Đã hoàn thành", p: 100, days: "Done", icon: "graduate", done: true },
        ].map((c, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
              <IconTile name={c.icon} color={c.done ? "var(--ok)" : "var(--accent)"} bg={c.done ? "var(--ok-bg)" : "var(--accent-soft)"}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: "-0.015em" }}>{c.t}</div>
                <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>{c.s}</div>
                <div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 8 }}>
                  <div style={{ flex: 1 }}><Progress value={c.p} color={c.done ? "var(--ok)" : "var(--accent)"}/></div>
                  <span style={{ fontSize: 10.5, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{c.p}%</span>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={GV_NAV} active="dash"/>
    </Phone>
  )},

  /* ───────── Hàng đợi chấm ───────── */
  { id: "gv-02", label: "02 · Hàng đợi chấm", code: "GV2", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Bài cần chấm" subtitle="PTIT Code Hunt · Vòng sơ loại" trailing={<IconBtn name="filter"/>}/>
      <Body>
        <ChipRow value="pend" chips={[
          { value: "pend", label: "Chưa chấm · 14" },
          { value: "saved", label: "Đã lưu · 3" },
          { value: "done", label: "Hoàn thành · 8" },
        ]} style={{ marginBottom: 14 }}/>

        <Card style={{ background: "var(--info-bg)", borderColor: "transparent", padding: 12, marginBottom: 14 }}>
          <div style={{ display: "flex", gap: 10 }}>
            <Icon name="shield" size={16} color="var(--info)" style={{ flexShrink: 0, marginTop: 1 }}/>
            <div style={{ fontSize: 11.5, color: "var(--info)", lineHeight: 1.5 }}>
              <b>Quy chế:</b> Bài đã ẩn danh. Mã thí sinh bắt đầu bằng <span style={{ fontFamily: "var(--font-mono)" }}>#CH-</span>
            </div>
          </div>
        </Card>

        {[
          { id: "#CH-2026-018", t: "Round 1 · Bài giải", time: "Nộp 09/05 22:48", hint: "DP, Segment Tree", urgent: true },
          { id: "#CH-2026-022", t: "Round 1 · Bài giải", time: "Nộp 09/05 23:12", hint: "Greedy + Heap" },
          { id: "#CH-2026-025", t: "Round 1 · Bài giải", time: "Nộp 09/05 23:30", hint: "Graph BFS" },
          { id: "#CH-2026-031", t: "Round 1 · Bài giải", time: "Nộp 09/05 23:54", hint: "Math, primes" },
        ].map((s, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
              <div style={{ fontFamily: "var(--font-mono)", fontSize: 11, color: "var(--accent)", fontWeight: 700 }}>{s.id}</div>
              {s.urgent && <Badge tone="err" dot>Sắp hạn</Badge>}
            </div>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{s.t}</div>
            <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>{s.time}</div>
            <div style={{ marginTop: 10, padding: "6px 10px", background: "var(--bg-sunken)", borderRadius: 8, fontSize: 11, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>
              hint · {s.hint}
            </div>
            <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
              <Btn variant="outline" size="sm" style={{ flex: 1 }}>Xem</Btn>
              <Btn size="sm" style={{ flex: 1 }}>Chấm ngay →</Btn>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={GV_NAV} active="judge"/>
    </Phone>
  )},

  /* ───────── Form chấm điểm ───────── */
  { id: "gv-03", label: "03 · Chấm điểm", code: "GV2", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="#CH-2026-018" subtitle="PTIT Code Hunt · Vòng sơ loại" trailing={<IconBtn name="more-v"/>}/>
      <Body>
        <Card style={{ marginBottom: 12, padding: 12 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
            <span style={{ fontSize: 11.5, color: "var(--fg-muted)" }}>Bài nộp ẩn danh</span>
            <Badge tone="ok" dot>Hợp lệ</Badge>
          </div>
          <ListRow
            leading={<IconTile name="doc" color="var(--err)" bg="var(--err-bg)"/>}
            title="solution.pdf"
            subtitle="2.4 MB · Mở xem"
            trailing={<Icon name="fwd" size={14} color="var(--fg-faint)"/>}
          />
        </Card>

        <SectionHead>Tiêu chí chấm</SectionHead>
        {[
          { c: "Tính đúng đắn", w: 40, v: 36 },
          { c: "Tối ưu thuật toán", w: 30, v: 25 },
          { c: "Code style & comments", w: 20, v: 18 },
          { c: "Trình bày", w: 10, v: 9 },
        ].map((cr, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 8 }}>
              <div>
                <span style={{ fontSize: 12.5, fontWeight: 600 }}>{cr.c}</span>
                <span style={{ fontSize: 10.5, color: "var(--fg-faint)", marginLeft: 6, fontFamily: "var(--font-mono)" }}>· trọng số {cr.w}%</span>
              </div>
              <span style={{ fontSize: 14, fontWeight: 800, color: "var(--accent)", fontFamily: "var(--font-mono)", letterSpacing: "-0.02em" }}>{cr.v}<span style={{ fontSize: 11, color: "var(--fg-faint)" }}>/{cr.w}</span></span>
            </div>
            <div style={{ height: 6, background: "var(--ink-150)", borderRadius: 99, overflow: "hidden", position: "relative" }}>
              <div style={{ width: `${(cr.v/cr.w)*100}%`, height: "100%", background: "var(--accent)", borderRadius: 99 }}/>
            </div>
          </Card>
        ))}

        <Card style={{ background: "var(--accent-soft)", borderColor: "transparent", marginBottom: 14, padding: 14 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 12.5, fontWeight: 700, color: "var(--accent-soft-fg)" }}>Tổng điểm</span>
            <span style={{ fontSize: 28, fontWeight: 800, color: "var(--accent)", letterSpacing: "-0.035em", fontFamily: "var(--font-mono)" }}>88<span style={{ fontSize: 14, opacity: 0.6 }}>/100</span></span>
          </div>
        </Card>

        <Field label="Nhận xét cho thí sinh">
          <div style={{ padding: 12, border: "1px solid var(--border)", borderRadius: 12, background: "var(--bg-elev)", fontSize: 12.5, color: "var(--fg)", minHeight: 70, lineHeight: 1.55 }}>
            Lời giải logic, tối ưu tốt. Cần chú thích rõ hơn ở phần segment tree...
          </div>
        </Field>

        <div style={{ display: "flex", gap: 8 }}>
          <Btn variant="outline" style={{ flex: 1 }}>Lưu nháp</Btn>
          <Btn icon="check" style={{ flex: 1.6 }}>Hoàn tất chấm</Btn>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── Sự kiện được phân công ───────── */
  { id: "gv-04", label: "04 · Sự kiện", code: "GV3", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Sự kiện của tôi" subtitle="3 cuộc thi" large/>
      <Body>
        <ChipRow value="active" chips={["Đang diễn ra", "Sắp tới", "Đã xong"]} style={{ marginBottom: 14 }}/>

        {[
          { t: "PTIT Code Hunt 2026", role: "Giám khảo chính", date: "10/05 → 22/05", count: "142 thí sinh", icon: "code", tone: "brand" },
          { t: "Hackathon Khởi nghiệp", role: "Cố vấn kỹ thuật", date: "12/05 · 1 ngày", count: "38 đội", icon: "lightning", tone: "info" },
          { t: "Đồ án sinh viên 2026", role: "Hội đồng phản biện", date: "20/05 → 25/05", count: "24 đồ án", icon: "graduate", tone: "ok" },
        ].map((e, i) => (
          <Card key={i} style={{ marginBottom: 10, padding: 14 }}>
            <div style={{ display: "flex", gap: 12, marginBottom: 10 }}>
              <IconTile name={e.icon} color={`var(--${e.tone === "brand" ? "accent" : e.tone})`} bg={e.tone === "brand" ? "var(--accent-soft)" : `var(--${e.tone}-bg)`} size={42}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 700, letterSpacing: "-0.015em" }}>{e.t}</div>
                <Badge tone={e.tone} style={{ marginTop: 4 }}>{e.role}</Badge>
              </div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
              <div style={{ padding: "8px 10px", background: "var(--bg-sunken)", borderRadius: 10 }}>
                <div style={{ fontSize: 10, color: "var(--fg-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>Thời gian</div>
                <div style={{ fontSize: 12, fontWeight: 600, marginTop: 2 }}>{e.date}</div>
              </div>
              <div style={{ padding: "8px 10px", background: "var(--bg-sunken)", borderRadius: 10 }}>
                <div style={{ fontSize: 10, color: "var(--fg-muted)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>Tham gia</div>
                <div style={{ fontSize: 12, fontWeight: 600, marginTop: 2 }}>{e.count}</div>
              </div>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={GV_NAV} active="events"/>
    </Phone>
  )},

  /* ───────── Thống kê & xuất báo cáo ───────── */
  { id: "gv-05", label: "05 · Báo cáo", code: "GV4", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Báo cáo chấm thi" subtitle="PTIT Code Hunt · Sơ loại"/>
      <Body>
        <SectionHead>Phân bố điểm</SectionHead>
        <Card style={{ marginBottom: 14, padding: "14px 14px 10px" }}>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 110, marginBottom: 8 }}>
            {[
              { l: "0-50", v: 8 },
              { l: "51-60", v: 14 },
              { l: "61-70", v: 22 },
              { l: "71-80", v: 38, hi: true },
              { l: "81-90", v: 28 },
              { l: "91-100", v: 12 },
            ].map((b, i) => (
              <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
                <span style={{ fontSize: 10, fontWeight: 700, color: b.hi ? "var(--accent)" : "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{b.v}</span>
                <div style={{ width: "100%", height: `${b.v * 2}px`, background: b.hi ? "var(--accent)" : "var(--ink-200)", borderRadius: "4px 4px 0 0" }}/>
              </div>
            ))}
          </div>
          <div style={{ display: "flex", gap: 6 }}>
            {["0-50","51-60","61-70","71-80","81-90","91-100"].map((l, i) => (
              <div key={i} style={{ flex: 1, fontSize: 8.5, color: "var(--fg-faint)", textAlign: "center", fontFamily: "var(--font-mono)" }}>{l}</div>
            ))}
          </div>
        </Card>

        <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
          <Stat value="78.5" label="Điểm TB" tone="brand"/>
          <Stat value="94.5" label="Cao nhất" tone="ok"/>
          <Stat value="42" label="Bài" tone="info"/>
        </div>

        <SectionHead>Top 5 thí sinh</SectionHead>
        {[
          { r: 1, code: "#CH-2026-014", s: 94.5 },
          { r: 2, code: "#CH-2026-027", s: 91.0 },
          { r: 3, code: "#CH-2026-008", s: 88.5 },
          { r: 4, code: "#CH-2026-018", s: 86.5 },
          { r: 5, code: "#CH-2026-031", s: 85.0 },
        ].map(p => (
          <ListRow key={p.r}
            leading={<div style={{ width: 28, height: 28, borderRadius: 8, background: "var(--accent-soft)", display: "grid", placeItems: "center", color: "var(--accent)", fontWeight: 800, fontSize: 12, fontFamily: "var(--font-mono)" }}>{p.r}</div>}
            title={<span style={{ fontFamily: "var(--font-mono)", fontSize: 12.5 }}>{p.code}</span>}
            subtitle="Vòng sơ loại"
            trailing={<span style={{ fontSize: 14, fontWeight: 700, fontFamily: "var(--font-mono)", color: "var(--accent)" }}>{p.s}</span>}
            style={{ marginBottom: 6, padding: 10 }}
          />
        ))}

        <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
          <Btn variant="outline" icon="doc" style={{ flex: 1 }}>PDF</Btn>
          <Btn variant="outline" icon="image" style={{ flex: 1 }}>Excel</Btn>
        </div>
      </Body>
    </Phone>
  )},
];

window.GV_SCREENS = gv_screens;
