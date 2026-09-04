import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Design System for Fintech Aesthetics, Glassmorphic Materials & Haptics.
public enum AppTheme {

    // MARK: - Color Palette
    public static let background = Color(hex: "#090C15")
    public static let cardBackground = Color(hex: "#151B28").opacity(0.72)
    public static let cardBorder = Color.white.opacity(0.08)
    public static let cardBorderHighlight = Color(hex: "#10B981").opacity(0.4)

    // Accents
    public static let emerald = Color(hex: "#10B981")
    public static let emeraldDark = Color(hex: "#059669")
    public static let emeraldLight = Color(hex: "#34D399")
    public static let blue = Color(hex: "#3B82F6")
    public static let cyan = Color(hex: "#06B6D4")
    public static let purple = Color(hex: "#A855F7")
    public static let amber = Color(hex: "#F59E0B")
    public static let roseRed = Color(hex: "#FB7185")

    // Text
    public static let textPrimary = Color(hex: "#F8FAFC")
    public static let textSecondary = Color(hex: "#94A3B8")
    public static let textMuted = Color(hex: "#64748B")

    // MARK: - Audio & Haptic Feedback
    #if os(iOS)
    public typealias ImpactFeedbackStyle = UIImpactFeedbackGenerator.FeedbackStyle
    public typealias NotificationFeedbackType = UINotificationFeedbackGenerator.FeedbackType

    public static func triggerHaptic(style: ImpactFeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func triggerNotificationHaptic(type: NotificationFeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    public static func playDepositSound() {
        SoundService.shared.playDepositSound()
        triggerNotificationHaptic(type: .success)
    }

    public static func playTapSound() {
        SoundService.shared.playTapSound()
        triggerHaptic(style: .light)
    }

    public static func playCelebrationSound() {
        SoundService.shared.playCelebrationSound()
        triggerNotificationHaptic(type: .success)
    }

    public static func playDeleteSound() {
        SoundService.shared.playDeleteSound()
        triggerNotificationHaptic(type: .warning)
    }
    #else
    public enum ImpactFeedbackStyle {
        case light, medium, heavy, soft, rigid
    }
    public enum NotificationFeedbackType {
        case success, warning, error
    }

    public static func triggerHaptic(style: ImpactFeedbackStyle = .medium) {}
    public static func triggerNotificationHaptic(type: NotificationFeedbackType = .success) {}
    public static func playDepositSound() {}
    public static func playTapSound() {}
    public static func playCelebrationSound() {}
    public static func playDeleteSound() {}
    #endif
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Glassmorphic Card ViewModifier
public struct GlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 24
    public var isHighlighted: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isHighlighted ? AppTheme.emerald : AppTheme.cardBorder,
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
                    .shadow(
                        color: isHighlighted ? AppTheme.emerald.opacity(0.35) : .clear,
                        radius: 12,
                        x: 0,
                        y: 0
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    public func glassCard(cornerRadius: CGFloat = 24, isHighlighted: Bool = false) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }

    @ViewBuilder
    public func darkNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }
}
