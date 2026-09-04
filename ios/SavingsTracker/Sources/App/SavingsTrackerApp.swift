import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Main application entrypoint for the Savings Tracker iOS application.
/// Incorporates hardware-level security, App Switcher privacy shielding, App Lock with biometrics/passcode,
/// and protected deep-link / navigation routing.
#if os(iOS)
@main
#endif
public struct SavingsTrackerApp: App {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var privacyManager = PrivacyShieldManager.shared
    @StateObject private var appLockManager = AppLockManager.shared

    public init() {
        SecureLogger.lifecycle.info("Savings Tracker app initialized.")
        configureGlobalAppearances()
    }

    private func configureGlobalAppearances() {
        #if os(iOS)
        // 1. Consistent Dark UITabBarAppearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 9/255, green: 12/255, blue: 21/255, alpha: 1.0)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0)
        ]
        itemAppearance.selected.iconColor = UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1.0)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1.0)
        ]

        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // 2. Consistent Dark UINavigationBarAppearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = UIColor(red: 9/255, green: 12/255, blue: 21/255, alpha: 1.0)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        #endif
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
            .preferredColorScheme(.dark)
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
