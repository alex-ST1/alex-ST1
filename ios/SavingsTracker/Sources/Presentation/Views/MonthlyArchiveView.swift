import SwiftUI

/// Displays month-by-month historical savings records and progression with swipe-to-delete support.
public struct MonthlyArchiveView: View {

    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.monthlyRecords.isEmpty {
                    emptyArchiveView
                } else {
                    recordsListView
                }
            }
            .navigationTitle("Monthly Archive")
            .darkNavigationBar()
            .alert("Delete Monthly Record?", isPresented: $viewModel.isDeleteMonthRecordConfirmationPresented) {
                Button("Cancel", role: .cancel) {
                    viewModel.monthRecordToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDeleteMonthlyRecord()
                }
            } message: {
                if let rec = viewModel.monthRecordToDelete {
                    Text("Delete the historical record for \(rec.shortLabel)? This will immediately update your Monthly Average and Projected Annual metrics.")
                } else {
                    Text("Are you sure you want to delete this historical record?")
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyArchiveView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.emerald.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.emeraldLight)
            }

            VStack(spacing: 6) {
                Text("No Historical Records")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("Monthly performance records will appear here as you deposit savings entries.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var recordsListView: some View {
        List {
            // Header Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Historical Performance")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.6)
                Text("Swipe left on any month to delete history and refresh averages.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 8, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Reversed list: newest month first
            ForEach(viewModel.monthlyRecords.reversed()) { record in
                monthlyRecordRow(record)
                    .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.promptDeleteMonthlyRecord(record)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.promptDeleteMonthlyRecord(record)
                        } label: {
                            Label("Delete Month Record", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func monthlyRecordRow(_ record: MonthlyRecord) -> some View {
        let isCurrent = record.period == viewModel.currentPeriod

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

                    if record.goal > 0 {
                        Text("Target: \(viewModel.metrics.currency.format(amount: record.goal))")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("Monthly Savings")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.metrics.currency.format(amount: record.saved))
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(AppTheme.emeraldLight)
                            .monospacedDigit()

                        if record.goal > 0 {
                            Text("\(record.progressPercentage)% Saved")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Text("Total Deposited")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    // Direct red trash button
                    Button {
                        viewModel.promptDeleteMonthlyRecord(record)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.roseRed.opacity(0.85))
                            .padding(8)
                            .background(AppTheme.roseRed.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
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
