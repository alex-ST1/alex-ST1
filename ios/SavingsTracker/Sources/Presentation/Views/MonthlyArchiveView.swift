import SwiftUI

/// Displays month-by-month historical savings records and progression.
public struct MonthlyArchiveView: View {

    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Title & Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Archive")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)

                        Text("Historical savings breakdown and target performance.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 4)

                    // Month Records List (Newest First)
                    ForEach(viewModel.monthlyRecords.reversed()) { record in
                        let isCurrent = record.period == "2026-09"

                        VStack(spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(record.shortLabel)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)

                                        if isCurrent {
                                            Text("CURRENT")
                                                .font(.system(size: 9, weight: .black))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.emerald.opacity(0.18))
                                                .foregroundColor(AppTheme.emeraldLight)
                                                .cornerRadius(6)
                                        }
                                    }

                                    Text("Target: \(viewModel.metrics.currency.format(amount: record.goal))")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(viewModel.metrics.currency.format(amount: record.saved))
                                        .font(.system(size: 17, weight: .heavy))
                                        .foregroundColor(AppTheme.emeraldLight)
                                        .monospacedDigit()

                                    Text("\(record.progressPercentage)% Saved")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.emerald, AppTheme.emeraldLight],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geometry.size.width * CGFloat(min(1.0, Double(record.progressPercentage) / 100.0)),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20, isHighlighted: isCurrent)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .darkNavigationBar()
        }
    }
}
