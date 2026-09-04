import SwiftUI

/// Protects user privacy by shielding sensitive financial views when the app enters the App Switcher / Multitasking.
@MainActor
public final class PrivacyShieldManager: ObservableObject {

    public static let shared = PrivacyShieldManager()

    @Published public private(set) var shouldShieldUI: Bool = false

    public init() {}

    /// Handles scene phase changes from the SwiftUI App lifecycle.
    public func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App is in foreground and user-interactive
            withAnimation(.easeInOut(duration: 0.15)) {
                self.shouldShieldUI = false
            }
            SecureLogger.security.debug("App became active, privacy shield lowered.")

        case .inactive:
            // App is transitioning (e.g. app switcher gesture initiated)
            withAnimation(.easeInOut(duration: 0.1)) {
                self.shouldShieldUI = true
            }
            SecureLogger.security.debug("App became inactive, privacy shield raised.")

        case .background:
            // App is suspended in background; maintain privacy shield
            self.shouldShieldUI = true
            SecureLogger.security.debug("App in background, privacy shield maintained.")

        @unknown default:
            break
        }
    }
}
