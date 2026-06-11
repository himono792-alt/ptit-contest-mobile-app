/* global React, Phone, AppBar, Body, NavBar, Card, Btn, Field, Input, Badge,
   Avatar, Icon, IconBtn, DarkModeBtn, IconTile, ListRow, SectionHead, ChipRow, Progress,
   Stat, Segmented */
// ============================================================
// STUDENT SCREENS — 16 màn
// ============================================================

const SV_NAV = [
  { key: "home", label: "Trang chủ", icon: "home" },
  { key: "contests", label: "Cuộc thi", icon: "trophy" },
  { key: "my", label: "Của tôi", icon: "list" },
  { key: "noti", label: "Thông báo", icon: "bell" },
  { key: "me", label: "Tôi", icon: "user" },
];

const sv_screens = [
  /* ───────── 01 Splash ───────── */
  { id: "sv-01", label: "01 · Splash", code: "SV0", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{
        flex: 1, display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center", gap: 18,
        background: "linear-gradient(180deg, var(--bg) 0%, var(--accent-soft) 100%)",
        padding: 32, position: "relative",
      }}>
        <div style={{
          width: 84, height: 84, borderRadius: 22,
          background: "var(--accent)", color: "#fff",
          display: "grid", placeItems: "center",
          fontWeight: 800, fontSize: 26, letterSpacing: "-0.04em",
          boxShadow: "0 12px 30px oklch(0.547 0.207 19 / 0.35)",
        }}>P</div>
        <div style={{ textAlign: "center" }}>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.03em", color: "var(--fg)" }}>Contest Hub</div>
          <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 6, lineHeight: 1.5 }}>
            Học viện Công nghệ<br/>Bưu chính Viễn thông
          </div>
        </div>
        <div style={{ position: "absolute", bottom: 56 }}>
          <div style={{ width: 80, height: 3, borderRadius: 99, background: "var(--ink-200)", overflow: "hidden" }}>
            <div style={{ width: "40%", height: "100%", background: "var(--accent)" }}/>
          </div>
        </div>
        <div style={{ position: "absolute", bottom: 28, fontSize: 10, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>
          v2.4.1 · build 240501
        </div>
      </div>
    </Phone>
  )},

  /* ───────── 02 Onboarding 1 ───────── */
  { id: "sv-02", label: "02 · Onboarding", code: "ONB", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: 24, background: "var(--bg)" }}>
        <div style={{ display: "flex", justifyContent: "flex-end", paddingTop: 8 }}>
          <button style={{ background: "transparent", border: "none", color: "var(--fg-muted)", fontSize: 13, fontWeight: 600 }}>Bỏ qua</button>
        </div>
        <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", gap: 24 }}>
          <div style={{
            width: 200, height: 200, borderRadius: 24,
            background: "var(--accent-soft)",
            display: "grid", placeItems: "center", position: "relative",
          }}>
            <Icon name="trophy" size={84} color="var(--accent)" strokeWidth={1.4}/>
            <div style={{ position: "absolute", top: 22, right: 18, width: 36, height: 36, borderRadius: 12, background: "var(--bg-elev)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-sm)" }}>
              <Icon name="sparkle" size={18} color="var(--warn)"/>
            </div>
            <div style={{ position: "absolute", bottom: 26, left: 14, width: 36, height: 36, borderRadius: 12, background: "var(--bg-elev)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-sm)" }}>
              <Icon name="code" size={18} color="var(--info)"/>
            </div>
          </div>
          <div style={{ textAlign: "center", padding: "0 12px" }}>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.03em", color: "var(--fg)", marginBottom: 8 }}>
              Khám phá hàng chục<br/>cuộc thi mỗi học kỳ
            </div>
            <div style={{ fontSize: 13, color: "var(--fg-muted)", lineHeight: 1.55 }}>
              Lập trình, học thuật, sáng tạo — tất cả tại một nơi, đăng ký chỉ với vài chạm.
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: 6, justifyContent: "center", marginBottom: 18 }}>
          <span style={{ width: 22, height: 6, borderRadius: 99, background: "var(--accent)" }}/>
          <span style={{ width: 6, height: 6, borderRadius: 99, background: "var(--ink-200)" }}/>
          <span style={{ width: 6, height: 6, borderRadius: 99, background: "var(--ink-200)" }}/>
        </div>
        <Btn full size="lg">Tiếp tục</Btn>
      </div>
    </Phone>
  )},

  /* ───────── 03 Đăng nhập ───────── */
  { id: "sv-03", label: "03 · Đăng nhập", code: "SV1", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", background: "var(--bg)" }}>
        <div style={{ padding: "32px 24px 16px" }}>
          <div style={{
            width: 52, height: 52, borderRadius: 14, background: "var(--accent)",
            display: "grid", placeItems: "center", color: "#fff",
            fontWeight: 800, fontSize: 18, marginBottom: 28, letterSpacing: "-0.04em",
          }}>P</div>
          <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: "-0.035em", color: "var(--fg)" }}>Chào mừng<br/>trở lại 👋</div>
          <div style={{ fontSize: 13, color: "var(--fg-muted)", marginTop: 8 }}>Đăng nhập với email PTIT để tiếp tục.</div>
        </div>
        <div style={{ flex: 1, padding: "20px 24px" }}>
          <Field label="Email PTIT">
            <Input icon="mail" defaultValue="b21dccn123@ptit.edu.vn"/>
          </Field>
          <Field label="Mật khẩu">
            <Input icon="lock" type="password" defaultValue="••••••••"/>
          </Field>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
            <label style={{ fontSize: 12.5, color: "var(--fg-muted)", display: "flex", alignItems: "center", gap: 8 }}>
              <span style={{ width: 16, height: 16, borderRadius: 4, background: "var(--accent)", display: "grid", placeItems: "center" }}>
                <Icon name="check" size={11} color="#fff" strokeWidth={2.5}/>
              </span>
              Ghi nhớ tôi
            </label>
            <a style={{ fontSize: 12.5, color: "var(--accent)", fontWeight: 600 }}>Quên mật khẩu?</a>
          </div>
          <Btn full size="lg">Đăng nhập</Btn>
          <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "18px 0", color: "var(--fg-faint)", fontSize: 11.5 }}>
            <div style={{ flex: 1, height: 1, background: "var(--border)" }}/>
            <span>HOẶC</span>
            <div style={{ flex: 1, height: 1, background: "var(--border)" }}/>
          </div>
          <Btn variant="outline" full size="lg">Đăng ký tài khoản mới</Btn>
        </div>
        <div style={{ padding: "10px 24px 16px", textAlign: "center", fontSize: 11, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>
          POST /auth/login · JWT + OAuth2
        </div>
      </div>
    </Phone>
  )},

  /* ───────── 04 OTP ───────── */
  { id: "sv-04", label: "04 · Xác thực OTP", code: "SV1", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Xác thực OTP"/>
      <Body padding={24}>
        <div style={{ textAlign: "center", marginTop: 12 }}>
          <div style={{
            width: 64, height: 64, borderRadius: 18, background: "var(--accent-soft)",
            display: "grid", placeItems: "center", margin: "0 auto 18px",
          }}><Icon name="mail" size={28} color="var(--accent)"/></div>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: "-0.025em", marginBottom: 6 }}>Nhập mã 6 chữ số</div>
          <div style={{ fontSize: 12.5, color: "var(--fg-muted)", lineHeight: 1.55 }}>
            Đã gửi đến<br/><b style={{ color: "var(--fg)" }}>b21dccn123@ptit.edu.vn</b>
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(6, 1fr)", gap: 8, margin: "28px 0 16px" }}>
          {["8","2","5","7","",""].map((d, i) => (
            <div key={i} style={{
              aspectRatio: "1", borderRadius: 12,
              border: `1.5px solid ${d ? "var(--accent)" : "var(--border)"}`,
              background: d ? "var(--accent-soft)" : "var(--bg-elev)",
              display: "grid", placeItems: "center",
              fontSize: 22, fontWeight: 700, color: "var(--fg)",
            }}>{d}</div>
          ))}
        </div>
        <div style={{ textAlign: "center", fontSize: 12, color: "var(--fg-muted)", marginBottom: 20 }}>
          Mã hết hạn sau <b style={{ color: "var(--accent)", fontFamily: "var(--font-mono)" }}>02:34</b>
        </div>
        <Btn full size="lg">Xác thực</Btn>
        <div style={{ textAlign: "center", marginTop: 14, fontSize: 12.5, color: "var(--fg-muted)" }}>
          Không nhận được mã? <a style={{ color: "var(--accent)", fontWeight: 600 }}>Gửi lại</a>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 05 Trang chủ ───────── */
  { id: "sv-05", label: "05 · Trang chủ", code: "SV4-5", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{ padding: "12px 18px 4px", flexShrink: 0, background: "var(--bg)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Avatar name="An Nguyen" size={40} color="var(--accent)"/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11.5, color: "var(--fg-muted)" }}>Xin chào,</div>
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: "-0.02em" }}>Nguyễn Văn An</div>
          </div>
          <DarkModeBtn/>
          <button style={{ width: 38, height: 38, borderRadius: 99, border: "1px solid var(--border)", background: "var(--bg-elev)", color: "var(--fg)", display: "grid", placeItems: "center", position: "relative" }}>
            <Icon name="bell" size={18}/>
            <span style={{ position: "absolute", top: 8, right: 9, width: 7, height: 7, borderRadius: 99, background: "var(--accent)", border: "1.5px solid var(--bg-elev)" }}/>
          </button>
        </div>
        <div style={{ marginTop: 14, padding: "11px 14px", background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 14, display: "flex", alignItems: "center", gap: 10 }}>
          <Icon name="search" size={16} color="var(--fg-faint)"/>
          <span style={{ flex: 1, fontSize: 13, color: "var(--fg-faint)" }}>Tìm cuộc thi, BTC...</span>
          <kbd style={{ fontSize: 10, color: "var(--fg-faint)", padding: "2px 6px", background: "var(--bg-sunken)", border: "1px solid var(--border)", borderRadius: 4, fontFamily: "var(--font-mono)" }}>⌘K</kbd>
        </div>
      </div>
      <Body padding={16}>
        <div style={{ display: "flex", gap: 8, marginBottom: 18 }}>
          <Stat value="3" label="Đang tham gia" tone="brand"/>
          <Stat value="7" label="Đã hoàn thành"/>
          <Stat value="2" label="Giải thưởng" tone="warn"/>
        </div>

        <div style={{
          background: "linear-gradient(135deg, var(--brand-700) 0%, var(--brand-600) 100%)",
          borderRadius: 18, padding: 16, color: "#fff", marginBottom: 18, position: "relative", overflow: "hidden",
        }}>
          <div style={{ position: "absolute", right: -20, top: -20, width: 120, height: 120, borderRadius: 99, background: "rgba(255,255,255,0.08)" }}/>
          <Badge tone="outline" style={{ background: "rgba(255,255,255,0.18)", color: "#fff", border: "none" }} dot>Sự kiện nổi bật</Badge>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: "-0.03em", marginTop: 10, lineHeight: 1.2 }}>PTIT Code Hunt<br/>2026</div>
          <div style={{ fontSize: 12, opacity: 0.9, marginTop: 6, display: "flex", gap: 12 }}>
            <span>📅 5 ngày còn lại</span>
            <span>👥 142 thí sinh</span>
          </div>
          <button style={{ marginTop: 12, padding: "8px 14px", borderRadius: 99, border: "none", background: "#fff", color: "var(--accent)", fontWeight: 700, fontSize: 12 }}>
            Đăng ký ngay →
          </button>
        </div>

        <SectionHead action="Xem tất cả ›">Hôm nay</SectionHead>
        <Card style={{ marginBottom: 8 }}>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <IconTile name="trophy" color="var(--accent)" bg="var(--accent-soft)"/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600 }}>Vòng chung kết Code Hunt</div>
              <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>10/05 · 08:00 · Hội trường A2</div>
            </div>
            <Badge tone="brand">2 ngày</Badge>
          </div>
        </Card>
        <Card>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <IconTile name="bell" color="var(--info)" bg="var(--info-bg)"/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600 }}>BTC đã công bố kết quả</div>
              <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>Hùng biện 2026 · vừa xong</div>
            </div>
          </div>
        </Card>
      </Body>
      <NavBar items={SV_NAV} active="home"/>
    </Phone>
  )},

  /* ───────── 06 Danh sách cuộc thi ───────── */
  { id: "sv-06", label: "06 · Cuộc thi", code: "SV4", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Khám phá" subtitle="38 cuộc thi đang diễn ra" leading="back" trailing={<IconBtn name="filter"/>} large/>
      <Body padding={16}>
        <div style={{ marginBottom: 14, padding: "11px 14px", background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 14, display: "flex", alignItems: "center", gap: 10 }}>
          <Icon name="search" size={16} color="var(--fg-faint)"/>
          <span style={{ flex: 1, fontSize: 13, color: "var(--fg-faint)" }}>Tìm cuộc thi...</span>
        </div>
        <ChipRow value="all" chips={[
          { value: "all", label: "Tất cả · 38" },
          { value: "it", label: "CNTT" },
          { value: "ac", label: "Học thuật" },
          { value: "art", label: "Văn nghệ" },
          { value: "sport", label: "Thể thao" },
        ]} style={{ marginBottom: 8 }}/>
        <ChipRow value="open" chips={[
          { value: "open", label: "🟢 Đang mở" },
          { value: "soon", label: "Sắp diễn ra" },
          { value: "team", label: "Theo nhóm" },
        ]} style={{ marginBottom: 14 }}/>

        {[
          { cat: "CNTT · Cá nhân", title: "PTIT Code Hunt 2026", desc: "Lập trình thuật toán cho SV năm 1-4", days: "5 ngày", count: "142/200", tone: "ok", icon: "code" },
          { cat: "Học thuật · Nhóm", title: "Hackathon Khởi nghiệp 2026", desc: "Đội 3-5 TV · Giải nhất 20tr", days: "1 ngày", count: "38 đội", tone: "warn", icon: "lightning" },
          { cat: "Văn nghệ", title: "Tiếng hát PTIT 2026", desc: "Vòng sơ loại · 15/05", days: "Sắp mở", count: "92 đăng ký", tone: "info", icon: "play" },
        ].map((c, i) => (
          <Card key={i} style={{ marginBottom: 10, padding: 0, overflow: "hidden" }}>
            <div style={{ padding: 14, display: "flex", gap: 12 }}>
              <div style={{
                width: 48, height: 48, borderRadius: 12,
                background: "var(--accent-soft)",
                display: "grid", placeItems: "center", flexShrink: 0,
              }}>
                <Icon name={c.icon} size={22} color="var(--accent)"/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 10.5, color: "var(--fg-muted)", textTransform: "uppercase", letterSpacing: "0.06em", fontWeight: 700, marginBottom: 3 }}>{c.cat}</div>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.015em", marginBottom: 4 }}>{c.title}</div>
                <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginBottom: 8 }}>{c.desc}</div>
                <div style={{ display: "flex", gap: 6 }}>
                  <Badge tone={c.tone} dot>{c.days}</Badge>
                  <Badge tone="neutral">{c.count}</Badge>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={SV_NAV} active="contests"/>
    </Phone>
  )},

  /* ───────── 07 Chi tiết cuộc thi ───────── */
  { id: "sv-07", label: "07 · Chi tiết cuộc thi", code: "SV5", w: 320, h: 660, render: () => (
    <Phone>
      <div style={{
        flexShrink: 0, height: 200, position: "relative",
        background: "linear-gradient(135deg, var(--brand-800) 0%, var(--brand-600) 100%)",
        padding: 18,
      }}>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <button style={{ width: 38, height: 38, borderRadius: 99, background: "rgba(255,255,255,0.18)", border: "none", color: "#fff", display: "grid", placeItems: "center" }}><Icon name="back" size={20}/></button>
          <div style={{ display: "flex", gap: 8 }}>
            <button style={{ width: 38, height: 38, borderRadius: 99, background: "rgba(255,255,255,0.18)", border: "none", color: "#fff", display: "grid", placeItems: "center" }}><Icon name="share" size={18}/></button>
            <button style={{ width: 38, height: 38, borderRadius: 99, background: "rgba(255,255,255,0.18)", border: "none", color: "#fff", display: "grid", placeItems: "center" }}><Icon name="heart" size={18}/></button>
          </div>
        </div>
        <div style={{ position: "absolute", left: 18, bottom: 16, color: "#fff" }}>
          <div style={{ fontSize: 11, opacity: 0.85, fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.08em" }}>CNTT · Cá nhân</div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.03em", marginTop: 4 }}>PTIT Code Hunt 2026</div>
        </div>
      </div>
      <Body padding={0} style={{ marginTop: -18, background: "var(--bg)", borderRadius: "20px 20px 0 0", paddingTop: 16 }}>
        <div style={{ padding: "0 16px" }}>
          <div style={{ display: "flex", gap: 6, marginBottom: 14 }}>
            <Badge tone="ok" dot>Đang mở</Badge>
            <Badge tone="neutral">⏰ Còn 5 ngày</Badge>
          </div>
          <div style={{ display: "flex", gap: 8, marginBottom: 18 }}>
            <Stat value="142" label="Thí sinh"/>
            <Stat value="3" label="Vòng thi"/>
            <Stat value="5tr" label="Giải nhất" tone="brand"/>
          </div>

          <Card style={{ marginBottom: 12 }}>
            <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 8 }}>Mô tả</div>
            <div style={{ fontSize: 12.5, color: "var(--fg-muted)", lineHeight: 1.6 }}>
              Cuộc thi lập trình thuật toán hàng năm dành cho sinh viên PTIT. 3 vòng: Sơ loại online, Bán kết, Chung kết. Áp dụng quy chế chấm ẩn danh.
            </div>
          </Card>

          <Card style={{ marginBottom: 12 }}>
            <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 12 }}>Lịch trình</div>
            <div style={{ paddingLeft: 16, position: "relative" }}>
              <div style={{ position: "absolute", left: 4, top: 4, bottom: 4, width: 1.5, background: "var(--border)" }}/>
              {[
                { state: "done", t: "Mở đăng ký", d: "01/05 — 08/05/2026", c: "var(--ok)" },
                { state: "active", t: "Vòng sơ loại (online)", d: "10/05 · 19:00–22:00", c: "var(--accent)" },
                { state: "next", t: "Bán kết", d: "15/05 · Hội trường A2", c: "var(--ink-300)" },
                { state: "next", t: "Chung kết · Trao giải", d: "22/05/2026", c: "var(--ink-300)" },
              ].map((it, i) => (
                <div key={i} style={{ marginBottom: i === 3 ? 0 : 12, position: "relative" }}>
                  <div style={{ position: "absolute", left: -16, top: 4, width: 9, height: 9, borderRadius: 99, background: it.c, border: "2px solid var(--bg-elev)" }}/>
                  <div style={{ fontSize: 12.5, fontWeight: 600, color: it.state === "next" ? "var(--fg-muted)" : "var(--fg)" }}>{it.t}</div>
                  <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 2 }}>{it.d}</div>
                </div>
              ))}
            </div>
          </Card>

          <Card style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 10 }}>Giải thưởng</div>
            {[
              { p: "Nhất", v: "5.000.000đ + Cup", c: "var(--accent)" },
              { p: "Nhì", v: "3.000.000đ", c: "var(--ink-500)" },
              { p: "Ba", v: "1.500.000đ + 5 KK", c: "var(--warn)" },
            ].map((p, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 0", borderBottom: i < 2 ? "1px solid var(--border)" : "none" }}>
                <div style={{ width: 28, height: 28, borderRadius: 99, background: "var(--accent-soft)", display: "grid", placeItems: "center", color: p.c }}><Icon name="trophy" size={14}/></div>
                <div style={{ flex: 1, fontSize: 12.5, fontWeight: 600 }}>{p.p}</div>
                <div style={{ fontSize: 12.5, fontWeight: 700, color: "var(--fg)" }}>{p.v}</div>
              </div>
            ))}
          </Card>
        </div>
        <div style={{ position: "sticky", bottom: 0, padding: 14, background: "var(--bg-elev)", borderTop: "1px solid var(--border)", display: "flex", gap: 8 }}>
          <Btn variant="outline" style={{ flex: 1 }}>Hỏi BTC</Btn>
          <Btn style={{ flex: 1.6 }}>Đăng ký ngay</Btn>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 08 Đăng ký dự thi ───────── */
  { id: "sv-08", label: "08 · Đăng ký dự thi", code: "SV6", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Đăng ký dự thi" subtitle="PTIT Code Hunt 2026"/>
      <Body>
        <div style={{ display: "flex", gap: 6, padding: 4, background: "var(--bg-sunken)", borderRadius: 13, border: "1px solid var(--border)", marginBottom: 14 }}>
          <button style={{ flex: 1, padding: 10, borderRadius: 10, background: "var(--accent)", color: "#fff", border: "none", fontSize: 12.5, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}>
            <Icon name="user" size={14}/> Cá nhân
          </button>
          <button style={{ flex: 1, padding: 10, borderRadius: 10, background: "transparent", color: "var(--fg-muted)", border: "none", fontSize: 12.5, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}>
            <Icon name="users" size={14}/> Nhóm
          </button>
        </div>
        <Card style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: "var(--fg-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 12 }}>Thí sinh</div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <Avatar name="An Nguyen" size={40}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600 }}>Nguyễn Văn An</div>
              <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2, fontFamily: "var(--font-mono)" }}>B21DCCN123 · CNTT · D21CN02</div>
            </div>
            <Badge tone="ok" dot>Verified</Badge>
          </div>
        </Card>
        <Field label="Lời giới thiệu (tuỳ chọn)">
          <div style={{ padding: 12, border: "1px solid var(--border)", borderRadius: 12, background: "var(--bg-elev)", fontSize: 13, color: "var(--fg)", minHeight: 70 }}>
            Sinh viên năm 3, đam mê thuật toán và competitive programming.
          </div>
        </Field>
        <Card style={{ background: "var(--warn-bg)", borderColor: "transparent", marginBottom: 14, padding: 12 }}>
          <div style={{ display: "flex", gap: 10 }}>
            <Icon name="info" size={16} color="var(--warn)" style={{ flexShrink: 0, marginTop: 2 }}/>
            <div style={{ fontSize: 11.5, color: "var(--warn)", lineHeight: 1.6 }}>
              <b>Điều kiện (SV_QĐ2):</b> Là SV PTIT đang theo học · GPA ≥ 2.0 · Chưa đạt giải nhất 2 năm liên tiếp.
            </div>
          </div>
        </Card>
        <label style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 12.5, marginBottom: 14, color: "var(--fg-muted)" }}>
          <span style={{ width: 18, height: 18, borderRadius: 5, background: "var(--accent)", display: "grid", placeItems: "center", flexShrink: 0 }}>
            <Icon name="check" size={12} color="#fff" strokeWidth={2.5}/>
          </span>
          Tôi đã đọc và đồng ý <a style={{ color: "var(--accent)", fontWeight: 600 }}>thể lệ cuộc thi</a>
        </label>
        <Btn full size="lg">Xác nhận đăng ký</Btn>
      </Body>
    </Phone>
  )},

  /* ───────── 09 Tạo nhóm ───────── */
  { id: "sv-09", label: "09 · Tạo nhóm", code: "SV6", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Tạo nhóm dự thi" subtitle="Hackathon Khởi nghiệp 2026"/>
      <Body>
        <Field label="Tên nhóm">
          <Input defaultValue="The Codebreakers"/>
        </Field>
        <SectionHead>Thành viên · 3/5</SectionHead>
        {[
          { name: "Nguyễn Văn An", code: "B21DCCN123", role: "Leader", status: null, color: "var(--accent)" },
          { name: "Trần Bảo Linh", code: "B21DCCN045 · ✓ Đã chấp nhận", role: null, status: "ok", color: "#0EA5E9" },
          { name: "Lê Minh Hoàng", code: "B21DCCN090 · ⏳ Chờ", role: null, status: "pend", color: "#16A34A" },
        ].map((m, i) => (
          <ListRow key={i}
            leading={<Avatar name={m.name} color={m.color} size={36}/>}
            title={m.name}
            subtitle={m.code}
            trailing={m.role ? <Badge tone="brand">👑 {m.role}</Badge> : <Icon name="close" size={16} color="var(--fg-faint)"/>}
            style={{ marginBottom: 8 }}
          />
        ))}
        <Card style={{ borderStyle: "dashed", borderColor: "var(--border-strong)", padding: 18, textAlign: "center", marginTop: 8, marginBottom: 14, cursor: "pointer" }}>
          <Icon name="plus" size={22} color="var(--accent)" style={{ marginBottom: 6 }}/>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Mời thành viên</div>
          <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 3 }}>Nhập MSSV hoặc email PTIT</div>
        </Card>
        <Card style={{ background: "var(--info-bg)", borderColor: "transparent", padding: 12, marginBottom: 14 }}>
          <div style={{ display: "flex", gap: 10 }}>
            <Icon name="info" size={16} color="var(--info)" style={{ flexShrink: 0, marginTop: 2 }}/>
            <div style={{ fontSize: 11.5, color: "var(--info)", lineHeight: 1.6 }}>
              Nhóm 3-5 TV, đều thuộc PTIT. Đăng ký hoàn tất khi mọi TV chấp nhận.
            </div>
          </div>
        </Card>
        <Btn full size="lg">Lưu & gửi lời mời</Btn>
      </Body>
    </Phone>
  )},

  /* ───────── 10 Nộp bài ───────── */
  { id: "sv-10", label: "10 · Nộp bài thi", code: "SV8", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Nộp bài" subtitle="Vòng sơ loại · Hạn 10/05 23:59"/>
      <Body>
        <Card style={{ background: "var(--accent-soft)", borderColor: "transparent", marginBottom: 14 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <div style={{ fontSize: 11, color: "var(--accent-soft-fg)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em" }}>Còn lại</div>
              <div style={{ fontSize: 22, fontWeight: 800, color: "var(--accent)", letterSpacing: "-0.025em", marginTop: 2, fontFamily: "var(--font-mono)" }}>02:14:32</div>
            </div>
            <Icon name="clock" size={32} color="var(--accent)"/>
          </div>
        </Card>
        <Field label="Tiêu đề">
          <Input defaultValue="Giải bài tập thuật toán - Round 1"/>
        </Field>
        <Field label="Mô tả ngắn">
          <div style={{ padding: 12, border: "1px solid var(--border)", borderRadius: 12, background: "var(--bg-elev)", fontSize: 13, minHeight: 50 }}>
            Lời giải sử dụng dynamic programming và segment tree.
          </div>
        </Field>
        <Field label="Tệp đính kèm">
          <div style={{ border: "1.5px dashed var(--border-strong)", borderRadius: 14, padding: "24px 16px", textAlign: "center", background: "var(--bg-sunken)" }}>
            <Icon name="upload" size={28} color="var(--accent)" style={{ marginBottom: 8 }}/>
            <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Bấm hoặc kéo file vào đây</div>
            <div style={{ fontSize: 11, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>PDF · DOCX · ZIP · max 50MB</div>
          </div>
        </Field>
        <ListRow
          leading={<IconTile name="doc" color="var(--err)" bg="var(--err-bg)" size={36}/>}
          title="solution.pdf"
          subtitle="2.4 MB · Đã upload"
          trailing={<Badge tone="ok" dot>OK</Badge>}
          style={{ marginBottom: 8 }}
        />
        <Card style={{ marginBottom: 14, padding: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <IconTile name="doc" color="var(--info)" bg="var(--info-bg)" size={36}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600 }}>source-code.zip</div>
              <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 2, fontFamily: "var(--font-mono)" }}>5.1 MB · uploading 78%</div>
              <div style={{ marginTop: 8 }}><Progress value={78}/></div>
            </div>
          </div>
        </Card>
        <div style={{ display: "flex", gap: 8 }}>
          <Btn variant="outline" style={{ flex: 1 }}>Lưu nháp</Btn>
          <Btn style={{ flex: 1.6 }}>Nộp bài</Btn>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 11 Cuộc thi của tôi ───────── */
  { id: "sv-11", label: "11 · Của tôi", code: "SV9", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Của tôi" subtitle="Lịch sử & cuộc thi đang tham gia" large/>
      <Body>
        <ChipRow value="all" chips={[
          { value: "all", label: "Tất cả · 10" },
          { value: "live", label: "Đang thi · 3" },
          { value: "done", label: "Đã xong · 7" },
        ]} style={{ marginBottom: 14 }}/>

        <Card style={{ marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
            <Badge tone="ok" dot>Đang diễn ra</Badge>
            <span style={{ fontSize: 11, color: "var(--fg-muted)" }}>5 ngày còn lại</span>
          </div>
          <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.02em", marginBottom: 4 }}>PTIT Code Hunt 2026</div>
          <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginBottom: 10 }}>Vòng sơ loại · hạn 10/05 23:59</div>
          <Progress value={35}/>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8 }}>
            <span style={{ fontSize: 11.5 }}>Trạng thái: <Badge tone="brand">SUBMITTED</Badge></span>
            <a style={{ fontSize: 12, color: "var(--accent)", fontWeight: 600 }}>Chi tiết ›</a>
          </div>
        </Card>

        <Card style={{ marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
            <Badge tone="info" dot>Sắp diễn ra</Badge>
            <span style={{ fontSize: 11, color: "var(--fg-muted)" }}>15/05/2026</span>
          </div>
          <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.02em", marginBottom: 4 }}>Hackathon Khởi nghiệp 2026</div>
          <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginBottom: 10 }}>Đội: The Codebreakers (3 TV)</div>
          <div style={{ display: "flex", gap: -6, marginBottom: 4 }}>
            {["AN","BL","MH"].map((n, i) => (
              <div key={i} style={{ marginLeft: i ? -8 : 0 }}><Avatar name={n} size={24}/></div>
            ))}
          </div>
        </Card>

        <Card>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
            <Badge tone="neutral">Đã hoàn thành</Badge>
            <span style={{ fontSize: 11, color: "var(--fg-muted)" }}>22/04/2026</span>
          </div>
          <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: "-0.02em", marginBottom: 4 }}>Tiếng Anh PTIT 2025</div>
          <div style={{ display: "flex", gap: 8, alignItems: "center", marginTop: 6 }}>
            <Badge tone="warn">🏅 Khuyến khích</Badge>
            <span style={{ fontSize: 12, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>82.5đ</span>
          </div>
        </Card>
      </Body>
      <NavBar items={SV_NAV} active="my"/>
    </Phone>
  )},

  /* ───────── 12 Leaderboard ───────── */
  { id: "sv-12", label: "12 · Bảng xếp hạng", code: "SV-LB", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Bảng xếp hạng" subtitle="PTIT Code Hunt · Vòng sơ loại"/>
      <Body padding={0}>
        <div style={{
          padding: "8px 16px 24px",
          background: "linear-gradient(180deg, var(--accent) 0%, var(--brand-700) 100%)",
        }}>
          <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "center", gap: 12, marginTop: 14 }}>
            {/* 2nd */}
            <div style={{ textAlign: "center" }}>
              <Avatar name="Trần Bảo" size={48} color="#0EA5E9"/>
              <div style={{ fontSize: 12, color: "#fff", fontWeight: 700, marginTop: 6 }}>Bảo Ngọc</div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.85)", fontFamily: "var(--font-mono)" }}>91.0</div>
              <div style={{ width: 64, height: 50, background: "rgba(255,255,255,0.2)", borderRadius: "10px 10px 0 0", marginTop: 6, display: "grid", placeItems: "center", color: "#fff", fontWeight: 800, fontSize: 18 }}>2</div>
            </div>
            {/* 1st */}
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 22 }}>👑</div>
              <Avatar name="Phan Tu" size={56} color="#EAB308"/>
              <div style={{ fontSize: 13, color: "#fff", fontWeight: 700, marginTop: 6 }}>Phan Minh Tú</div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.95)", fontFamily: "var(--font-mono)", fontWeight: 700 }}>94.5</div>
              <div style={{ width: 70, height: 76, background: "rgba(255,255,255,0.28)", borderRadius: "10px 10px 0 0", marginTop: 6, display: "grid", placeItems: "center", color: "#fff", fontWeight: 800, fontSize: 22 }}>1</div>
            </div>
            {/* 3rd */}
            <div style={{ textAlign: "center" }}>
              <Avatar name="Hoang Anh" size={44} color="#16A34A"/>
              <div style={{ fontSize: 12, color: "#fff", fontWeight: 700, marginTop: 6 }}>Đức Anh</div>
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.85)", fontFamily: "var(--font-mono)" }}>88.5</div>
              <div style={{ width: 60, height: 36, background: "rgba(255,255,255,0.16)", borderRadius: "10px 10px 0 0", marginTop: 6, display: "grid", placeItems: "center", color: "#fff", fontWeight: 800, fontSize: 16 }}>3</div>
            </div>
          </div>
        </div>
        <div style={{ padding: 14, background: "var(--bg)", borderRadius: "16px 16px 0 0", marginTop: -16, position: "relative" }}>
          {[
            { r: 4, n: "Lê Văn Khoa", c: "B21DCAT022", s: 86.5 },
            { r: 5, n: "Phạm Quỳnh", c: "B22DCCN144", s: 85.0 },
            { r: 6, n: "Đỗ Thanh Hà", c: "B21DCCN088", s: 84.5 },
            { r: 7, n: "Nguyễn Văn An (bạn)", c: "B21DCCN123", s: 82.5, me: true },
            { r: 8, n: "Vũ Đức Trí", c: "B22DCCN201", s: 81.0 },
          ].map(p => (
            <div key={p.r} style={{
              display: "flex", alignItems: "center", gap: 12,
              padding: "10px 12px", marginBottom: 6,
              borderRadius: 12,
              background: p.me ? "var(--accent-soft)" : "var(--bg-elev)",
              border: p.me ? "1.5px solid var(--accent)" : "1px solid var(--border)",
            }}>
              <div style={{ width: 22, fontSize: 13, fontWeight: 800, color: "var(--fg-muted)", fontFamily: "var(--font-mono)", textAlign: "center" }}>{p.r}</div>
              <Avatar name={p.n} size={30}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600, color: "var(--fg)" }}>{p.n}</div>
                <div style={{ fontSize: 10.5, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{p.c}</div>
              </div>
              <div style={{ fontSize: 13, fontWeight: 700, color: p.me ? "var(--accent)" : "var(--fg)", fontFamily: "var(--font-mono)" }}>{p.s}</div>
            </div>
          ))}
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 13 Notification ───────── */
  { id: "sv-13", label: "13 · Thông báo", code: "SV-N", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Thông báo" subtitle="3 chưa đọc" trailing={<IconBtn name="settings"/>} large/>
      <Body>
        <ChipRow value="all" chips={["Tất cả", "Cuộc thi", "Hệ thống", "Nhóm"]} style={{ marginBottom: 14 }}/>

        <SectionHead>Hôm nay</SectionHead>
        {[
          { icon: "trophy", color: "var(--accent)", bg: "var(--accent-soft)", t: "Kết quả vòng sơ loại đã công bố", s: "PTIT Code Hunt 2026 · bạn xếp hạng 7/87", time: "5 phút", unread: true },
          { icon: "users", color: "var(--info)", bg: "var(--info-bg)", t: "Lê Minh Hoàng đã chấp nhận lời mời", s: "Nhóm 'The Codebreakers'", time: "1 giờ", unread: true },
          { icon: "warn", color: "var(--warn)", bg: "var(--warn-bg)", t: "Hạn nộp bài còn 2 tiếng", s: "Vòng sơ loại Code Hunt", time: "2 giờ", unread: true },
        ].map((n, i) => (
          <Card key={i} style={{ marginBottom: 8, position: "relative", padding: 12 }}>
            {n.unread && <span style={{ position: "absolute", top: 14, right: 14, width: 8, height: 8, borderRadius: 99, background: "var(--accent)" }}/>}
            <div style={{ display: "flex", gap: 12 }}>
              <IconTile name={n.icon} color={n.color} bg={n.bg}/>
              <div style={{ flex: 1, minWidth: 0, paddingRight: 12 }}>
                <div style={{ fontSize: 13, fontWeight: 600, lineHeight: 1.4 }}>{n.t}</div>
                <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 3 }}>{n.s}</div>
                <div style={{ fontSize: 10.5, color: "var(--fg-faint)", marginTop: 4, fontFamily: "var(--font-mono)" }}>{n.time}</div>
              </div>
            </div>
          </Card>
        ))}

        <SectionHead style={{ marginTop: 14 }}>Tuần này</SectionHead>
        {[
          { icon: "cert", color: "var(--ok)", bg: "var(--ok-bg)", t: "Chứng nhận sẵn sàng", s: "Tiếng Anh PTIT 2025 · bấm để tải", time: "2 ngày" },
          { icon: "info", color: "var(--info)", bg: "var(--info-bg)", t: "Cập nhật phiên bản 2.4", s: "Cải thiện hiệu năng & sửa lỗi", time: "5 ngày" },
        ].map((n, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12, background: "var(--bg-sunken)" }}>
            <div style={{ display: "flex", gap: 12 }}>
              <IconTile name={n.icon} color={n.color} bg={n.bg}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{n.t}</div>
                <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 3 }}>{n.s}</div>
              </div>
              <span style={{ fontSize: 10.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>{n.time}</span>
            </div>
          </Card>
        ))}
      </Body>
      <NavBar items={SV_NAV} active="noti"/>
    </Phone>
  )},

  /* ───────── 14 Profile ───────── */
  { id: "sv-14", label: "14 · Profile", code: "SV-PF", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Tôi" trailing={<IconBtn name="settings"/>}/>
      <Body padding={0}>
        <div style={{ padding: "16px 16px 20px", textAlign: "center", background: "var(--bg-elev)", borderBottom: "1px solid var(--border)" }}>
          <Avatar name="An Nguyen" size={80} color="var(--accent)" style={{ margin: "0 auto", border: "3px solid var(--bg)" }}/>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: "-0.02em", marginTop: 12 }}>Nguyễn Văn An</div>
          <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 3, fontFamily: "var(--font-mono)" }}>B21DCCN123 · CNTT · D21CN02</div>
          <div style={{ display: "flex", gap: 24, justifyContent: "center", marginTop: 16 }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: "var(--accent)", letterSpacing: "-0.025em" }}>10</div>
              <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 1 }}>Cuộc thi</div>
            </div>
            <div style={{ width: 1, background: "var(--border)" }}/>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: "var(--accent)", letterSpacing: "-0.025em" }}>2</div>
              <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 1 }}>Giải thưởng</div>
            </div>
            <div style={{ width: 1, background: "var(--border)" }}/>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: "var(--accent)", letterSpacing: "-0.025em" }}>5</div>
              <div style={{ fontSize: 10.5, color: "var(--fg-muted)", marginTop: 1 }}>Chứng nhận</div>
            </div>
          </div>
        </div>
        <div style={{ padding: 16 }}>
          <SectionHead>Tài khoản</SectionHead>
          {[
            { icon: "user", t: "Hồ sơ cá nhân", s: "Họ tên, MSSV, lớp" },
            { icon: "lock", t: "Đổi mật khẩu", s: "Cập nhật bảo mật" },
            { icon: "bell", t: "Thông báo", s: "Email & in-app" },
            { icon: "globe", t: "Ngôn ngữ", s: "Tiếng Việt", trail: <Icon name="fwd" size={14} color="var(--fg-faint)"/> },
          ].map((it, i) => (
            <ListRow key={i}
              leading={<IconTile name={it.icon} color="var(--fg)" bg="var(--bg-sunken)" size={36}/>}
              title={it.t} subtitle={it.s}
              trailing={<Icon name="fwd" size={14} color="var(--fg-faint)"/>}
              style={{ marginBottom: 6 }}
            />
          ))}

          <SectionHead style={{ marginTop: 16 }}>Khác</SectionHead>
          {[
            { icon: "info", t: "Trợ giúp & FAQ" },
            { icon: "shield", t: "Quyền riêng tư" },
            { icon: "logout", t: "Đăng xuất", danger: true },
          ].map((it, i) => (
            <ListRow key={i}
              leading={<IconTile name={it.icon} color={it.danger ? "var(--err)" : "var(--fg)"} bg={it.danger ? "var(--err-bg)" : "var(--bg-sunken)"} size={36}/>}
              title={<span style={{ color: it.danger ? "var(--err)" : "var(--fg)" }}>{it.t}</span>}
              trailing={<Icon name="fwd" size={14} color="var(--fg-faint)"/>}
              style={{ marginBottom: 6 }}
            />
          ))}
          <div style={{ textAlign: "center", padding: "20px 0 8px", fontSize: 10.5, color: "var(--fg-faint)", fontFamily: "var(--font-mono)" }}>
            v2.4.1 · build 240501
          </div>
        </div>
      </Body>
      <NavBar items={SV_NAV} active="me"/>
    </Phone>
  )},

  /* ───────── 15 Certificate ───────── */
  { id: "sv-15", label: "15 · Chứng nhận", code: "SV-CT", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Chứng nhận" subtitle="Tiếng Anh PTIT 2025"/>
      <Body padding={0}>
        <div style={{ padding: 16, background: "var(--bg-sunken)" }}>
          <div style={{
            background: "linear-gradient(135deg, #fff 0%, var(--accent-soft) 100%)",
            border: "2px solid var(--accent)", borderRadius: 14,
            padding: "20px 18px", textAlign: "center",
            boxShadow: "var(--shadow-md)",
            color: "var(--ink-900)",
          }}>
            <div style={{ fontSize: 9, fontWeight: 700, color: "var(--accent)", letterSpacing: "0.12em", textTransform: "uppercase" }}>Học viện Công nghệ Bưu chính Viễn thông</div>
            <div style={{ width: 36, height: 1.5, background: "var(--accent)", margin: "8px auto 12px" }}/>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.04em", color: "var(--accent)", marginBottom: 8, fontFamily: "var(--font-display)" }}>CHỨNG NHẬN</div>
            <div style={{ fontSize: 11, color: "var(--ink-700)" }}>Chứng nhận sinh viên</div>
            <div style={{ fontSize: 14, fontWeight: 800, color: "var(--ink-900)", margin: "6px 0", letterSpacing: "-0.015em" }}>NGUYỄN VĂN AN</div>
            <div style={{ fontSize: 11, color: "var(--ink-700)" }}>đã đạt giải <b>Khuyến khích</b> cuộc thi</div>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: "var(--ink-900)", margin: "4px 0 12px" }}>Tiếng Anh PTIT 2025</div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 14 }}>
              <div style={{ width: 56, height: 56, padding: 4, background: "#fff", borderRadius: 8, border: "1px solid var(--ink-200)" }}>
                <svg viewBox="0 0 21 21" style={{ width: "100%", height: "100%" }}>
                  {Array.from({length: 21*21}).map((_, i) => {
                    const x = i % 21, y = Math.floor(i/21);
                    if ((x<7&&y<7)||(x>13&&y<7)||(x<7&&y>13)) return null;
                    if (((x*y+x+y)%3 === 0) || ((x+y)%5 === 0)) return <rect key={i} x={x} y={y} width="1" height="1" fill="#000"/>;
                    return null;
                  })}
                  <path d="M0 0h7v7H0V0zm1 1v5h5V1H1zm1 1h3v3H2V2z" fill="#000"/>
                  <path d="M14 0h7v7h-7V0zm1 1v5h5V1h-5zm1 1h3v3h-3V2z" fill="#000"/>
                  <path d="M0 14h7v7H0v-7zm1 1v5h5v-5H1zm1 1h3v3H2v-3z" fill="#000"/>
                </svg>
              </div>
              <div style={{ textAlign: "center", fontSize: 9, color: "var(--ink-700)" }}>
                <div style={{ height: 22, marginBottom: 2, fontFamily: "Brush Script MT, cursive", fontSize: 14, color: "var(--accent)" }}>Phan Đăng Hưng</div>
                <div style={{ borderTop: "1px solid var(--ink-300)", paddingTop: 2, fontWeight: 600 }}>PGS. Phan Đăng Hưng</div>
                <div style={{ marginTop: 1 }}>BCN Khoa CNTT</div>
              </div>
            </div>
          </div>
          <div style={{ marginTop: 12, padding: 12, background: "var(--bg-elev)", border: "1px solid var(--border)", borderRadius: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11.5, marginBottom: 5 }}>
              <span style={{ color: "var(--fg-muted)" }}>Mã chứng nhận</span>
              <span style={{ fontWeight: 600, fontFamily: "var(--font-mono)" }}>PTIT-EN-2025-1042</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11.5, marginBottom: 5 }}>
              <span style={{ color: "var(--fg-muted)" }}>Ngày cấp</span>
              <span style={{ fontWeight: 600 }}>22/04/2026</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11.5 }}>
              <span style={{ color: "var(--fg-muted)" }}>Trạng thái</span>
              <Badge tone="ok" dot>Đã ký số</Badge>
            </div>
          </div>
        </div>
        <div style={{ position: "sticky", bottom: 0, padding: 14, background: "var(--bg-elev)", borderTop: "1px solid var(--border)", display: "flex", gap: 8 }}>
          <Btn variant="outline" icon="share" style={{ flex: 1 }}>Chia sẻ</Btn>
          <Btn icon="download" style={{ flex: 1 }}>Tải PDF</Btn>
        </div>
      </Body>
    </Phone>
  )},

  /* ───────── 16 Đánh giá ───────── */
  { id: "sv-16", label: "16 · Đánh giá", code: "SV-RT", w: 320, h: 660, render: () => (
    <Phone>
      <AppBar title="Đánh giá cuộc thi" subtitle="Tiếng Anh PTIT 2025"/>
      <Body>
        <div style={{ textAlign: "center", padding: "12px 0 18px" }}>
          <Avatar name="EN" size={64} color="var(--info)" style={{ margin: "0 auto 12px", borderRadius: 16 }}/>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: "-0.02em" }}>Trải nghiệm của bạn?</div>
          <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 4 }}>Phản hồi giúp BTC tổ chức tốt hơn</div>
        </div>
        <div style={{ display: "flex", justifyContent: "center", gap: 8, marginBottom: 24 }}>
          {[1,2,3,4,5].map(n => (
            <Icon key={n} name="star" size={36} color={n <= 4 ? "#F59E0B" : "var(--ink-300)"} strokeWidth={1.4} style={{ fill: n <= 4 ? "#F59E0B" : "transparent" }}/>
          ))}
        </div>
        <SectionHead>Tiêu chí</SectionHead>
        {[
          { t: "Tổ chức chuyên nghiệp", v: 4 },
          { t: "Đề thi chất lượng", v: 5 },
          { t: "Hỗ trợ BTC", v: 4 },
          { t: "Phần thưởng & ghi nhận", v: 3 },
        ].map((c, i) => (
          <Card key={i} style={{ marginBottom: 8, padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
              <span style={{ fontSize: 12.5, fontWeight: 600 }}>{c.t}</span>
              <span style={{ fontSize: 11, color: "var(--fg-muted)", fontFamily: "var(--font-mono)" }}>{c.v}/5</span>
            </div>
            <div style={{ display: "flex", gap: 4 }}>
              {[1,2,3,4,5].map(n => (
                <div key={n} style={{
                  flex: 1, height: 6, borderRadius: 3,
                  background: n <= c.v ? "var(--accent)" : "var(--ink-150)",
                }}/>
              ))}
            </div>
          </Card>
        ))}
        <Field label="Nhận xét (tuỳ chọn)">
          <div style={{ padding: 12, border: "1px solid var(--border)", borderRadius: 12, background: "var(--bg-elev)", fontSize: 12.5, color: "var(--fg-muted)", minHeight: 70, fontStyle: "italic" }}>
            Cuộc thi rất hay, đề ra sát thực tế. Mong BTC có thêm vòng phỏng vấn...
          </div>
        </Field>
        <Btn full size="lg">Gửi phản hồi</Btn>
      </Body>
    </Phone>
  )},
];

window.SV_SCREENS = sv_screens;
