import SwiftUI
import Combine

/// Auto-lock timeout choices.
public enum AutoLockTimeout: Int, CaseIterable, Identifiable, Codable, Sendable {
    case immediate = 0
    case oneMinute = 60
    case fiveMinutes = 300

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .immediate: return "Immediately"
        case .oneMinute: return "After 1 minute"
        case .fiveMinutes: return "After 5 minutes"
        }
    }

    public var seconds: TimeInterval {
        TimeInterval(rawValue)
    }
}

/// Coordinates the App Lock security lifecycle:
/// - Enforces device passcode / biometric authentication on launch & background return
/// - Obscures screens and blocks interaction when locked
/// - Queues deep-links and navigation events until unlocked
/// - Offers configurable auto-lock grace periods
@MainActor
public final class AppLockManager: ObservableObject {

    public static let shared = AppLockManager()

    // MARK: - Keys
    private static let appLockEnabledKey = "com.savingstracker.app.app_lock_enabled"
    private static let autoLockTimeoutKey = "com.savingstracker.app.autolock_timeout"

    // MARK: - Published State
    @Published public private(set) var isLocked: Bool
    @Published public private(set) var pendingDeepLinkURL: URL?
    @Published public var isAppLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAppLockEnabled, forKey: Self.appLockEnabledKey)
            if !isAppLockEnabled {
                isLocked = false
            }
        }
    }
    @Published public var autoLockTimeout: AutoLockTimeout {
        didSet {
            UserDefaults.standard.set(autoLockTimeout.rawValue, forKey: Self.autoLockTimeoutKey)
        }
    }

    // MARK: - Dependencies
    public let biometricManager: LocalAuthenticationProviding
    public private(set) var lastBackgroundDate: Date?

    public init(
        biometricManager: LocalAuthenticationProviding = BiometricAuthManager.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.biometricManager = biometricManager

        let storedEnabled = userDefaults.bool(forKey: Self.appLockEnabledKey)
        self.isAppLockEnabled = storedEnabled

        let storedTimeoutRaw = userDefaults.integer(forKey: Self.autoLockTimeoutKey)
        self.autoLockTimeout = AutoLockTimeout(rawValue: storedTimeoutRaw) ?? .immediate

        // If App Lock is enabled, app starts in locked state on fresh launch
        self.isLocked = storedEnabled
    }

    // MARK: - Lifecycle Management

    /// Handles scenePhase changes from the SwiftUI App lifecycle.
    public func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isAppLockEnabled else { return }

        switch phase {
        case .background:
            lastBackgroundDate = Date()
            if autoLockTimeout == .immediate {
                isLocked = true
                SecureLogger.security.info("App entered background; locked immediately.")
            } else {
                SecureLogger.security.debug("App entered background; grace period started (\(self.autoLockTimeout.displayName, privacy: .public)).")
            }

        case .active:
            evaluateLockStateOnActive()

        case .inactive:
            // App is transitioning (e.g. app switcher gesture initiated)
            break

        @unknown default:
            break
        }
    }

    /// Evaluates whether the lock timeout has expired when app returns to active.
    public func evaluateLockStateOnActive() {
        guard isAppLockEnabled else { return }

        if let bgDate = lastBackgroundDate {
            let elapsed = Date().timeIntervalSince(bgDate)
            if elapsed >= autoLockTimeout.seconds {
                isLocked = true
                SecureLogger.security.info("Grace period expired (\(Int(elapsed), privacy: .public)s elapsed); app locked.")
            }
            lastBackgroundDate = nil
        }

        if isLocked {
            Task {
                await requestUnlock()
            }
        }
    }

    /// Requests user authentication using biometrics or passcode to unlock the app.
    @discardableResult
    public func requestUnlock(reason: String = "Unlock your Savings Vault") async -> Bool {
        guard isAppLockEnabled && isLocked else {
            return true
        }

        let success = await biometricManager.authenticate(reason: reason)
        if success {
            self.isLocked = false
            self.lastBackgroundDate = nil
            SecureLogger.security.info("Vault successfully unlocked.")
            processPendingDeepLink()
        }
        return success
    }

    /// Immediately locks the app session.
    public func lockImmediately() {
        if isAppLockEnabled {
            self.isLocked = true
            self.biometricManager.lockSession()
            SecureLogger.security.info("Vault locked immediately by user request.")
        }
    }

    // MARK: - Deep-Link & Navigation Security

    /// Safe entrypoint for deep links.
    /// If app is locked, queues the URL and prevents execution until unlocked.
    /// - Parameter url: The incoming deep-link URL.
    /// - Returns: True if deep-link can be opened immediately; false if queued.
    @discardableResult
    public func handleDeepLink(_ url: URL) -> Bool {
        if isLocked && isAppLockEnabled {
            self.pendingDeepLinkURL = url
            SecureLogger.security.notice("Deep link intercepted and queued while app is locked: \(url.scheme ?? "", privacy: .public)://")
            // Prompt unlock
            Task {
                await requestUnlock(reason: "Authenticate to view requested savings record")
            }
            return false
        } else {
            SecureLogger.security.info("Deep link processed immediately.")
            NotificationCenter.default.post(
                name: .init("SavingsTrackerDidUnlockWithPendingDeepLink"),
                object: url
            )
            return true
        }
    }

    /// Releases and clears queued deep-link after successful unlock.
    private func processPendingDeepLink() {
        guard let url = pendingDeepLinkURL else { return }
        SecureLogger.security.info("Releasing queued deep link after unlock: \(url.scheme ?? "", privacy: .public)://")
        self.pendingDeepLinkURL = nil
        // Notification for deep link router
        NotificationCenter.default.post(
            name: .init("SavingsTrackerDidUnlockWithPendingDeepLink"),
            object: url
        )
    }

    // MARK: - Safe Toggle Operations

    /// Authenticates the user before allowing them to enable or disable App Lock in Settings.
    /// Prevents accidentally locking oneself out or unauthorized disablement.
    public func preflightToggleAppLock(to enable: Bool) async -> Bool {
        let reason = enable
            ? "Authenticate to enable App Lock protection"
            : "Authenticate to disable App Lock protection"

        let authenticated = await biometricManager.authenticate(reason: reason)
        if authenticated {
            self.isAppLockEnabled = enable
            if !enable {
                self.isLocked = false
            }
            AppTheme.triggerNotificationHaptic(type: .success)
            return true
        } else {
            AppTheme.triggerNotificationHaptic(type: .error)
            return false
        }
    }
}
