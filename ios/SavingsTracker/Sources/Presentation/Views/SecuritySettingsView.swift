import SwiftUI

/// Security settings view for Biometrics, App Lock, Keychain Encryption, and Privacy controls.
public struct SecuritySettingsView: View {

    @StateObject private var appLockManager = AppLockManager.shared
    @StateObject private var biometricManager = BiometricAuthManager.shared
    @ObservedObject public var viewModel: DashboardViewModel

    @State private var isWipeConfirmationPresented: Bool = false
    @State private var isLockToggleProcessing: Bool = false
    @State private var toggleErrorMessage: String? = nil

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: App Lock & Biometrics
                Section {
                    Toggle(isOn: Binding(
                        get: { appLockManager.isAppLockEnabled },
                        set: { targetValue in
                            guard !isLockToggleProcessing else { return }
                            isLockToggleProcessing = true
                            Task {
                                let success = await appLockManager.preflightToggleAppLock(to: targetValue)
                                if !success {
                                    toggleErrorMessage = "Authentication was cancelled or failed. Setting was not changed."
                                } else {
                                    toggleErrorMessage = nil
                                }
                                isLockToggleProcessing = false
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: biometricManager.biometryIconName)
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.emeraldLight)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("App Lock (\(biometricManager.biometryDisplayName))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Require \(biometricManager.biometryDisplayName) or passcode when returning to app.")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                    .tint(AppTheme.emerald)
                    .disabled(isLockToggleProcessing || (!biometricManager.isBiometryAvailable && !biometricManager.isPasscodeAvailable))

                    // Auto-Lock Timeout Option
                    if appLockManager.isAppLockEnabled {
                        Picker("Auto-Lock", selection: $appLockManager.autoLockTimeout) {
                            ForEach(AutoLockTimeout.allCases) { timeout in
                                Text(timeout.displayName).tag(timeout)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.emeraldLight)

                        // Lock Now Button
                        Button {
                            AppTheme.triggerHaptic(style: .medium)
                            appLockManager.lockImmediately()
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 13))
                                Text("Lock Vault Now")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.emeraldLight)
                        }
                    }
                } header: {
                    Text("ACCESS CONTROL & APP LOCK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if !biometricManager.isPasscodeAvailable && !biometricManager.isBiometryAvailable {
                            Text("No device passcode is configured in iOS Settings. Please enable a device passcode to activate App Lock.")
                                .foregroundColor(AppTheme.roseRed)
                        } else {
                            Text("Your device passcode is always supported as an automatic fallback if \(biometricManager.biometryDisplayName) fails or is cancelled.")
                                .foregroundColor(AppTheme.textMuted)
                        }

                        if let error = toggleErrorMessage {
                            Text(error)
                                .foregroundColor(AppTheme.roseRed)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.top, 2)
                        }
                    }
                    .font(.system(size: 11))
                }

                // Section 2: Hardware Security Status
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(AppTheme.blue)
                            .frame(width: 20)
                        Text("Keychain Hardware Encryption")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("AES-256-GCM")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.emeraldLight)
                    }

                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(AppTheme.purple)
                            .frame(width: 20)
                        Text("App Switcher Privacy Shield")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.emeraldLight)
                    }

                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(AppTheme.cyan)
                            .frame(width: 20)
                        Text("Apple Privacy Manifest")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Compliant")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.emeraldLight)
                    }
                } header: {
                    Text("HARDWARE SECURITY STATUS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }

                // Section 3: Data Hygiene
                Section {
                    Button(role: .destructive) {
                        isWipeConfirmationPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 20)
                            Text("Reset Vault to Default Sample Data")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                } header: {
                    Text("DATA HYGIENE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Security & Privacy")
            .confirmationDialog(
                "Reset Vault Data?",
                isPresented: $isWipeConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Reset Data", role: .destructive) {
                    viewModel.resetData()
                    AppTheme.triggerNotificationHaptic(type: .success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will wipe all existing transaction records and restore the default INR savings structure.")
            }
        }
    }
}
