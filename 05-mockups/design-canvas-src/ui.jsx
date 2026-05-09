/* global React */
// ============================================================
// PTIT CONTEST — UI PRIMITIVES
// Plus Jakarta Sans · oklch palette · Linear/Notion-flavored
// ============================================================

const { useState } = React;

/* ───────── Icon — line-style, 1.5 stroke. Curated set ───────── */
function Icon({ name, size = 20, color = "currentColor", strokeWidth = 1.6, style }) {
  const s = size;
  const sw = strokeWidth;
  const props = {
    width: s, height: s, viewBox: "0 0 24 24",
    fill: "none", stroke: color, strokeWidth: sw,
    strokeLinecap: "round", strokeLinejoin: "round", style,
  };
  switch (name) {
    case "home": return <svg {...props}><path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/></svg>;
    case "trophy": return <svg {...props}><path d="M8 4h8v6a4 4 0 01-8 0V4z"/><path d="M16 6h3v3a3 3 0 01-3 3"/><path d="M8 6H5v3a3 3 0 003 3"/><path d="M9 19h6M10 15h4l1 4H9l1-4z"/></svg>;
    case "list": return <svg {...props}><path d="M8 6h13M8 12h13M8 18h13"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/></svg>;
    case "bell": return <svg {...props}><path d="M6 8a6 6 0 1112 0c0 7 3 8 3 8H3s3-1 3-8z"/><path d="M10 21a2 2 0 004 0"/></svg>;
    case "user": return <svg {...props}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0116 0"/></svg>;
    case "search": return <svg {...props}><circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/></svg>;
    case "back": return <svg {...props}><path d="M15 6l-6 6 6 6"/></svg>;
    case "fwd": return <svg {...props}><path d="M9 6l6 6-6 6"/></svg>;
    case "close": return <svg {...props}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case "menu": return <svg {...props}><path d="M3 6h18M3 12h18M3 18h18"/></svg>;
    case "more": return <svg {...props}><circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/></svg>;
    case "more-v": return <svg {...props}><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>;
    case "filter": return <svg {...props}><path d="M3 5h18M6 12h12M10 19h4"/></svg>;
    case "calendar": return <svg {...props}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case "clock": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case "users": return <svg {...props}><circle cx="9" cy="8" r="3.5"/><path d="M3 20a6 6 0 0112 0"/><path d="M16 11a3 3 0 100-6"/><path d="M21 20a5 5 0 00-5-5"/></svg>;
    case "check": return <svg {...props}><path d="M5 12l5 5 9-11"/></svg>;
    case "check-circle": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/></svg>;
    case "x-circle": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/></svg>;
    case "info": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M12 8v.01M11 12h1v5h1"/></svg>;
    case "warn": return <svg {...props}><path d="M12 3l10 17H2L12 3z"/><path d="M12 10v4M12 17v.01"/></svg>;
    case "upload": return <svg {...props}><path d="M12 16V4M7 9l5-5 5 5"/><path d="M5 18h14v3H5z"/></svg>;
    case "download": return <svg {...props}><path d="M12 4v12M7 11l5 5 5-5"/><path d="M5 20h14"/></svg>;
    case "doc": return <svg {...props}><path d="M14 3H6v18h12V7l-4-4z"/><path d="M14 3v4h4"/><path d="M9 13h6M9 17h4"/></svg>;
    case "image": return <svg {...props}><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 17l-5-5-9 9"/></svg>;
    case "qr": return <svg {...props}><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3M21 14v7M17 17v4"/></svg>;
    case "shield": return <svg {...props}><path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6l8-3z"/></svg>;
    case "settings": return <svg {...props}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.4 1.9l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.9-.4 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.9.4l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.4-1.9 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1A1.7 1.7 0 004.6 9a1.7 1.7 0 00-.4-1.9l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.9.4H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.9-.4l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.4 1.9V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>;
    case "logout": return <svg {...props}><path d="M9 4H5v16h4"/><path d="M16 16l4-4-4-4M20 12H10"/></svg>;
    case "edit": return <svg {...props}><path d="M4 20h4l11-11-4-4L4 16v4z"/></svg>;
    case "plus": return <svg {...props}><path d="M12 5v14M5 12h14"/></svg>;
    case "star": return <svg {...props}><path d="M12 3l3 6 6 1-4.5 4.5 1 6.5L12 17l-5.5 4 1-6.5L3 10l6-1 3-6z"/></svg>;
    case "heart": return <svg {...props}><path d="M12 21s-7-4.5-9-9C1.5 8 4 4.5 7.5 4.5c2 0 3.5 1 4.5 2.5 1-1.5 2.5-2.5 4.5-2.5 3.5 0 6 3.5 4.5 7.5-2 4.5-9 9-9 9z"/></svg>;
    case "share": return <svg {...props}><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M8 11l8-4M8 13l8 4"/></svg>;
    case "chart": return <svg {...props}><path d="M3 21V3M3 21h18"/><rect x="7" y="13" width="3" height="6"/><rect x="13" y="9" width="3" height="10"/><rect x="19" y="6" width="2" height="13"/></svg>;
    case "graduate": return <svg {...props}><path d="M12 4L2 9l10 5 10-5-10-5z"/><path d="M6 11v5c0 2 3 3 6 3s6-1 6-3v-5"/></svg>;
    case "code": return <svg {...props}><path d="M8 8l-5 4 5 4M16 8l5 4-5 4M14 5l-4 14"/></svg>;
    case "mail": return <svg {...props}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 7 9-7"/></svg>;
    case "lock": return <svg {...props}><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/></svg>;
    case "eye": return <svg {...props}><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>;
    case "play": return <svg {...props}><path d="M7 4l13 8-13 8V4z"/></svg>;
    case "pin": return <svg {...props}><path d="M12 22s7-7.5 7-13a7 7 0 10-14 0c0 5.5 7 13 7 13z"/><circle cx="12" cy="9" r="2.5"/></svg>;
    case "trend": return <svg {...props}><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></svg>;
    case "approve": return <svg {...props}><path d="M21 11.5a8.5 8.5 0 11-9-8.5"/><path d="M9 11l3 3 9-9"/></svg>;
    case "watch": return <svg {...props}><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/></svg>;
    case "cert": return <svg {...props}><circle cx="12" cy="9" r="5"/><path d="M9 13l-2 8 5-3 5 3-2-8"/></svg>;
    case "db": return <svg {...props}><ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/><path d="M4 11v7c0 1.7 3.6 3 8 3s8-1.3 8-3v-7"/></svg>;
    case "server": return <svg {...props}><rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><circle cx="7" cy="7.5" r=".5"/><circle cx="7" cy="16.5" r=".5"/></svg>;
    case "logs": return <svg {...props}><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M7 8h10M7 12h10M7 16h6"/></svg>;
    case "send": return <svg {...props}><path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z"/></svg>;
    case "sparkle": return <svg {...props}><path d="M12 3v6M12 15v6M3 12h6M15 12h6M5 5l4 4M15 15l4 4M19 5l-4 4M9 15l-4 4"/></svg>;
    case "globe": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 010 18M12 3a14 14 0 000 18"/></svg>;
    case "wallet": return <svg {...props}><rect x="3" y="6" width="18" height="14" rx="2"/><path d="M3 10h18M16 14h2"/></svg>;
    case "team": return <svg {...props}><circle cx="9" cy="9" r="3"/><circle cx="17" cy="10" r="2.5"/><path d="M3 20a6 6 0 0112 0"/><path d="M21 19a4 4 0 00-7-2.6"/></svg>;
    case "flag": return <svg {...props}><path d="M5 21V4M5 4h12l-2 4 2 4H5"/></svg>;
    case "exclam": return <svg {...props}><circle cx="12" cy="12" r="9"/><path d="M12 7v6M12 16v.01"/></svg>;
    case "compose": return <svg {...props}><path d="M4 20h4l11-11-4-4L4 16v4z"/><path d="M14 5l4 4"/></svg>;
    case "lightning": return <svg {...props}><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/></svg>;
    default: return <svg {...props}><circle cx="12" cy="12" r="6"/></svg>;
  }
}

