# 📱 Savings Tracker • Modern iPhone App (INR • ₹ Edition)

A high-fidelity, aesthetic **Monthly Savings Tracker** designed for **iPhone** with Indian Rupee (`₹`) support, modern fintech glassmorphism, interactive curved graphs, and reactive micro-animations.

Developed seamlessly on **Kali Linux** without needing macOS, Xcode, or Apple Developer fees, installable directly on your iPhone as a standalone app!

---

## ✨ Features

- **Indian Rupee (INR • ₹) Native**: Full native support for Indian Rupee (`₹`) with Indian numbering formatting (`₹1,45,000`, `₹25,000`), realistic savings goals, and quick-add denominations (`+₹500`, `+₹1,000`, `+₹2,500`, `+₹5,000`).
- **Lightning-Fast Instant Loading**: Multi-threaded server with zero DNS-lookup lag, `TCP_NODELAY`, and smart browser caching for instantaneous sub-50ms loading on iPhone & desktop.
- **Fintech Dark Aesthetic**: Deep obsidian palette (`#090c15`), frosted glass cards (`backdrop-filter: blur(24px)`), and glowing emerald mint accents (`#10b981`).
- **Dedicated Overview Dashboard**:
  - **Hero Card**: Displays Total Accumulated Savings (`₹3,14,000`), current month's savings (`₹18,500`), Month-over-Month (% MoM) savings rate, and goal progress bar (`₹25,000` goal).
  - **Interactive Spline Graph**: Smooth Bezier area chart plotting savings over 3 Months, 6 Months, or 1 Year with interactive hover/tap tooltips and target reference lines.
  - **Asset Allocation Visualizer**: Dynamic animated SVG donut ring showing distribution across dedicated buckets.
  - **Financial Metrics**: Monthly savings average, highest monthly record, and projected annual savings.
- **Dedicated Savings Buckets**:
  - Emergency Fund (Safety) — Target: ₹2,00,000
  - Mutual Funds & SIP (Wealth) — Target: ₹1,50,000
  - Goa & Ladakh Trip (Travel) — Target: ₹60,000
  - Workstation & Tech (Gadgets) — Target: ₹50,000
- **Rapid Reactive Refresh & Animations**:
  - **Number Rolling Counters**: When money is deposited, numbers roll up smoothly (`easeOutQuint`).
  - **Card Flash Effect**: Cards pulse with a glowing emerald halo when updated.
  - **Dynamic Chart Morphing**: The chart's data points and Bezier spline curve smoothly interpolate upwards in real-time.
  - **Confetti Celebration**: Canvas particle burst triggers automatically upon reaching savings goals.
  - **Tactile Feedback & Audio Chimes**: Synthesized Apple Pay-style dual-harmonic cash chime and iOS haptic vibration (`navigator.vibrate`).
- **iOS Bottom Sheet Modal**: Quick-select denomination pills (`+₹500`, `+₹1,000`, `+₹2,500`, `+₹5,000`), custom amount keypad, and bucket selector.
- **Offline-First & Privacy**: 100% private. All data is persisted in your device's `localStorage` and Service Worker cache. Includes one-click JSON backup export/import.
- **Kali Linux Desktop Preview Mode**: Includes an interactive iPhone 16 Pro mockup frame with a Dynamic Island simulation, switchable to full desktop view with one click.

---

## 🚀 Quick Start on Kali Linux

You can run the app with either **Python 3** or **Node.js** (both have zero dependencies):

### Option A: Using Python 3 (Recommended)
```bash
python3 server.py
```

### Option B: Using Node.js
```bash
node server.js
```

The terminal will display:
- **Local Preview**: `http://localhost:8080` (open in Chromium or Firefox on Kali Linux)
- **iPhone Link**: `http://<YOUR_LOCAL_IP>:8080` (e.g. `http://192.168.1.55:8080`)

---

## 📲 How to Install & Run on iPhone

1. Connect your **iPhone** to the same Wi-Fi network as your Kali Linux machine.
2. Open **Safari** on your iPhone and go to the link shown in your terminal (e.g. `http://192.168.1.X:8080`).
3. Tap the **Share** button in Safari (the square icon with the arrow pointing up at the bottom).
4. Scroll down and tap **Add to Home Screen**.
5. Tap **Add** in the top right.

The **Savings** app icon will appear on your iPhone Home Screen. Tapping it opens the app in fullscreen mode with no Safari URL bars, looking and behaving just like a native iOS application!

---

## 📁 Project Architecture

```
Savings-Tracker/
├── index.html          # iOS viewport setup, safe area margins, PWA links & app shell
├── manifest.json       # PWA manifest for iPhone home screen installation
├── sw.js               # Service Worker for offline asset caching
├── css/
│   └── styles.css      # iOS glassmorphism, typography, animations, and utilities
├── js/
│   ├── icons.js        # Crisp Lucide / SF Pro styled SVG icons
│   ├── store.js        # State management, reactivity, calculations & LocalStorage
│   ├── chart.js        # High-performance SVG Bezier spline & donut chart engine
│   ├── animations.js   # Rolling number counters, card flash, audio synthesizer, confetti
│   └── app.js          # Controller orchestrating views, modals, and rapid refresh
├── icons/
│   └── icon.svg        # App icon with squircle, gradient, and glow effects
├── server.py           # Zero-dependency local LAN server (Python)
├── server.js           # Zero-dependency local LAN server (Node)
└── README.md           # Documentation
```

---

## 🛠️ Testing & Rapid Refresh Demo

1. Open `http://localhost:8080` in your browser.
2. Notice the **Overview Dashboard** with the **Hero Savings Card** and the **Savings Trajectory Graph**.
3. Click the **"+₹1,000 Quick Add"** or **"+ Deposit"** button.
4. Pick an amount (e.g. `+₹2,500`) and tap **"Confirm Deposit"**.
5. Observe the rapid reactive cascade:
   - Rolling counter increments on Total Savings and Monthly Savings without layout jitter.
   - Hero card and bucket card flash with an emerald border glow.
   - The chart's data point and curve smoothly animate upwards.
   - The transaction appears in the activity feed with a slide-in transition.
   - If the monthly goal of ₹25,000 is met, confetti cascades across the screen!

---

## 🛡️ Native iOS App (Swift + SwiftUI)

For deployment directly via Xcode, TestFlight, or the App Store with **hardware-level encryption**, **Face ID**, and **Apple Privacy Manifest**, see the dedicated native Swift codebase in:

👉 **[`ios/SavingsTracker/`](./ios/SavingsTracker/)**

- **Language & Framework**: Swift 5.9+, SwiftUI, iOS 17.0+
- **Security**: AES-256-GCM via `CryptoKit`, Master Key locked in `Keychain` (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)
- **Biometrics**: `LocalAuthentication` with Face ID & device passcode fallback
- **Multitasking Privacy**: Automatic App Switcher privacy shield against screenshot data leakage
- **Compliance**: Apple `PrivacyInfo.xcprivacy` manifest (iOS 17+ compliant)
- **CI/CD**: Pre-configured GitHub Actions workflow at `.github/workflows/ios.yml`

