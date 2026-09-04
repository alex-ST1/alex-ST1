# 📲 How to Install Savings Tracker on Your iPhone (Without a Mac)

This guide shows you how to install the compiled native iOS app (`SavingsTracker.ipa`) onto your physical iPhone using a standard PC or Linux computer with a **free personal Apple ID**.

---

## 🛠️ Prerequisites

1. Your **iPhone** (iOS 17.0 or newer).
2. A **USB Lightning / USB-C cable** to connect your iPhone to a computer.
3. Your **Personal Apple ID** (no paid $99 developer account needed).
4. Download the latest **`SavingsTracker.ipa`** from GitHub Actions (instructions below).

---

## Step 1: Download `SavingsTracker.ipa` from GitHub

1. Open your repository on GitHub: [`https://github.com/alex-ST1/alex-ST1`](https://github.com/alex-ST1/alex-ST1).
2. Click on the **Actions** tab at the top.
3. Click on the latest workflow run named **"iOS Security & Build CI"**.
4. Scroll down to the **Artifacts** section at the bottom of the summary page.
5. Click on **`SavingsTracker-iOS-IPA`** to download the zip file.
6. Extract the zip file on your computer to obtain `SavingsTracker.ipa`.

---

## Step 2: Install via Sideloadly (Recommended — Easiest & Free)

**Sideloadly** is a free, safe desktop app that signs the `.ipa` with your free Apple ID and installs it directly onto your connected iPhone.

1. **Download Sideloadly**:
   - Visit [sideloadly.io](https://sideloadly.io) and download the version for Windows or macOS (or run via Wine/VM on Linux).
2. **Connect your iPhone**:
   - Connect your iPhone to your computer using a USB cable.
   - Unlock your iPhone and tap **"Trust this computer"** if prompted.
3. **Load the IPA**:
   - Open Sideloadly. You will see your connected device listed.
   - Drag and drop `SavingsTracker.ipa` into the large icon box in Sideloadly.
4. **Sign In & Install**:
   - Enter your **Apple ID email** in the "Apple account" field.
   - Click **Start**.
   - Sideloadly will ask for your Apple ID password (used locally to request a free 7-day development certificate from Apple).
   - Once the progress bar reaches 100%, **Savings Vault** will appear on your iPhone home screen!

---

## Step 3: Trust Developer Certificate on Your iPhone

When you tap the app icon for the first time, iOS will say *"Untrusted Developer"*. This is normal for free personal Apple ID sideloading:

1. On your iPhone, open **Settings**.
2. Go to **General** > **VPN & Device Management**.
3. Under **DEVELOPER APP**, tap your Apple ID email.
4. Tap **Trust "[Your Apple ID]"** and confirm **Trust**.

---

## Step 4: Enable Developer Mode (iOS 16 / iOS 17 requirement)

If prompted that "Developer Mode is required":

1. On your iPhone, open **Settings**.
2. Go to **Privacy & Security** > scroll down to **Developer Mode**.
3. Toggle **Developer Mode** to **ON**.
4. Tap **Restart**.
5. After your phone restarts, unlock it and tap **Turn On** on the confirmation popup.

---

## 🎉 You're Done!

You can now open **Savings Vault** on your iPhone!
- **App Lock**: Go to the **Security** tab and toggle **App Lock** to activate native **Face ID / Touch ID** protection.
- **Biometric Authentication**: Test locking the screen and backgrounding the app.
- **Hardware Encryption**: Your financial data is securely sealed via CryptoKit AES-256-GCM in the hardware Keychain.

*(Note: Apps signed with a free personal Apple ID remain valid for 7 days. To renew, simply re-plug your phone and click Start in Sideloadly).*