/* ───────── Badge ───────── */
function Badge({ tone = "neutral", children, dot = false, style }) {
  const tones = {
    neutral: { bg: "var(--ink-100)", fg: "var(--ink-700)", dot: "var(--ink-500)" },
    brand:   { bg: "var(--accent-soft)", fg: "var(--accent-soft-fg)", dot: "var(--brand-600)" },
    ok:      { bg: "var(--ok-bg)", fg: "var(--ok)", dot: "var(--ok)" },
    warn:    { bg: "var(--warn-bg)", fg: "var(--warn)", dot: "var(--warn)" },
    info:    { bg: "var(--info-bg)", fg: "var(--info)", dot: "var(--info)" },
    err:     { bg: "var(--err-bg)", fg: "var(--err)", dot: "var(--err)" },
    outline: { bg: "transparent", fg: "var(--fg-muted)", dot: "var(--ink-400)", border: "1px solid var(--border)" },
  };
  const t = tones[tone] || tones.neutral;
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 6,
      padding: "3px 9px", borderRadius: 999,
      background: t.bg, color: t.fg, border: t.border || "none",
      fontSize: 11, fontWeight: 600, letterSpacing: "-0.005em",
      lineHeight: 1.4, ...style,
    }}>
      {dot && <span style={{ width: 6, height: 6, borderRadius: 99, background: t.dot }}/>}
      {children}
    </span>
  );
}

