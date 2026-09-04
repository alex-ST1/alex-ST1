import SwiftUI

/// Asset Allocation Donut Chart with guaranteed non-overflowing legend.
public struct DonutChartView: View {

    public let goals: [SavingsGoal]
    public let currency: CurrencyType

    public init(goals: [SavingsGoal], currency: CurrencyType) {
        self.goals = goals
        self.currency = currency
    }

    private var totalSavings: Decimal {
        goals.reduce(Decimal(0)) { $0 + $1.current }
    }

    private var segments: [(goal: SavingsGoal, startRatio: Double, endRatio: Double, percentage: Int)] {
        let totalDouble = (totalSavings as NSDecimalNumber).doubleValue
        guard totalDouble > 0 else { return [] }

        var currentOffset = 0.0
        var result: [(goal: SavingsGoal, startRatio: Double, endRatio: Double, percentage: Int)] = []

        for goal in goals {
            let val = (goal.current as NSDecimalNumber).doubleValue
            let ratio = val / totalDouble
            let start = currentOffset
            let end = currentOffset + ratio
            currentOffset = end
            let pct = Int((ratio * 100).rounded())
            result.append((goal, start, end, pct))
        }

        return result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(AppTheme.blue)
                        .font(.system(size: 14, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Asset Allocation")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Distribution across savings buckets")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
            }

            if goals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textMuted)
                    Text("No Active Buckets")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Create savings buckets to see your asset distribution.")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if totalSavings == 0 {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 12)
                        VStack(spacing: 2) {
                            Text("TOTAL")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                            Text(currency.format(amount: 0))
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.white)
                            Text("0% Saved")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .frame(width: 126, height: 126)
                    .flexShrinkZero()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Buckets Created")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(goals.count) active bucket\(goals.count == 1 ? "" : "s") awaiting deposits.")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // Donut + Legend Layout
                HStack(spacing: 16) {
                // Donut Ring (126x126 with 12pt stroke)
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 12)

                    // Color Segments
                    ForEach(segments, id: \.goal.id) { seg in
                        Circle()
                            .trim(from: seg.startRatio, to: seg.endRatio)
                            .stroke(
                                Color(hex: seg.goal.colorHex),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: seg.endRatio)
                    }

                    // Center Labels (Generous padding, perfectly contained)
                    VStack(spacing: 2) {
                        Text("TOTAL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.5)

                        Text(currency.format(amount: totalSavings))
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 4)

                        Text("100% Tracked")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.emeraldLight)
                    }
                }
                .frame(width: 126, height: 126)
                .flexShrinkZero()

                // Legend List
                VStack(spacing: 8) {
                    ForEach(segments, id: \.goal.id) { seg in
                        HStack(alignment: .center, spacing: 6) {
                            // Dot
                            Circle()
                                .fill(Color(hex: seg.goal.colorHex))
                                .frame(width: 8, height: 8)
                                .shadow(color: Color(hex: seg.goal.colorHex).opacity(0.5), radius: 3)

                            // Title
                            Text(seg.goal.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Amount & Percentage
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(currency.format(amount: seg.goal.current))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .monospacedDigit()

                                Text("(\(seg.percentage)%)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .monospacedDigit()
                            }
                            .fixedSize()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            }
        }
        .padding(18)
        .glassCard()
    }
}

extension View {
    func flexShrinkZero() -> some View {
        self.fixedSize(horizontal: true, vertical: true)
    }
}
