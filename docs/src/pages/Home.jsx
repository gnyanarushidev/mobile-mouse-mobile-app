import { Link } from "react-router-dom";

export default function Home() {
  return (
    <div>
      {/* Hero */}
      <section style={styles.hero}>
        <div className="container">
          <div style={styles.heroContent}>
            <span style={styles.badge}>🖱️ Mobile Mouse v1.0</span>
            <h1 style={styles.heroTitle}>
              Turn Your Phone into a{" "}
              <span style={styles.gradientText}>Precision Touchpad</span>
            </h1>
            <p style={styles.heroSub}>
              Control your desktop cursor, keyboard, and screen — all from your
              Android phone. Smooth touchpad gestures, gyroscope motion, and
              real-time screen streaming over Wi‑Fi.
            </p>
            <div style={styles.buttons}>
              <Link to="/docs" style={styles.btnPrimary}>
                Get Started →
              </Link>
              <a
                href="https://github.com/gnyanarushi/mobile-mouse-mobile-app"
                target="_blank"
                rel="noreferrer"
                style={styles.btnOutline}
              >
                GitHub
              </a>
            </div>
            <div style={styles.stats}>
              <div style={styles.stat}>
                <strong>🚀</strong>
                <span>Multi-platform</span>
              </div>
              <div style={styles.stat}>
                <strong>📡</strong>
                <span>Real-time streaming</span>
              </div>
              <div style={styles.stat}>
                <strong>🎯</strong>
                <span>Precise control</span>
              </div>
              <div style={styles.stat}>
                <strong>🔒</strong>
                <span>Local network</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="section">
        <div className="container">
          <h2 className="section-title">✨ Features</h2>
          <p className="section-subtitle">
            Everything you need to control your desktop from your phone — in one
            lightweight app.
          </p>
          <div className="grid-3">
            {[
              {
                icon: "🖱️",
                title: "Touchpad Control",
                desc: "Drag your finger across the screen to move the cursor. Smooth, responsive, and accurate.",
              },
              {
                icon: "🧲",
                title: "Gyroscope Input",
                desc: "Use your phone's built-in motion sensors to steer the cursor with natural hand movements.",
              },
              {
                icon: "👆",
                title: "Click & Gestures",
                desc: "Left click, right click, and quick access keys — all right at your fingertips.",
              },
              {
                icon: "⌨️",
                title: "Keyboard Control",
                desc: "Type text, tap special keys, use modifiers — full keyboard support from your phone.",
              },
              {
                icon: "📺",
                title: "Screen Streaming",
                desc: "View your desktop screen in real-time via WebSocket or UDP with low latency.",
              },
              {
                icon: "🌐",
                title: "Cross-Platform",
                desc: "Works on Android with desktop listeners for macOS, Windows, and Linux.",
              },
            ].map((f) => (
              <div key={f.title} className="card">
                <span style={{ fontSize: "2rem" }}>{f.icon}</span>
                <h3 style={{ marginTop: 16, marginBottom: 8, fontSize: "1.15rem", fontWeight: 700 }}>
                  {f.title}
                </h3>
                <p style={{ color: "#64748B", fontSize: "0.9rem", lineHeight: 1.7 }}>{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Architecture */}
      <section style={{ background: "#F8FAFC", padding: "80px 0" }}>
        <div className="container">
          <h2 className="section-title">🏗️ How It Works</h2>
          <p className="section-subtitle">
            A simple two-piece architecture — phone app sends JSON, desktop
            listener acts on it.
          </p>
          <div className="grid-2">
            <div className="card">
              <h3 style={{ color: "#4F46E5", marginBottom: 12 }}>📱 Mobile App (Flutter)</h3>
              <ul style={{ listStyle: "disc", paddingLeft: 20, color: "#475569", lineHeight: 2 }}>
                <li>Captures touch gestures &amp; gyroscope data</li>
                <li>Marshals input into JSON payloads</li>
                <li>Sends via TCP / WebSocket to desktop</li>
                <li>Receives and displays screen frames</li>
              </ul>
            </div>
            <div className="card">
              <h3 style={{ color: "#7C3AED", marginBottom: 12 }}>🖥️ Desktop Listener (Java)</h3>
              <ul style={{ listStyle: "disc", paddingLeft: 20, color: "#475569", lineHeight: 2 }}>
                <li>Receives JSON over TCP port 5000/5001</li>
                <li>Moves cursor via AWT Robot / xdotool</li>
                <li>Handles keyboard input &amp; clicks</li>
                <li>Streams desktop screen back via WebSocket/UDP</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="section" style={{ textAlign: "center" }}>
        <div className="container">
          <h2 className="section-title">Ready to get started?</h2>
          <p className="section-subtitle" style={{ margin: "0 auto 32px" }}>
            Install the desktop listener and open the mobile app — you're just minutes away.
          </p>
          <Link to="/docs" style={styles.btnPrimary}>
            View Documentation →
          </Link>
        </div>
      </section>
    </div>
  );
}

const styles = {
  hero: {
    background: "linear-gradient(135deg, #020617 0%, #1E1B4B 50%, #4338CA 100%)",
    padding: "100px 0 80px",
    color: "#fff",
  },
  heroContent: {
    textAlign: "center",
    maxWidth: 720,
    margin: "0 auto",
  },
  badge: {
    display: "inline-block",
    padding: "6px 16px",
    background: "rgba(255,255,255,0.1)",
    borderRadius: 999,
    fontSize: "0.85rem",
    fontWeight: 600,
    marginBottom: 24,
    color: "#CBD5E1",
  },
  heroTitle: { fontSize: "3rem", fontWeight: 800, lineHeight: 1.2, marginBottom: 20 },
  gradientText: {
    background: "linear-gradient(135deg, #818CF8, #C084FC)",
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
    backgroundClip: "text",
  },
  heroSub: { fontSize: "1.15rem", color: "#CBD5E1", lineHeight: 1.7, marginBottom: 36 },
  buttons: { display: "flex", gap: 16, justifyContent: "center", marginBottom: 48 },
  btnPrimary: {
    padding: "14px 32px",
    background: "#fff",
    color: "#4F46E5",
    borderRadius: 12,
    fontWeight: 700,
    fontSize: "1rem",
    textDecoration: "none",
    boxShadow: "0 4px 16px rgba(0,0,0,0.2)",
  },
  btnOutline: {
    padding: "14px 32px",
    background: "transparent",
    color: "#fff",
    borderRadius: 12,
    fontWeight: 600,
    fontSize: "1rem",
    border: "2px solid rgba(255,255,255,0.3)",
    textDecoration: "none",
  },
  stats: {
    display: "flex",
    justifyContent: "center",
    gap: 32,
    flexWrap: "wrap",
    marginTop: 40,
  },
  stat: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
    fontSize: "0.85rem",
    color: "#94A3B8",
  },
};