/* ───────── Card ───────── */
function Card({ children, style, padding = 14, elevated = false, onClick }) {
  return (
    <div onClick={onClick} style={{
      background: "var(--bg-elev)",
      border: "1px solid var(--border)",
      borderRadius: 16,
      padding,
      boxShadow: elevated ? "var(--shadow-md)" : "var(--shadow-xs)",
      cursor: onClick ? "pointer" : "default",
      ...style,
    }}>{children}</div>
  );
}

/* ───────── Button ───────── */
function Btn({ variant = "primary", size = "md", children, icon, full, style, ...rest }) {
  const sizes = {
    sm: { padding: "8px 12px", fontSize: 12, h: 34, r: 10 },
    md: { padding: "11px 16px", fontSize: 13.5, h: 42, r: 12 },
    lg: { padding: "13px 18px", fontSize: 14, h: 48, r: 14 },
  };
  const s = sizes[size];
  const variants = {
    primary: { bg: "var(--accent)", fg: "var(--accent-fg)", border: "1px solid var(--accent)" },
    secondary: { bg: "var(--bg-sunken)", fg: "var(--fg)", border: "1px solid var(--border)" },
    ghost: { bg: "transparent", fg: "var(--fg)", border: "1px solid transparent" },
    outline: { bg: "var(--bg-elev)", fg: "var(--fg)", border: "1px solid var(--border-strong)" },
    danger: { bg: "var(--err-bg)", fg: "var(--err)", border: "1px solid transparent" },
  };
  const v = variants[variant];
  return (
    <button {...rest} style={{
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
      height: s.h, padding: s.padding, fontSize: s.fontSize,
      borderRadius: s.r, fontWeight: 600,
      background: v.bg, color: v.fg, border: v.border,
      cursor: "pointer", letterSpacing: "-0.01em",
      width: full ? "100%" : undefined, ...style,
    }}>
      {icon && <Icon name={icon} size={size === "sm" ? 14 : 16}/>}
      {children}
    </button>
  );
}

/* ───────── Input ───────── */
function Field({ label, hint, children }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && <div style={{ fontSize: 12, fontWeight: 600, color: "var(--fg-muted)", marginBottom: 6 }}>{label}</div>}
      {children}
      {hint && <div style={{ fontSize: 11, color: "var(--fg-faint)", marginTop: 6 }}>{hint}</div>}
    </div>
  );
}
function Input({ icon, ...rest }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 10,
      padding: "12px 14px", border: "1px solid var(--border)",
      borderRadius: 12, background: "var(--bg-elev)",
    }}>
      {icon && <Icon name={icon} size={16} color="var(--fg-faint)"/>}
      <input {...rest} style={{
        flex: 1, border: "none", outline: "none", background: "transparent",
        fontSize: 14, color: "var(--fg)", letterSpacing: "-0.005em",
      }}/>
    </div>
  );
}

/* ───────── Avatar ───────── */
function Avatar({ name = "?", size = 36, color, src, style }) {
  const initials = name.split(" ").map(s=>s[0]).slice(-2).join("").toUpperCase();
  const palette = ["#C8102E", "#7C3AED", "#0EA5E9", "#16A34A", "#EA580C", "#DB2777"];
  const bg = color || palette[name.charCodeAt(0) % palette.length];
  return (
    <div style={{
      width: size, height: size, borderRadius: 99,
      background: src ? `center/cover url(${src})` : bg, color: "#fff",
      display: "grid", placeItems: "center",
      fontWeight: 700, fontSize: size * 0.36, letterSpacing: "-0.02em",
      flexShrink: 0, ...style,
    }}>{!src && initials}</div>
  );
}

