import SwiftUI

/// Main application entrypoint for the Savings Tracker iOS application.
/// Incorporates hardware-level security, App Switcher privacy shielding, App Lock with biometrics/passcode,
/// and protected deep-link / navigation routing.
@main
public struct SavingsTrackerApp: App {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var privacyManager = PrivacyShieldManager.shared
    @StateObject private var appLockManager = AppLockManager.shared

    public init() {
        SecureLogger.lifecycle.info("Savings Tracker app initialized.")
    }

    public var body: some Scene {
        WindowGroup {
            ZStack {
                // Primary App Interface
                DashboardView()
                    .accessibilityHidden(appLockManager.isLocked || privacyManager.shouldShieldUI)
                    .allowsHitTesting(!appLockManager.isLocked && !privacyManager.shouldShieldUI)

                // Privacy Shield for App Switcher snapshot protection (highest priority)
                if privacyManager.shouldShieldUI {
                    PrivacyShieldView(
                        isBiometricPromptNeeded: false,
                        biometryIconName: appLockManager.biometricManager.biometryIconName,
                        biometryDisplayName: appLockManager.biometricManager.biometryDisplayName
                    )
                    .transition(.opacity)
                    .zIndex(1000)
                }

                // Interactive App Lock Screen (Face ID / Touch ID / Passcode)
                if appLockManager.isLocked && appLockManager.isAppLockEnabled {
                    PrivacyShieldView(
                        isBiometricPromptNeeded: true,
                        biometryIconName: appLockManager.biometricManager.biometryIconName,
                        biometryDisplayName: appLockManager.biometricManager.biometryDisplayName,
                        errorMessage: appLockManager.biometricManager.authenticationError,
                        onUnlockTapped: {
                            Task {
                                await appLockManager.requestUnlock()
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: privacyManager.shouldShieldUI)
            .animation(.easeInOut(duration: 0.2), value: appLockManager.isLocked)
            .onChange(of: scenePhase) { _, newPhase in
                privacyManager.handleScenePhaseChange(newPhase)
                appLockManager.handleScenePhaseChange(newPhase)
            }
            .onOpenURL { url in
                appLockManager.handleDeepLink(url)
            }
            .task {
                appLockManager.biometricManager.checkAvailability()
                if appLockManager.isLocked && appLockManager.isAppLockEnabled {
                    await appLockManager.requestUnlock()
                }
            }
        }
    }
}
