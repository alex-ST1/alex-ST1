import SwiftUI

/// Audit trail of transactions and preference configuration.
public struct ActivityLedgerView: View {

    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Title & Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activity & Audit")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)

                        Text("Transaction history, currency selection, and audit ledger.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 4)

                    // Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CURRENCY PREFERENCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        HStack(spacing: 8) {
                            ForEach(CurrencyType.allCases, id: \.self) { cur in
                                let isSelected = viewModel.metrics.currency == cur
                                Button {
                                    AppTheme.playTapSound()
                                    viewModel.updateCurrency(cur)
                                } label: {
                                    Text("\(cur.symbol) \(cur.rawValue)")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected
                                                ? AppTheme.emerald.opacity(0.2)
                                                : Color.white.opacity(0.06)
                                        )
                                        .foregroundColor(
                                            isSelected
                                                ? AppTheme.emeraldLight
                                                : AppTheme.textSecondary
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    isSelected
                                                        ? AppTheme.emerald
                                                        : Color.white.opacity(0.08),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 18)

                    // Transactions Audit List
                    Text("TRANSACTION AUDIT LOG (\(viewModel.transactions.count))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.6)
                        .padding(.top, 4)

                    if viewModel.transactions.isEmpty {
                        Text("No transactions recorded yet.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    } else {
                        ForEach(viewModel.transactions) { tx in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.emerald.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppTheme.emeraldLight)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tx.note)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text("\(tx.bucketName) • \(dateFormatter.string(from: tx.date))")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Text("+\(viewModel.metrics.currency.format(amount: tx.amount))")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(AppTheme.emeraldLight)
                                    .monospacedDigit()
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
