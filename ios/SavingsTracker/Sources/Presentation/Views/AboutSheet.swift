import SwiftUI

/// Elegant About sheet displaying app metadata, architecture highlights, and developer attribution.
public struct AboutSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isEmailCopied: Bool = false

    public let authorName = "Sagar Thapa"
    public let authorEmail = "thapasagar102@gmail.com"

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon & Hero Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 15/255, green: 23/255, blue: 42/255),
                                            Color(red: 9/255, green: 12/255, blue: 21/255)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [AppTheme.emeraldLight, AppTheme.cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: AppTheme.emerald.opacity(0.35), radius: 16, x: 0, y: 8)

                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.emeraldLight, AppTheme.cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .padding(.top, 12)

                        VStack(spacing: 4) {
                            Text("Savings Vault")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)

                            Text("Version 1.0.0 (Build 1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.emeraldLight)

                            Text("Encrypted Personal Wealth Tracker")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    // Developer Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.emeraldLight)
                            Text("AUTHOR & DEVELOPER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.6)
                        }

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.emerald, AppTheme.cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Text("ST")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(authorName)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Author & Creator")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Email Row & Actions
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppTheme.cyan)
                                    .font(.system(size: 14))

                                Text(authorEmail)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()
                            }

                            HStack(spacing: 10) {
                                Link(destination: URL(string: "mailto:\(authorEmail)")!) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("Send Email")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.emerald)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }

                                Button {
                                    #if os(iOS)
                                    UIPasteboard.general.string = authorEmail
                                    #endif
                                    AppTheme.triggerNotificationHaptic(type: .success)
                                    isEmailCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        isEmailCopied = false
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isEmailCopied ? "checkmark" : "doc.on.doc.fill")
                                            .font(.system(size: 11, weight: .bold))
                                        Text(isEmailCopied ? "Copied!" : "Copy")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)

                    // Key Architectural Features
                    VStack(alignment: .leading, spacing: 14) {
                        Text("KEY CAPABILITIES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        featureRow(icon: "key.fill", color: AppTheme.blue, title: "Hardware Security", desc: "AES-256-GCM encrypted persistence in secure iOS Keychain.")
                        featureRow(icon: "faceid", color: AppTheme.emeraldLight, title: "Biometric Protection", desc: "Face ID / Touch ID authentication with automatic privacy shield.")
                        featureRow(icon: "target", color: AppTheme.purple, title: "Customizable Buckets", desc: "Create, customize, edit, and delete dedicated financial goals.")
                        featureRow(icon: "speaker.wave.2.fill", color: AppTheme.cyan, title: "Fintech Audio Chimes", desc: "Acoustic audio cues synthesized for deposit milestones.")
                        featureRow(icon: "viewfinder", color: AppTheme.amberGold, title: "Responsive Layout", desc: "Dynamic edge-to-edge resolution scaling across all iOS devices.")
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)

                    // Footer
                    Text("© 2026 Sagar Thapa. All rights reserved.")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.emeraldLight)
                }
            }
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}