/* ───────── Segmented control ───────── */
function Segmented({ value, onChange, options }) {
  return (
    <div style={{
      display: "inline-flex", padding: 3, gap: 2,
      background: "var(--bg-sunken)", borderRadius: 11,
      border: "1px solid var(--border)",
    }}>
      {options.map(o => (
        <button key={o.value} onClick={()=>onChange?.(o.value)} style={{
          padding: "7px 14px", fontSize: 12.5, fontWeight: 600,
          borderRadius: 8, border: "none", cursor: "pointer",
          background: value === o.value ? "var(--bg-elev)" : "transparent",
          color: value === o.value ? "var(--fg)" : "var(--fg-muted)",
          boxShadow: value === o.value ? "var(--shadow-xs)" : "none",
          letterSpacing: "-0.005em",
        }}>{o.label}</button>
      ))}
    </div>
  );
}

/* ───────── Status bar (Android punch-hole) ───────── */
function StatusBar({ dark }) {
  const c = dark ? "rgba(255,255,255,.92)" : "var(--fg)";
  return (
    <div style={{
      height: 36, display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "0 18px", flexShrink: 0, position: "relative",
    }}>
      <span style={{ fontSize: 13, fontWeight: 600, color: c, letterSpacing: "-0.01em" }}>9:41</span>
      <div style={{
        position: "absolute", top: 8, left: "50%", transform: "translateX(-50%)",
        width: 22, height: 22, borderRadius: 99, background: "#0a0a0a",
      }}/>
      <div style={{ display: "flex", alignItems: "center", gap: 5, color: c }}>
        <svg width="14" height="14" viewBox="0 0 16 16"><path d="M2 11h2v3H2zM6 8h2v6H6zM10 5h2v9h-2zM14 2h2v12h-2z" fill={c}/></svg>
        <svg width="13" height="13" viewBox="0 0 16 16"><path d="M8 13.3L.7 6a10.4 10.4 0 0114.6 0L8 13.3z" fill={c}/></svg>
        <svg width="20" height="12" viewBox="0 0 22 12"><rect x="1" y="2" width="18" height="8" rx="2.5" stroke={c} fill="none"/><rect x="3" y="4" width="14" height="4" rx="1" fill={c}/><rect x="20" y="4.5" width="1.5" height="3" rx="0.5" fill={c}/></svg>
      </div>
    </div>
  );
}

/* ───────── Bottom nav ───────── */
function NavBar({ items, active, dark }) {
  return (
    <div style={{
      flexShrink: 0, padding: "8px 8px 12px",
      background: "var(--bg-elev)", borderTop: "1px solid var(--border)",
      display: "flex", justifyContent: "space-around",
    }}>
      {items.map(it => {
        const isActive = it.key === active;
        return (
          <button key={it.key} style={{
            display: "flex", flexDirection: "column", alignItems: "center", gap: 3,
            padding: "6px 8px", border: "none", background: "transparent",
            color: isActive ? "var(--accent)" : "var(--fg-muted)",
            fontSize: 10.5, fontWeight: 600, letterSpacing: "-0.005em",
            cursor: "pointer",
          }}>
            <div style={{
              width: 56, height: 28, borderRadius: 99,
              background: isActive ? "var(--accent-soft)" : "transparent",
              display: "grid", placeItems: "center",
            }}>
              <Icon name={it.icon} size={20}/>
            </div>
            <span>{it.label}</span>
          </button>
        );
      })}
      <div style={{ position: "absolute", bottom: 5, left: "50%", transform: "translateX(-50%)",
        width: 110, height: 4, borderRadius: 2, background: "var(--ink-400)", opacity: 0.5 }}/>
    </div>
  );
}

