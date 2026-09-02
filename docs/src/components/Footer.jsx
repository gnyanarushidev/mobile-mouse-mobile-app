export default function Footer() {
  const links = [
    { label: "Home", to: "/" },
    { label: "Documentation", to: "/docs" },
    { label: "Privacy Policy", to: "/privacy-policy" },
    { label: "GitHub", to: "https://github.com/gnyanarushi/mobile-mouse-mobile-app" },
  ];

  return (
    <footer style={styles.footer}>
      <div className="container">
        <div style={styles.grid}>
          <div style={styles.brandSection}>
            <span style={styles.brandIcon}>🖱️</span>
            <span style={styles.brandName}>Mobile Mouse</span>
            <p style={styles.tagline}>
              Turn your Android phone into a precise wireless touchpad and remote mouse for your laptop.
            </p>
          </div>

          {[...Array(4)].map((_, i) => {
            const colLinks = [
              ["Product", [links[0], links[1]]],
              ["Resources", [links[2], links[3]]],
              ["Company", [
                { label: "GitHub", to: "https://github.com/gnyanarushi" },
                { label: "License", to: "/privacy-policy" },
              ]],
              ["" , []],
            ];
            const [title, items] = colLinks[i];
            return (
              <div key={i} style={styles.col}>
                <h4 style={styles.colTitle}>{title}</h4>
                {items.map((l) => (
                  <a key={l.to} href={l.to} style={styles.colLink}>
                    {l.label}
                  </a>
                ))}
              </div>
            );
          })}
        </div>

        <div style={styles.bottom}>
          <p>© {new Date().getFullYear()} Mobile Mouse. MIT License.</p>
          <p>Built with ❤️ by gnyanarushi</p>
        </div>
      </div>
    </footer>
  );
}

const styles = {
  footer: {
    background: "var(--bg-dark)",
    color: "#CBD5E1",
    padding: "64px 0 32px",
    marginTop: "80px",
  },
  grid: {
    display: "grid",
    gridTemplateColumns: "2fr 1fr 1fr 1fr",
    gap: "40px",
    marginBottom: "48px",
  },
  brandSection: {
    display: "flex",
    flexDirection: "column",
    gap: 12,
  },
  brandIcon: { fontSize: "2rem" },
  brandName: { fontSize: "1.5rem", fontWeight: 800, color: "#FFFFFF" },
  tagline: { fontSize: "0.9rem", color: "#94A3B8", maxWidth: 320, lineHeight: 1.7 },
  col: { display: "flex", flexDirection: "column", gap: 12 },
  colTitle: { fontSize: "0.85rem", fontWeight: 700, color: "#FFFFFF", textTransform: "uppercase", letterSpacing: "0.05em" },
  colLink: { fontSize: "0.9rem", color: "#94A3B8", textDecoration: "none", transition: "color 0.2s" },
  bottom: {
    display: "flex",
    justifyContent: "space-between",
    paddingTop: 32,
    borderTop: "1px solid rgba(255,255,255,0.08)",
    fontSize: "0.85rem",
    color: "#64748B",
  },
};