import SwiftUI

/// Privacy shield covering financial content when the app is in the iOS App Switcher or locked.
/// Features hardware-level privacy obscuration and accessible unlock controls.
public struct PrivacyShieldView: View {

    public var isBiometricPromptNeeded: Bool
    public var biometryIconName: String
    public var biometryDisplayName: String
    public var errorMessage: String?
    public var onUnlockTapped: (() -> Void)?

    public init(
        isBiometricPromptNeeded: Bool = false,
        biometryIconName: String = "faceid",
        biometryDisplayName: String = "Biometrics",
        errorMessage: String? = nil,
        onUnlockTapped: (() -> Void)? = nil
    ) {
        self.isBiometricPromptNeeded = isBiometricPromptNeeded
        self.biometryIconName = biometryIconName
        self.biometryDisplayName = biometryDisplayName
        self.errorMessage = errorMessage
        self.onUnlockTapped = onUnlockTapped
    }

    public var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 22) {
                // Shield Emblem
                ZStack {
                    Circle()
                        .fill(AppTheme.emerald.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Circle()
                        .stroke(AppTheme.emerald.opacity(0.25), lineWidth: 1)
                        .frame(width: 88, height: 88)

                    Image(systemName: isBiometricPromptNeeded ? biometryIconName : "lock.shield.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(AppTheme.emeraldLight)
                }
                .accessibilityHidden(true)

                // Title & Security Subheading
                VStack(spacing: 8) {
                    Text(isBiometricPromptNeeded ? "Savings Vault Locked" : "Savings Vault")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)

                    Text(isBiometricPromptNeeded
                         ? "Authenticate using \(biometryDisplayName) or your device passcode to access your financial records."
                         : "Protected with Hardware Encryption")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                // Error Message Pill (if authentication was cancelled or failed)
                if let error = errorMessage, isBiometricPromptNeeded {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.roseRed)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.roseRed.opacity(0.12))
                    .cornerRadius(10)
                    .padding(.top, 4)
                }

                // Unlock Trigger Button
                if isBiometricPromptNeeded, let unlockAction = onUnlockTapped {
                    Button {
                        AppTheme.triggerHaptic(style: .medium)
                        unlockAction()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: biometryIconName)
                                .font(.system(size: 16, weight: .bold))
                            Text("Unlock with \(biometryDisplayName)")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.emerald, AppTheme.emeraldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.emerald.opacity(0.4), radius: 10, y: 4)
                    }
                    .padding(.top, 14)
                    .accessibilityLabel("Unlock Savings Vault with \(biometryDisplayName) or Passcode")
                    .accessibilityHint("Double tap to authenticate and unlock your financial vault")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
    }
}
