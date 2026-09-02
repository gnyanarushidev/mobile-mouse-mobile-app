import { Link, useLocation } from "react-router-dom";
import { useState } from "react";

const links = [
  { to: "/", label: "Home" },
  { to: "/docs", label: "Documentation" },
  { to: "/privacy-policy", label: "Privacy Policy" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const location = useLocation();

  return (
    <nav style={styles.nav}>
      <div className="container" style={styles.inner}>
        <Link to="/" style={styles.brand}>
          <span style={styles.brandIcon}>🖱️</span>
          <span style={styles.brandText}>Mobile Mouse</span>
        </Link>

        <div style={styles.links}>
          {links.map((l) => (
            <Link
              key={l.to}
              to={l.to}
              style={{
                ...styles.link,
                ...(location.pathname === l.to ? styles.linkActive : {}),
              }}
            >
              {l.label}
            </Link>
          ))}
          <Link to="/" style={styles.cta}>
            Get Started
          </Link>
        </div>

        <button style={styles.hamburger} onClick={() => setOpen(!open)}>
          <span style={styles.bar(open, 0)} />
          <span style={styles.bar(open, 1)} />
          <span style={styles.bar(open, 2)} />
        </button>
      </div>

      {open && (
        <div style={styles.mobileMenu}>
          {links.map((l) => (
            <Link
              key={l.to}
              to={l.to}
              style={styles.mobileLink}
              onClick={() => setOpen(false)}
            >
              {l.label}
            </Link>
          ))}
          <Link
            to="/"
            style={styles.mobileCta}
            onClick={() => setOpen(false)}
          >
            Get Started
          </Link>
        </div>
      )}
    </nav>
  );
}

const styles = {
  nav: {
    background: "rgba(255,255,255,0.92)",
    backdropFilter: "blur(16px)",
    borderBottom: "1px solid rgba(0,0,0,0.06)",
    position: "sticky",
    top: 0,
    zIndex: 50,
  },
  inner: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    height: 64,
  },
  brand: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    fontSize: "1.25rem",
    fontWeight: 800,
    color: "#0F172A",
    textDecoration: "none",
  },
  brandIcon: { fontSize: "1.5rem" },
  brandText: {
    background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
    backgroundClip: "text",
  },
  links: {
    display: "flex",
    alignItems: "center",
    gap: 32,
  },
  link: {
    fontSize: "0.95rem",
    fontWeight: 500,
    color: "#64748B",
    textDecoration: "none",
    transition: "color 0.2s",
  },
  linkActive: {
    color: "#4F46E5",
    fontWeight: 600,
  },
  cta: {
    padding: "10px 22px",
    background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
    color: "#fff",
    borderRadius: 12,
    fontWeight: 600,
    fontSize: "0.9rem",
    textDecoration: "none",
  },
  hamburger: {
    display: "none",
    flexDirection: "column",
    gap: 5,
    background: "none",
    border: "none",
    cursor: "pointer",
    padding: 4,
  },
  bar: (open, i) => ({
    width: 24,
    height: 2.5,
    background: "#0F172A",
    borderRadius: 2,
    transition: "all 0.3s",
    transform: open ? `rotate(${i === 1 ? 0 : i === 0 ? 45 : -45}deg)` : "none",
    opacity: open && i === 1 ? 0 : 1,
  }),
  mobileMenu: {
    display: "flex",
    flexDirection: "column",
    gap: 8,
    padding: "16px 24px 24px",
    borderTop: "1px solid rgba(0,0,0,0.06)",
  },
  mobileLink: {
    fontSize: "1.1rem",
    fontWeight: 500,
    color: "#0F172A",
    textDecoration: "none",
    padding: "10px 0",
    borderBottom: "1px solid rgba(0,0,0,0.05)",
  },
  mobileCta: {
    textAlign: "center",
    padding: "12px",
    background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
    color: "#fff",
    borderRadius: 12,
    fontWeight: 600,
    textDecoration: "none",
    marginTop: 8,
  },
};