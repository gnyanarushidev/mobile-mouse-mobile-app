import { Link } from "react-router-dom";

export default function Documentation() {
  return (
    <div style={{ paddingTop: 40 }}>
      <section className="section">
        <div className="container" style={{ maxWidth: 860 }}>
          <h1 className="section-title">Documentation</h1>
          <p className="section-subtitle">
            Everything you need to set up and use Mobile Mouse.
          </p>

          {/* Prerequisites */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Prerequisites</h2>
            <ul style={styles.list}>
              <li>Android phone with <strong>Flutter 3.x</strong> or download the APK from releases</li>
              <li>Desktop running <strong>macOS, Windows, or Linux</strong></li>
              <li>Both devices on the <strong>same Wi‑Fi network</strong></li>
              <li>Desktop listener installed (see below)</li>
            </ul>
          </div>

          {/* Desktop Install */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Desktop Listener Install</h2>
            <p style={styles.p}>The desktop listener runs in the background and receives commands from the mobile app.</p>

            <h3 style={styles.h3}>macOS (Homebrew)</h3>
            <div className="code">brew tap gnyanarushi/mobile-mouse-desktop-app{"\n"}brew install mobile-mouse-desktop-app</div>

            <h3 style={styles.h3}>Windows (PowerShell)</h3>
            <div className="code">curl -fsSL https://raw.githubusercontent.com/gnyanarushi/homebrew-mobile-mouse-desktop-app/main/install.ps1 | Invoke-Expression</div>

            <h3 style={styles.h3}>Linux (Manual)</h3>
            <div className="code">git clone https://github.com/gnyanarushi/mobile-mouse-desktop-app.git{"\n"}cd mobile-mouse-desktop-app{"\n"}./gradlew build</div>
          </div>

          {/* Running the Listener */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Running the Listener</h2>
            <div className="code">mobile-mouse-desktop-app --port 5000</div>
            <p style={styles.p}>The listener binds to <code>0.0.0.0:5000</code> by default. Ensure your firewall allows incoming connections on this port.</p>
          </div>

          {/* Connecting */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Connecting from the Mobile App</h2>
            <ol style={styles.list}>
              <li>Open the Mobile Mouse app on your Android phone</li>
              <li>Tap <strong>Add Connection</strong></li>
              <li>Enter the <strong>hostname or IP</strong> of your desktop</li>
              <li>Tap <strong>Connect</strong> — the status indicator should turn green</li>
            </ol>
            <p style={styles.p}>You can save multiple connections and edit them later by long-pressing a saved entry.</p>
          </div>

          {/* Controls */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Available Controls</h2>
            <div style={styles.featureGrid}>
              <div style={styles.featureItem}>
                <span style={{ fontSize: "1.5rem" }}>🖱️</span>
                <div>
                  <strong>Touchpad</strong>
                  <p style={{ color: "#64748B", fontSize: "0.85rem", marginTop: 4 }}>
                    Slide your finger to move the cursor. Tap to left-click. Two-finger tap for right-click.
                  </p>
                </div>
              </div>
              <div style={styles.featureItem}>
                <span style={{ fontSize: "1.5rem" }}>🧲</span>
                <div>
                  <strong>Gyroscope</strong>
                  <p style={{ color: "#64748B", fontSize: "0.85rem", marginTop: 4 }}>
                    Tilt your phone to control the cursor. Great for presentations.
                  </p>
                </div>
              </div>
              <div style={styles.featureItem}>
                <span style={{ fontSize: "1.5rem" }}>⌨️</span>
                <div>
                  <strong>Keyboard</strong>
                  <p style={{ color: "#64748B", fontSize: "0.85rem", marginTop: 4 }}>
                    Type text, use modifiers (Ctrl, Alt, Shift), and access special keys.
                  </p>
                </div>
              </div>
              <div style={styles.featureItem}>
                <span style={{ fontSize: "1.5rem" }}>📺</span>
                <div>
                  <strong>Screen Streaming</strong>
                  <p style={{ color: "#64748B", fontSize: "0.85rem", marginTop: 4 }}>
                    View your desktop screen in real-time. Supports WebSocket and UDP modes.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* JSON Protocol */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>JSON Protocol</h2>
            <p style={styles.p}>All commands are sent as JSON over TCP. Here are example payloads:</p>

            <h3 style={styles.h3}>Mouse Move</h3>
            <div className="code">{"{"} "type": "mouseMove", "dx": 12, "dy": -4 {"}"}</div>

            <h3 style={styles.h3}>Click</h3>
            <div className="code">{"{"} "type": "click", "button": "left" {"}"}</div>

            <h3 style={styles.h3}>Key Press</h3>
            <div className="code">{"{"} "type": "keyPress", "key": "a", "modifiers": ["ctrl"] {"}"}</div>

            <h3 style={styles.h3}>Scroll</h3>
            <div className="code">{"{"} "type": "scroll", "dy": -3 {"}"}</div>
          </div>

          {/* Troubleshooting */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h2 style={styles.h2}>Troubleshooting</h2>
            <ul style={styles.list}>
              <li><strong>Can't connect?</strong> Make sure both devices are on the same network and port 5000 is not blocked by a firewall.</li>
              <li><strong>Laggy cursor?</strong> Try switching to UDP mode for screen streaming. Reduce screen resolution in settings.</li>
              <li><strong>No audio/keyboard?</strong> Grant the required permissions in Android settings.</li>
              <li><strong>App crashes?</strong> Check that your Android version is 7.0 or above.</li>
            </ul>
          </div>

          {/* Links */}
          <div className="card" style={{ textAlign: "center", padding: "48px 32px" }}>
            <h2 style={{ ...styles.h2, marginBottom: 16 }}>Need more help?</h2>
            <p style={{ ...styles.p, marginBottom: 24 }}>Check the GitHub repos for source code, issues, and contributions.</p>
            <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap" }}>
              <a
                href="https://github.com/gnyanarushi/mobile-mouse-mobile-app"
                target="_blank"
                rel="noreferrer"
                style={styles.linkBtn}
              >
                📱 Mobile App Repo
              </a>
              <a
                href="https://github.com/gnyanarushi/mobile-mouse-desktop-app"
                target="_blank"
                rel="noreferrer"
                style={styles.linkBtn}
              >
                🖥️ Desktop Listener Repo
              </a>
            </div>
            <p style={{ marginTop: 24 }}>
              <Link to="/privacy-policy" style={{ color: "#4F46E5", fontWeight: 600 }}>
                Privacy Policy →
              </Link>
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}

const styles = {
  h2: {
    fontSize: "1.5rem",
    fontWeight: 700,
    color: "#0F172A",
    marginBottom: 16,
  },
  h3: {
    fontSize: "1.05rem",
    fontWeight: 600,
    color: "#334155",
    marginTop: 24,
    marginBottom: 10,
  },
  p: {
    color: "#475569",
    fontSize: "0.95rem",
    lineHeight: 1.8,
    marginBottom: 16,
  },
  list: {
    paddingLeft: 24,
    color: "#475569",
    fontSize: "0.95rem",
    lineHeight: 2,
  },
  featureGrid: {
    display: "grid",
    gridTemplateColumns: "1fr 1fr",
    gap: 24,
  },
  featureItem: {
    display: "flex",
    gap: 16,
    alignItems: "flex-start",
    padding: 16,
    background: "#F8FAFC",
    borderRadius: 12,
  },
  linkBtn: {
    display: "inline-block",
    padding: "12px 28px",
    background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
    color: "#fff",
    borderRadius: 12,
    fontWeight: 600,
    fontSize: "0.95rem",
    textDecoration: "none",
  },
};
