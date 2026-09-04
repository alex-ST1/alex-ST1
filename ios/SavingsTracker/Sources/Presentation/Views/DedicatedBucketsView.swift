import SwiftUI

/// Dedicated Savings Buckets and Goals with individual progress meters.
public struct DedicatedBucketsView: View {

    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Track allocation and milestones across dedicated funds.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)

                    ForEach(viewModel.goals) { goal in
                        let isHighlighted = viewModel.highlightedBucketId == goal.id

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: goal.colorHex).opacity(0.18))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color(hex: goal.colorHex).opacity(0.35), lineWidth: 1)
                                            )

                                        Image(systemName: goal.iconName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(hex: goal.colorHex))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(goal.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(goal.category)
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    AppTheme.triggerHaptic(style: .light)
                                    viewModel.selectedBucketForModal = goal.id
                                    viewModel.isAddModalPresented = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("Deposit")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }

                            // Saved Amount and Percentage
                            HStack {
                                HStack(spacing: 4) {
                                    Text("Saved:")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(viewModel.metrics.currency.format(amount: goal.current))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }

                                Spacer()

                                Text("\(goal.progressPercentage)%")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(Color(hex: goal.colorHex))
                                    .monospacedDigit()
                            }

                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(Color(hex: goal.colorHex))
                                        .frame(
                                            width: geometry.size.width * CGFloat(min(1.0, Double(goal.progressPercentage) / 100.0)),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)

                            // Target and Remaining
                            HStack {
                                Text("Target: \(viewModel.metrics.currency.format(amount: goal.target))")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("Remaining: \(viewModel.metrics.currency.format(amount: goal.remainingAmount))")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 22, isHighlighted: isHighlighted)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dedicated Funds")
        }
    }
}
