export default function PrivacyPolicy() {
  return (
    <div style={{ paddingTop: 40 }}>
      <section className="section">
        <div className="container" style={{ maxWidth: 780 }}>
          <h1 className="section-title">Privacy Policy</h1>
          <p style={styles.updated}>Last updated: September 2, 2026</p>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>1. Overview</h2>
            <p style={styles.p}>
              Mobile Mouse ("the App") is an open-source project that allows users to control their
              desktop computer from an Android device over a local Wi‑Fi network. This privacy
              policy explains how the App handles data.
            </p>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>2. Data Collection</h2>
            <p style={styles.p}>
              The App does <strong>not</strong> collect, store, transmit, or share any personal data
              with third parties. All communication happens exclusively between your Android device
              and your own desktop computer over your local network.
            </p>
            <ul style={styles.list}>
              <li>No analytics or tracking services are used</li>
              <li>No user accounts or registration required</li>
              <li>No data is sent to external servers</li>
              <li>No ads, cookies, or telemetry</li>
            </ul>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>3. Network Communication</h2>
            <p style={styles.p}>
              The App communicates with the desktop listener using TCP or WebSocket connections
              on your local network. Data transmitted includes:
            </p>
            <ul style={styles.list}>
              <li>Mouse movement coordinates (dx, dy deltas)</li>
              <li>Click and scroll events</li>
              <li>Keyboard input</li>
              <li>Gyroscope sensor data (when enabled)</li>
              <li>Screen frames (when screen streaming is active)</li>
            </ul>
            <p style={styles.p}>
              All of this data stays on your local network and is never transmitted to the internet.
            </p>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>4. Permissions</h2>
            <p style={styles.p}>The App may request the following Android permissions:</p>
            <ul style={styles.list}>
              <li><strong>Internet / Network Access</strong> — Required to connect to the desktop listener</li>
              <li><strong>Gyroscope / Motion Sensors</strong> — Optional, used for gyroscope-based cursor control</li>
              <li><strong>Screen Capture</strong> — Optional, used only if you enable screen streaming</li>
            </ul>
            <p style={styles.p}>
              These permissions are used solely for the App's core functionality and are never
              abused for data collection.
            </p>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>5. Open Source</h2>
            <p style={styles.p}>
              Mobile Mouse is fully open source. You can review the complete source code at any time:
            </p>
            <ul style={styles.list}>
              <li>Mobile App: <a href="https://github.com/gnyanarushi/mobile-mouse-mobile-app" target="_blank" rel="noreferrer">github.com/gnyanarushi/mobile-mouse-mobile-app</a></li>
              <li>Desktop Listener: <a href="https://github.com/gnyanarushi/mobile-mouse-desktop-app" target="_blank" rel="noreferrer">github.com/gnyanarushi/mobile-mouse-desktop-app</a></li>
            </ul>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>6. Children's Privacy</h2>
            <p style={styles.p}>
              The App is not directed at children under 13. It does not collect any personal
              information from anyone, including children.
            </p>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>7. Changes to This Policy</h2>
            <p style={styles.p}>
              This privacy policy may be updated from time to time. Any changes will be reflected
              in the "Last updated" date above and in the repository.
            </p>
          </div>

          <div className="card" style={{ marginBottom: 24 }}>
            <h2 style={styles.h2}>8. License</h2>
            <p style={styles.p}>
              Mobile Mouse is released under the <strong>MIT License</strong>. You are free to use,
              modify, and distribute the software in accordance with the license terms.
            </p>
          </div>

          <div className="card" style={{ textAlign: "center", padding: "40px 32px" }}>
            <p style={styles.p}>
              Questions? Open an issue on{" "}
              <a href="https://github.com/gnyanarushi/mobile-mouse-mobile-app/issues" target="_blank" rel="noreferrer">
                GitHub
              </a>.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}

const styles = {
  updated: {
    textAlign: "center",
    color: "#94A3B8",
    fontSize: "0.9rem",
    marginBottom: 48,
    marginTop: -24,
  },
  h2: {
    fontSize: "1.35rem",
    fontWeight: 700,
    color: "#0F172A",
    marginBottom: 14,
  },
  p: {
    color: "#475569",
    fontSize: "0.95rem",
    lineHeight: 1.8,
    marginBottom: 14,
  },
  list: {
    paddingLeft: 24,
    color: "#475569",
    fontSize: "0.95rem",
    lineHeight: 2,
    marginBottom: 14,
  },
};