/* ───────── Top app bar ───────── */
function AppBar({ title, subtitle, leading = "back", trailing, dense = false, accent = false, large = false }) {
  return (
    <div style={{
      flexShrink: 0,
      background: accent ? "var(--accent)" : "var(--bg-elev)",
      color: accent ? "#fff" : "var(--fg)",
      padding: large ? "8px 16px 18px" : (dense ? "10px 12px" : "12px 14px"),
      borderBottom: accent ? "none" : "1px solid var(--border)",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, minHeight: 40 }}>
        {leading && (
          <button style={{
            width: 38, height: 38, borderRadius: 99, border: "none",
            background: "transparent", color: "inherit", cursor: "pointer",
            display: "grid", placeItems: "center",
          }}><Icon name={leading} size={20}/></button>
        )}
        {!large && (
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: "-0.015em" }}>{title}</div>
            {subtitle && <div style={{ fontSize: 11.5, opacity: 0.7, marginTop: 1 }}>{subtitle}</div>}
          </div>
        )}
        {large && <div style={{ flex: 1 }}/>}
        {trailing}
      </div>
      {large && (
        <div style={{ padding: "8px 6px 0", fontSize: 26, fontWeight: 700, letterSpacing: "-0.025em" }}>
          {title}
          {subtitle && <div style={{ fontSize: 12.5, opacity: 0.7, fontWeight: 500, marginTop: 4, letterSpacing: "-0.005em" }}>{subtitle}</div>}
        </div>
      )}
    </div>
  );
}
function IconBtn({ name, accent, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 38, height: 38, borderRadius: 99, border: "none",
      background: "transparent", color: "inherit", cursor: "pointer",
      display: "grid", placeItems: "center",
    }}><Icon name={name} size={20}/></button>
  );
}

/* ───────── Dark mode toggle nhỏ — dùng trong AppBar trailing ───────── */
function DarkModeBtn() {
  const [isDark, setIsDark] = React.useState(
    typeof document !== "undefined" && document.body.dataset.theme === "dark"
  );
  React.useEffect(() => {
    const sync = () => setIsDark(document.body.dataset.theme === "dark");
    const obs = new MutationObserver(sync);
    obs.observe(document.body, { attributes: true, attributeFilter: ["data-theme"] });
    return () => obs.disconnect();
  }, []);
  const toggle = () => {
    const next = !isDark;
    if (window.__setTweak) window.__setTweak("darkMode", next);
    else document.body.dataset.theme = next ? "dark" : "light";
  };
  return (
    <button
      onClick={toggle}
      title={isDark ? "Chuyển sáng" : "Chuyển tối"}
      aria-label="Bật/tắt chế độ tối"
      style={{
        width: 36, height: 36, borderRadius: 99,
        border: "1px solid var(--border)",
        background: "var(--bg-elev)",
        color: "var(--fg)",
        cursor: "pointer",
        display: "grid", placeItems: "center",
        fontSize: 15,
        boxShadow: "var(--shadow-xs)",
      }}
    >{isDark ? "☀" : "🌙"}</button>
  );
}

/* ───────── Phone shell ───────── */
function Phone({ children, dark = false, width = 320, height = 660 }) {
  return (
    <div className="phone-skin" data-theme={dark ? "dark" : "light"} style={{
      width, height,
      borderRadius: 38, overflow: "hidden",
      background: "var(--bg)",
      border: "8px solid #1a1a1a",
      boxShadow: "0 30px 80px rgba(0,0,0,0.18), 0 0 0 1.5px rgba(0,0,0,0.4)",
      display: "flex", flexDirection: "column", position: "relative",
    }}>
      <StatusBar dark={dark}/>
      <div style={{ flex: 1, overflow: "hidden", display: "flex", flexDirection: "column", background: "var(--bg)" }}>
        {children}
      </div>
      <div style={{ position: "absolute", bottom: 4, left: "50%", transform: "translateX(-50%)",
        width: 110, height: 4, borderRadius: 2, background: "var(--ink-400)", opacity: 0.45, zIndex: 5 }}/>
    </div>
  );
}

/* ───────── Body wrapper ───────── */
function Body({ children, padding = 14, style }) {
  return (
    <div style={{
      flex: 1, overflowY: "auto", overflowX: "hidden",
      padding, background: "var(--bg)", ...style,
    }}>{children}</div>
  );
}

