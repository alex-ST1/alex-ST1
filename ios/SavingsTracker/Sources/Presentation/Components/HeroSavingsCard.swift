import SwiftUI

/// Overview Hero Card displaying total wealth, monthly progress, and quick-add actions.
public struct HeroSavingsCard: View {

    public let metrics: FinancialMetrics
    public let isHighlighted: Bool
    public let onQuickAdd: (Decimal) -> Void

    public init(
        metrics: FinancialMetrics,
        isHighlighted: Bool = false,
        onQuickAdd: @escaping (Decimal) -> Void
    ) {
        self.metrics = metrics
        self.isHighlighted = isHighlighted
        self.onQuickAdd = onQuickAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Row: Total Savings + MoM Pill Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL ACCUMULATED SAVINGS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.6)

                    Text(metrics.currency.format(amount: metrics.totalSavings))
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Spacer()

                // MoM Rate Badge
                HStack(spacing: 4) {
                    Image(systemName: metrics.momRate >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(metrics.momRate >= 0 ? "+" : "")\(metrics.momRate)% MoM")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    metrics.momRate >= 0
                        ? AppTheme.emerald.opacity(0.16)
                        : AppTheme.blue.opacity(0.16)
                )
                .foregroundColor(
                    metrics.momRate >= 0
                        ? AppTheme.emeraldLight
                        : AppTheme.blue
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            metrics.momRate >= 0
                                ? AppTheme.emerald.opacity(0.3)
                                : AppTheme.blue.opacity(0.3),
                            lineWidth: 1
                        )
                )
            }

            // Monthly Target Row (Rock-Solid Layout)
            VStack(spacing: 8) {
                Divider()
                    .background(Color.white.opacity(0.1))

                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.emeraldLight)
                            .font(.system(size: 12))
                        Text("September Savings")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(metrics.currency.format(amount: metrics.currentMonthSaved))
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text("/ \(metrics.currency.format(amount: metrics.currentGoal))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Rounded Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.emerald, AppTheme.emeraldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(min(1.0, Double(metrics.progressPercent) / 100.0)),
                                height: 10
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: metrics.progressPercent)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("Target: \(metrics.currency.format(amount: metrics.currentGoal))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(metrics.progressPercent)% of Goal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.emeraldLight)
                        .monospacedDigit()
                }
            }

            // Quick Add Shortcut Buttons
            HStack(spacing: 10) {
                Button {
                    AppTheme.triggerHaptic(style: .medium)
                    onQuickAdd(1000)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("+\(metrics.currency.symbol)1,000 Quick Add")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.emerald, AppTheme.emerald.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: AppTheme.emerald.opacity(0.35), radius: 6, y: 3)
                }

                Button {
                    AppTheme.triggerHaptic(style: .medium)
                    onQuickAdd(2500)
                } label: {
                    Text("+\(metrics.currency.symbol)2,500")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.emerald.opacity(0.18),
                            AppTheme.cardBackground
                        ],
                        center: .topLeading,
                        startRadius: 20,
                        endRadius: 260
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    isHighlighted ? AppTheme.emeraldLight : AppTheme.emerald.opacity(0.25),
                    lineWidth: isHighlighted ? 2 : 1
                )
                .shadow(
                    color: isHighlighted ? AppTheme.emerald.opacity(0.6) : .clear,
                    radius: isHighlighted ? 18 : 0
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }
}
