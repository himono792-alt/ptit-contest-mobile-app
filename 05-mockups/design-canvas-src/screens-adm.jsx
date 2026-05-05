/* global React, Phone, AppBar, Body, NavBar, Card, Btn, Field, Input, Badge,
   Avatar, Icon, IconBtn, IconTile, ListRow, SectionHead, ChipRow, Progress,
   Stat, Segmented */
// ============================================================
// ADMIN SCREENS — quản trị hệ thống
// ============================================================

const ADM_NAV = [
  { key: "dash", label: "Tổng quan", icon: "chart" },
  { key: "users", label: "Người dùng", icon: "users" },
  { key: "system", label: "Hệ thống", icon: "server" },
  { key: "logs", label: "Logs", icon: "logs" },
];

const adm_screens = [
  /* ───────── 01 Admin dashboard ───────── */
  { id: "adm-01", label: "01 · Admin Dashboard", code: "AD1", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ padding: "12px 18px", flexShrink: 0, background: "var(--bg)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--ink-900)", display: "grid", placeItems: "center", color: "#fff" }}>
            <Icon name="shield" size={18}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>SYSTEM ADMIN</div>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.015em" }}>console.ptit</div>
          </div>
          <Badge tone="ok" dot>All systems</Badge>
        </div>
      </div>
      <Body>
        <SectionHead>System health · live</SectionHead>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 14 }}>
          <Card style={{ padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={{ fontSize: 10.5, color: "var(--fg-muted)", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.06em" }}>Uptime</span>
              <span style={{ width: 6, height: 6, borderRadius: 99, background: "var(--ok)", boxShadow: "0 0 0 3px var(--ok-bg)" }}/>
            </div>
            <div style={{ fontSize: 22, fontWeight: 800, fontFamily: "var(--font-mono)", letterSpacing: "-0.025em", marginTop: 4 }}>99.97<span style={{ fontSize: 13, color: "var(--fg-muted)" }}>%</span></div>
            <div style={{ fontSize: 10.5, color: "var(--ok)", marginTop: 2 }}>↑ 30 ngày</div>
          </Card>
          <Card style={{ padding: 12 }}>
            <div style={{ fontSize: 10.5, color: "var(--fg-muted)", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.06em" }}>Latency p95</div>
            <div style={{ fontSize: 22, fontWeight: 800, fontFamily: "var(--font-mono)", letterSpacing: "-0.025em", marginTop: 4 }}>142<span style={{ fontSize: 13, color: "var(--fg-muted)" }}>ms</span></div>
            <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 2 }}>API gateway</div>
          </Card>
          <Card style={{ padding: 12 }}>
            <div style={{ fontSize: 10.5, color: "var(--fg-muted)", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.06em" }}>Online users</div>
            <div style={{ fontSize: 22, fontWeight: 800, fontFamily: "var(--font-mono)", letterSpacing: "-0.025em", marginTop: 4 }}>1,284</div>
            <div style={{ fontSize: 10.5, color: "var(--info)", marginTop: 2 }}>+ 142 (15m)</div>
          </Card>
          <Card style={{ padding: 12 }}>
            <div style={{ fontSize: 10.5, color: "var(--fg-muted)", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.06em" }}>Storage</div>
            <div style={{ fontSize: 22, fontWeight: 800, fontFamily: "var(--font-mono)", letterSpacing: "-0.025em", marginTop: 4 }}>62<span style={{ fontSize: 13, color: "var(--fg-muted)" }}>%</span></div>
            <div style={{ marginTop: 4 }}><Progress value={62} thickness={4}/></div>
          </Card>
        </div>

        <SectionHead>Service status</SectionHead>
        <Card style={{ padding: 0, overflow: "hidden", marginBottom: 14 }}>
          {[
            { name: "auth-service", status: "ok", uptime: "30d", latency: "84ms" },
            { name: "contest-api", status: "ok", uptime: "28d", latency: "112ms" },
            { name: "submission-store", status: "warn", uptime: "12h", latency: "245ms" },
            { name: "notification-worker", status: "ok", uptime: "30d", latency: "32ms" },
            { name: "report-generator", status: "ok", uptime: "30d", latency: "—" },
          ].map((s, i, arr) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 14px", borderBottom: i < arr.length-1 ? "1px solid var(--border)" : "none" }}>
              <span style={{ width: 8, height: 8, borderRadius: 99, background: s.status === "ok" ? "var(--ok)" : "var(--warn)", flexShrink: 0 }}/>
              <span style={{ flex: 1, fontSize: 12, fontFamily: "var(--font-mono)", fontWeight: 600 }}>{s.name}</span>
              <span style={{ fontSize: 10.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>{s.uptime}</span>
              <span style={{ fontSize: 10.5, color: "var(--fg-muted)", fontFamily: "var(--font-mono)", width: 50, textAlign: "right" }}>{s.latency}</span>
            </div>
          ))}
        </Card>

        <SectionHead>Traffic · 24h</SectionHead>
        <Card style={{ padding: "14px 12px 8px" }}>
          <svg viewBox="0 0 280 80" style={{ width: "100%", height: 80 }}>
            <defs>
              <linearGradient id="g1" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--accent)" stopOpacity="0.25"/>
                <stop offset="100%" stopColor="var(--accent)" stopOpacity="0"/>
              </linearGradient>
            </defs>
            <path d="M0 60 Q20 50 40 52 T80 40 T120 35 T160 28 T200 22 T240 18 T280 10 L280 80 L0 80 Z" fill="url(#g1)"/>
            <path d="M0 60 Q20 50 40 52 T80 40 T120 35 T160 28 T200 22 T240 18 T280 10" fill="none" stroke="var(--accent)" strokeWidth="1.8"/>
          </svg>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 9.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)", marginTop: 4 }}>
            <span>00:00</span><span>06:00</span><span>12:00</span><span>18:00</span><span>now</span>
          </div>
        </Card>
      </Body>
      <NavBar items={ADM_NAV} active="dash"/>
    </Phone>
  )},

  /* ───────── 02 Quản lý người dùng ───────── */
  { id: "adm-02", label: "02 · Người dùng", code: "AD2", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Người dùng" subtitle="8,420 tổng" trailing={<IconBtn name="plus"/>}/>
      <Body>
        <div style={{ padding: "11px 14px", background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 12, display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
          <Icon name="search" size={16} color="var(--fg-faint)"/>
          <span style={{ flex: 1, fontSize: 13, color: "var(--fg-faint)" }}>MSSV, email, tên...</span>
          <kbd style={{ fontSize: 10, color: "var(--fg-faint)", padding: "2px 6px", background: "var(--bg-sunken)", border: "1px solid var(--border)", borderRadius: 4, fontFamily: "var(--font-mono)" }}>⌘K</kbd>
        </div>
        <ChipRow value="all" chips={[
          { value: "all", label: "Tất cả · 8.4K" },
          { value: "sv", label: "Sinh viên" },
          { value: "gv", label: "Giảng viên" },
          { value: "bcn", label: "BCN" },
        ]} style={{ marginBottom: 14 }}/>

        {[
          { n: "Nguyễn Văn An", id: "B21DCCN123", email: "b21dccn123@ptit.edu.vn", role: "SV", tone: "info", online: true },
          { n: "TS. Phạm Hải", id: "GV0421", email: "haipham@ptit.edu.vn", role: "GV", tone: "brand" },
          { n: "PGS. Phan Hưng", id: "GV0102", email: "hungpd@ptit.edu.vn", role: "BCN", tone: "ok" },
          { n: "Trần Bảo Linh", id: "B21DCCN045", email: "b21dccn045@ptit.edu.vn", role: "SV", tone: "info", online: true },
          { n: "Lê Minh Hoàng", id: "B21DCCN090", email: "b21dccn090@ptit.edu.vn", role: "SV", tone: "info" },
          { n: "ThS. Lê Bình", id: "GV0518", email: "binhlv@ptit.edu.vn", role: "GV", tone: "brand" },
        ].map((u, i) => (
          <Card key={i} style={{ marginBottom: 6, padding: 10 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ position: "relative" }}>
                <Avatar name={u.n} size={36}/>
                {u.online && <span style={{ position: "absolute", bottom: 0, right: 0, width: 10, height: 10, borderRadius: 99, background: "var(--ok)", border: "2px solid var(--bg-elev)" }}/>}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600 }}>{u.n}</div>
                <div style={{ fontSize: 10.5, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{u.id} · {u.email}</div>
              </div>
              <Badge tone={u.tone}>{u.role}</Badge>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={ADM_NAV} active="users"/>
    </Phone>
  )},

  /* ───────── 03 Phân quyền ───────── */
  { id: "adm-03", label: "03 · Phân quyền", code: "AD3", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Vai trò & quyền" subtitle="Role-based access control"/>
      <Body>
        <SectionHead>Vai trò</SectionHead>
        {[
          { r: "Sinh viên", c: 7820, perm: 6, color: "var(--info)" },
          { r: "Giảng viên / BTC", c: 412, perm: 14, color: "var(--accent)" },
          { r: "BCN Khoa", c: 18, perm: 22, color: "var(--ok)" },
          { r: "Admin hệ thống", c: 4, perm: 38, color: "var(--ink-900)" },
        ].map((r, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: r.color, display: "grid", placeItems: "center", color: "#fff", flexShrink: 0 }}>
                <Icon name={i === 0 ? "graduate" : i === 1 ? "edit" : i === 2 ? "shield" : "server"} size={18}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 700 }}>{r.r}</div>
                <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 2, fontFamily: "var(--font-mono)" }}>{r.c.toLocaleString()} người · {r.perm} quyền</div>
              </div>
              <Icon name="fwd" size={14} color="var(--fg-faint)"/>
            </div>
          </Card>
        ))}

        <SectionHead style={{ marginTop: 14 }}>Permission matrix · SV</SectionHead>
        <Card style={{ padding: 0, overflow: "hidden" }}>
          {[
            { p: "contest.view", v: true },
            { p: "contest.register", v: true },
            { p: "submission.create", v: true },
            { p: "submission.score", v: false },
            { p: "user.manage", v: false },
            { p: "system.config", v: false },
          ].map((r, i, arr) => (
            <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 14px", borderBottom: i < arr.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span style={{ fontSize: 11.5, fontFamily: "var(--font-mono)", color: "var(--fg)" }}>{r.p}</span>
              {r.v ? (
                <span style={{ width: 32, height: 18, borderRadius: 99, background: "var(--accent)", position: "relative", display: "inline-block" }}>
                  <span style={{ position: "absolute", top: 2, right: 2, width: 14, height: 14, borderRadius: 99, background: "#fff" }}/>
                </span>
              ) : (
                <span style={{ width: 32, height: 18, borderRadius: 99, background: "var(--ink-200)", position: "relative", display: "inline-block" }}>
                  <span style={{ position: "absolute", top: 2, left: 2, width: 14, height: 14, borderRadius: 99, background: "#fff" }}/>
                </span>
              )}
            </div>
          ))}
        </Card>
      </Body>
    </Phone>
  )},

  /* ───────── 04 Cấu hình hệ thống ───────── */
  { id: "adm-04", label: "04 · Cấu hình", code: "AD4", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Cấu hình hệ thống"/>
      <Body>
        <SectionHead>Tổ chức</SectionHead>
        <Card style={{ marginBottom: 12 }}>
          <Field label="Tên đơn vị">
            <Input defaultValue="Học viện Công nghệ Bưu chính Viễn thông"/>
          </Field>
          <Field label="Domain email">
            <Input icon="globe" defaultValue="@ptit.edu.vn"/>
          </Field>
          <Field label="Năm học hiện tại">
            <div style={{ display: "flex", gap: 8 }}>
              <div style={{ flex: 1 }}><Input defaultValue="2025-2026"/></div>
              <div style={{ flex: 1 }}><Input defaultValue="HK2"/></div>
            </div>
          </Field>
        </Card>

        <SectionHead>Tích hợp</SectionHead>
        {[
          { l: "Đăng nhập SSO PTIT", s: "OAuth2 · oidc.ptit.edu.vn", on: true, icon: "shield" },
          { l: "Email gateway (SMTP)", s: "smtp.ptit.edu.vn:587 · Verified", on: true, icon: "mail" },
          { l: "Push notification (FCM)", s: "Firebase project ptit-prod", on: true, icon: "bell" },
          { l: "Anti-plagiarism (MOSS)", s: "Đang tắt · cấu hình API key", on: false, icon: "shield" },
        ].map((it, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <IconTile name={it.icon} color="var(--fg)" bg="var(--bg-sunken)" size={36}/>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600 }}>{it.l}</div>
                <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 2, fontFamily: "var(--font-mono)" }}>{it.s}</div>
              </div>
              <span style={{ width: 36, height: 22, borderRadius: 99, background: it.on ? "var(--accent)" : "var(--ink-200)", position: "relative", display: "inline-block", flexShrink: 0 }}>
                <span style={{ position: "absolute", top: 2, [it.on ? "right" : "left"]: 2, width: 18, height: 18, borderRadius: 99, background: "#fff" }}/>
              </span>
            </div>
          </Card>
        ))}

        <SectionHead style={{ marginTop: 14 }}>Maintenance</SectionHead>
        <Card style={{ padding: 0, overflow: "hidden" }}>
          {[
            { l: "Backup database", s: "Hôm nay 03:00 · 2.4 GB", trail: "Run now" },
            { l: "Clear cache", s: "Last: 2 giờ trước", trail: "Run" },
            { l: "Reset OTP attempts", s: "Áp dụng cho all users", trail: "Run" },
          ].map((it, i, arr) => (
            <div key={i} style={{ padding: "12px 14px", borderBottom: i < arr.length - 1 ? "1px solid var(--border)" : "none", display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600 }}>{it.l}</div>
                <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 2, fontFamily: "var(--font-mono)" }}>{it.s}</div>
              </div>
              <Btn variant="outline" size="sm">{it.trail}</Btn>
            </div>
          ))}
        </Card>
      </Body>
      <NavBar items={ADM_NAV} active="system"/>
    </Phone>
  )},

  /* ───────── 05 Audit logs ───────── */
  { id: "adm-05", label: "05 · Audit log", code: "AD5", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Audit log" subtitle="Thời gian thực" trailing={<IconBtn name="filter"/>}/>
      <Body>
        <ChipRow value="all" chips={["Tất cả", "auth", "contest", "system", "error"]} style={{ marginBottom: 14 }}/>

        <Card style={{ background: "var(--bg-sunken)", borderColor: "transparent", padding: 8, marginBottom: 12 }}>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "4px 6px", fontSize: 10, color: "var(--fg-muted)", fontFamily: "var(--font-mono)", textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 700 }}>
            <span>Time · Event</span>
            <span>Actor</span>
          </div>
        </Card>

        {[
          { t: "23:48:12", lvl: "INFO", ev: "auth.login", who: "B21DCCN123", color: "var(--info)" },
          { t: "23:47:55", lvl: "INFO", ev: "submission.create", who: "B21DCCN123", color: "var(--info)" },
          { t: "23:45:02", lvl: "WARN", ev: "auth.failed_otp", who: "b22dccn099", color: "var(--warn)" },
          { t: "23:42:18", lvl: "INFO", ev: "contest.published", who: "GV0421", color: "var(--ok)" },
          { t: "23:38:44", lvl: "INFO", ev: "user.role_changed", who: "ADM001", color: "var(--info)" },
          { t: "23:35:09", lvl: "ERR", ev: "submission.upload_failed", who: "B21DCCN090", color: "var(--err)" },
          { t: "23:32:01", lvl: "INFO", ev: "contest.approved", who: "GV0102", color: "var(--ok)" },
          { t: "23:28:50", lvl: "INFO", ev: "auth.logout", who: "B21DCCN045", color: "var(--info)" },
        ].map((l, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10,
            padding: "8px 10px", marginBottom: 4,
            background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 8,
            fontFamily: "var(--font-mono)",
          }}>
            <span style={{ fontSize: 10, color: "var(--fg-faint)", width: 56, flexShrink: 0 }}>{l.t}</span>
            <span style={{
              fontSize: 9, fontWeight: 700, padding: "2px 6px", borderRadius: 4, width: 38, textAlign: "center", flexShrink: 0,
              background: `color-mix(in oklch, ${l.color} 18%, transparent)`,
              color: l.color,
            }}>{l.lvl}</span>
            <span style={{ flex: 1, fontSize: 10.5, color: "var(--fg)", minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{l.ev}</span>
            <span style={{ fontSize: 10, color: "var(--fg-muted)" }}>{l.who}</span>
          </div>
        ))}
        <div style={{ textAlign: "center", padding: "12px 0 4px", fontSize: 10.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>
          • live · 12 sự kiện/phút
        </div>
      </Body>
      <NavBar items={ADM_NAV} active="logs"/>
    </Phone>
  )},

  /* ───────── 06 Cuộc thi (admin view) ───────── */
  { id: "adm-06", label: "06 · QL Cuộc thi", code: "AD6", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Quản lý cuộc thi" subtitle="38 đang hoạt động" trailing={<IconBtn name="plus"/>}/>
      <Body>
        <ChipRow value="all" chips={[
          { value: "all", label: "Tất cả · 142" },
          { value: "live", label: "Đang chạy · 38" },
          { value: "draft", label: "Nháp · 6" },
          { value: "archive", label: "Lưu trữ" },
        ]} style={{ marginBottom: 14 }}/>

        {[
          { t: "PTIT Code Hunt 2026", own: "Khoa CNTT", count: 142, status: "Đang chạy", tone: "ok" },
          { t: "Hackathon Khởi nghiệp", own: "Phòng KH-CN", count: 38, status: "Sắp diễn ra", tone: "info" },
          { t: "Tiếng hát PTIT 2026", own: "Đoàn TN", count: 92, status: "Đăng ký", tone: "warn" },
          { t: "Robot mini 2026", own: "Đoàn Khoa CNTT", count: 0, status: "Nháp", tone: "neutral" },
          { t: "Đồ án sinh viên 2026", own: "Khoa CNTT", count: 24, status: "Đang chạy", tone: "ok" },
        ].map((c, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: "-0.015em" }}>{c.t}</div>
                <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 2 }}>{c.own}</div>
              </div>
              <Badge tone={c.tone} dot>{c.status}</Badge>
            </div>
            <div style={{ display: "flex", gap: 12, marginTop: 8, fontSize: 11, color: "var(--fg-muted)" }}>
              <span>👥 {c.count} thí sinh</span>
              <span style={{ fontFamily: "var(--font-mono)" }}>· #C{2025+i}{String(i*7).padStart(3,"0")}</span>
            </div>
          </Card>
        ))}
      </Body>
    </Phone>
  )},
];

window.ADM_SCREENS = adm_screens;