/* ───────── Section heading ───────── */
function SectionHead({ children, action, style }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      marginBottom: 10, marginTop: 4,
      fontSize: 12, fontWeight: 700, color: "var(--fg)",
      textTransform: "uppercase", letterSpacing: "0.06em", ...style,
    }}>
      <span>{children}</span>
      {action && <span style={{ fontSize: 11.5, color: "var(--accent)", textTransform: "none", letterSpacing: 0, fontWeight: 600 }}>{action}</span>}
    </div>
  );
}

/* ───────── Chip row ───────── */
function ChipRow({ chips, value, onChange, scrollable = true, style }) {
  return (
    <div style={{
      display: "flex", gap: 6,
      overflowX: scrollable ? "auto" : "visible",
      paddingBottom: 4, ...style,
    }}>
      {chips.map(c => {
        const k = typeof c === "string" ? c : c.value;
        const lbl = typeof c === "string" ? c : c.label;
        const active = value === k;
        return (
          <button key={k} onClick={()=>onChange?.(k)} style={{
            flexShrink: 0, padding: "7px 13px",
            borderRadius: 99, fontSize: 12, fontWeight: 600, letterSpacing: "-0.005em",
            border: `1px solid ${active ? "var(--accent)" : "var(--border)"}`,
            background: active ? "var(--accent)" : "var(--bg-elev)",
            color: active ? "var(--accent-fg)" : "var(--fg-muted)",
            cursor: "pointer",
          }}>{lbl}</button>
        );
      })}
    </div>
  );
}

/* ───────── Progress bar ───────── */
function Progress({ value = 0, color = "var(--accent)", thickness = 6 }) {
  return (
    <div style={{ width: "100%", height: thickness, background: "var(--ink-150)", borderRadius: 99, overflow: "hidden" }}>
      <div style={{ width: `${Math.min(100, Math.max(0, value))}%`, height: "100%", background: color, borderRadius: 99 }}/>
    </div>
  );
}

/* ───────── Stat card ───────── */
function Stat({ value, label, tone = "neutral", icon }) {
  const tones = {
    neutral: { bg: "var(--bg-elev)", fg: "var(--fg)" },
    brand:   { bg: "var(--accent-soft)", fg: "var(--accent-soft-fg)" },
    ok:      { bg: "var(--ok-bg)", fg: "var(--ok)" },
    warn:    { bg: "var(--warn-bg)", fg: "var(--warn)" },
    info:    { bg: "var(--info-bg)", fg: "var(--info)" },
  };
  const t = tones[tone];
  return (
    <div style={{
      flex: 1, minWidth: 0,
      background: t.bg,
      border: "1px solid var(--border)",
      borderRadius: 14, padding: "10px 12px",
    }}>
      {icon && <Icon name={icon} size={14} color={t.fg} style={{ opacity: 0.7, marginBottom: 4 }}/>}
      <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.025em", color: t.fg, lineHeight: 1.05 }}>{value}</div>
      <div style={{ fontSize: 11, color: "var(--fg-muted)", marginTop: 2, fontWeight: 500 }}>{label}</div>
    </div>
  );
}

/* ───────── List item ───────── */
function ListRow({ leading, title, subtitle, trailing, dense = false, onClick, style }) {
  return (
    <div onClick={onClick} style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: dense ? "8px 10px" : "12px",
      background: "var(--bg-elev)", border: "1px solid var(--border)",
      borderRadius: 14, cursor: onClick ? "pointer" : "default",
      ...style,
    }}>
      {leading}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, letterSpacing: "-0.01em", color: "var(--fg)" }}>{title}</div>
        {subtitle && <div style={{ fontSize: 11.5, color: "var(--fg-muted)", marginTop: 2 }}>{subtitle}</div>}
      </div>
      {trailing}
    </div>
  );
}

/* ───────── Soft icon tile ───────── */
function IconTile({ name, color = "var(--accent)", bg = "var(--accent-soft)", size = 38 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 12, background: bg,
      display: "grid", placeItems: "center", flexShrink: 0,
    }}><Icon name={name} size={size * 0.5} color={color}/></div>
  );
}

/* ───────── Screen meta wrapper for canvas labels ───────── */
function ScreenMeta({ code, type, children }) { return children; }

Object.assign(window, {
  Icon, Badge, Card, Btn, Field, Input, Avatar, Segmented,
  StatusBar, NavBar, AppBar, IconBtn, DarkModeBtn, Phone, Body,
  SectionHead, ChipRow, Progress, Stat, ListRow, IconTile, ScreenMeta,
});
