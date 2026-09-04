# 🛡️ Savings Tracker • Native iOS Application (Swift + SwiftUI)

A security-first, production-ready native iOS application for tracking monthly savings in Indian Rupee (INR • `₹`), built with modern Swift, SwiftUI, and Apple's latest security frameworks.

---

## 🏗️ Architecture & Design Principles

The iOS app is structured following Clean Architecture and Domain-Driven Design (DDD) to ensure strict separation of concerns, testability, and enterprise-grade security:

```
ios/SavingsTracker/
├── Package.swift                             # Swift Package manifest targeting iOS 17.0+
├── Sources/
│   ├── App/
│   │   └── SavingsTrackerApp.swift           # SwiftUI App entrypoint with Privacy Shield & Biometrics
│   ├── Security/
│   │   ├── AppLockManager.swift              # App Lock lifecycle, timeouts & deep link interception
│   │   ├── KeychainService.swift             # Keychain wrapper with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
│   │   ├── BiometricAuthManager.swift        # Face ID / Touch ID / Passcode LocalAuthentication provider
│   │   ├── InputSanitizer.swift              # Strict validation, regex, anti-injection, and range capping
│   │   ├── PrivacyShieldManager.swift        # Multitasking & App Switcher snapshot blur protection
│   │   └── SecureLogger.swift                # Zero-PII privacy-redacted logging via os.Logger
│   ├── Domain/
│   │   └── Models/
│   │       ├── CurrencyType.swift            # INR (₹) locale formatting with Indian numbering system
│   │       ├── SavingsGoal.swift             # Dedicated bucket entity (Emergency, SIP, Travel, Tech)
│   │       ├── SavingsTransaction.swift      # Immutable deposit ledger entry
│   │       ├── MonthlyRecord.swift           # Monthly historical archive entry
│   │       └── FinancialMetrics.swift        # Aggregated analytics (MoM growth, averages, projected annual)
│   ├── Data/
│   │   ├── SecureStorageService.swift        # AES-256-GCM CryptoKit encryption with completeFileProtection
│   │   └── SavingsRepository.swift           # Thread-safe Swift actor managing encrypted storage & state
│   ├── Presentation/
│   │   ├── Theme/
│   │   │   └── Theme.swift                   # Obsidian & Emerald palette, GlassCard modifiers, Haptic engine
│   │   ├── Components/
│   │   │   ├── HeroSavingsCard.swift         # Overview hero card with numeric roll animations
│   │   │   ├── SplineChartView.swift         # Pure SwiftUI Bezier curve interactive graph with drag tooltip
│   │   │   └── DonutChartView.swift          # Dynamic asset allocation visualizer
│   │   ├── ViewModels/
│   │   │   └── DashboardViewModel.swift      # @MainActor observable view model with rapid refresh cascade
│   │   └── Views/
│   │       ├── DashboardView.swift           # 5-tab main container (Dashboard, Monthly, Buckets, Activity, Security)
│   │       ├── AddDepositSheet.swift         # Bottom sheet deposit modal with denomination pills
│   │       ├── MonthlyArchiveView.swift      # Historical performance records & target completion
│   │       ├── DedicatedBucketsView.swift    # Fund cards with individual progress bars
│   │       ├── ActivityLedgerView.swift      # Chronological deposit transaction audit trail
│   │       ├── SecuritySettingsView.swift    # App Lock toggle, auto-lock timeout, and data hygiene
│   │       └── PrivacyShieldView.swift       # Frosted security veil & interactive unlock screen
│   └── Resources/
│       ├── Info.plist                        # Face ID usage description, URL scheme & ATS rules
│       └── PrivacyInfo.xcprivacy             # Apple mandatory Privacy Manifest (iOS 17+)
└── Tests/
    ├── AppLockTests.swift                    # Timeouts, background transitions & deep link interception
    ├── InputSanitizationTests.swift          # Rejection of negative, zero, overflow, and XSS input
    ├── CalculationTests.swift                # Indian Rupee formatting, progress %, and MoM math
    └── SecurityTests.swift                   # CryptoKit AES-GCM encryption roundtrip & tamper detection
```

---

## 🔒 Security Architecture Highlights

1. **Zero Hard-coded Secrets**: No sensitive keys, passwords, or tokens in source code or build flags.
2. **Hardware-Backed Master Key in Keychain**: The AES-GCM 256-bit encryption key is generated with cryptographically secure random bytes and locked in the iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, preventing unauthorized extraction even if a backup is restored on a different device.
3. **AES-256-GCM Authenticated Encryption on Disk**: All financial records, goals, and transactions are encrypted with `CryptoKit.AES.GCM` prior to writing to the filesystem, and written with `completeFileProtection` (hardware-encrypted when device is locked).
4. **App Switcher Privacy Shield**: iOS automatically takes snapshot images of apps when entering the App Switcher / Multitasking tray. `PrivacyShieldManager` observes `scenePhase` transitions and superimposes a frosted `PrivacyShieldView` before snapshots are taken, preventing accidental shoulder-surfing or cached cleartext previews.
5. **Strict Input Sanitization**:
   - Single deposit cap set at ₹10 Crore (`₹100,000,000`) to prevent numeric overflow.
   - Max 2 decimal places strictly enforced for fiat currency.
   - HTML injection tokens (`<`, `>`, `&`, `"`, `'`) are sanitized.
   - Zero and negative values are strictly rejected.
6. **Biometric Access Control (LocalAuthentication)**: Supports Face ID, Touch ID, and Optic ID with automatic device passcode fallback.
7. **Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)**: Declares zero tracking, zero third-party data collection, and explicitly provides Apple's approved reasons for UserDefaults and File Timestamp APIs.
8. **Zero-PII Structured Logging (`os.Logger`)**: High-performance system logging with privacy redaction ensuring balances, notes, and user details are never written to system consoles.

---

## 🚀 How to Open, Build & Test in Xcode

### Prerequisites
- macOS Sonoma 14+ or Sequoia 15+
- Xcode 15.0+ or 16.0+
- iOS 17.0+ Simulator or physical iPhone

### Option A: Open as a Swift Package
1. Launch **Xcode**.
2. Select **File > Open...** and navigate to `ios/SavingsTracker/Package.swift`.
3. Xcode will automatically resolve dependencies and configure targets.
4. Select an iOS Simulator (e.g. **iPhone 16 Pro**) from the top run destination dropdown.
5. Press **Cmd + U** to execute the unit test suite (`SavingsTrackerTests`).
6. Press **Cmd + R** to run the app.

### Option B: Command-Line via `xcodebuild` / `swift`
Run the test suite from the terminal:
```bash
cd ios/SavingsTracker
swift test
```
Or with `xcodebuild`:
```bash
xcodebuild test \
  -scheme SavingsTrackerTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
```

---

## 📲 Deploying to a Physical iPhone

### Free Personal Team Deployment (No $99 Fee Required)
1. In Xcode, connect your iPhone via USB cable or local Wi-Fi.
2. Under **Signing & Capabilities**, set **Team** to your Personal Apple ID team.
3. Set a unique Bundle Identifier (e.g., `com.yourname.savingstracker`).
4. Select your iPhone as the build target and press **Cmd + R**.
5. On your iPhone, go to **Settings > General > VPN & Device Management**, tap your Developer App profile, and choose **Trust**.

---

## 🧪 Automated CI/CD (GitHub Actions)

A GitHub Actions workflow is provided at `.github/workflows/ios.yml` to automatically build and run security tests on macOS runners for every push and pull request.
