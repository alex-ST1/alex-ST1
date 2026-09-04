import SwiftUI

/// Main Overview Dashboard view containing the Hero card, Spline chart, Donut chart, and metrics.
public struct DashboardView: View {

    @StateObject public var viewModel = DashboardViewModel()
    @State private var selectedTab: Int = 0
    @State private var isAboutPresented: Bool = false

    #if os(iOS)
    private var headerPlacement: ToolbarItemPlacement { .topBarLeading }
    #else
    private var headerPlacement: ToolbarItemPlacement { .navigation }
    #endif

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Overview Dashboard
            overviewTab
                .tabItem {
                    Label("Dashboard", systemImage: "wallet.pass.fill")
                }
                .tag(0)

            // Tab 2: Monthly Archive
            MonthlyArchiveView(viewModel: viewModel)
                .tabItem {
                    Label("Monthly", systemImage: "calendar")
                }
                .tag(1)

            // Tab 3: Dedicated Funds
            DedicatedBucketsView(viewModel: viewModel)
                .tabItem {
                    Label("Buckets", systemImage: "target")
                }
                .tag(2)

            // Tab 4: Activity & Audit Log
            ActivityLedgerView(viewModel: viewModel)
                .tabItem {
                    Label("Activity", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            // Tab 5: Security & Privacy Settings
            SecuritySettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Security", systemImage: "lock.shield.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.emeraldLight)
        .sheet(isPresented: $viewModel.isAddModalPresented) {
            AddDepositSheet(viewModel: viewModel, initialBucketId: viewModel.selectedBucketForModal)
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SavingsTrackerDidUnlockWithPendingDeepLink"))) { notification in
            if let url = notification.object as? URL {
                handleDeepLink(url)
            }
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greetingHeader

                    HeroSavingsCard(
                        metrics: viewModel.metrics,
                        isHighlighted: viewModel.isHeroCardHighlighted,
                        onQuickAdd: { amount in
                            viewModel.quickDeposit(amount: amount, bucketId: "emergency")
                        }
                    )

                    SplineChartView(
                        records: viewModel.monthlyRecords,
                        currency: viewModel.metrics.currency,
                        targetGoal: viewModel.metrics.currentGoal,
                        selectedTimeframe: $viewModel.selectedTimeframe
                    )

                    DonutChartView(
                        goals: viewModel.goals,
                        currency: viewModel.metrics.currency
                    )

                    metricsGrid
                    recentDepositsSection
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: headerPlacement) {
                    toolbarBrand
                }

                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppTheme.playTapSound()
                        isAboutPresented = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                #endif
            }
            .alert("Remove Entry?", isPresented: $viewModel.isDeleteTxConfirmationPresented) {
                Button("Cancel", role: .cancel) {}
                Button("Remove Entry", role: .destructive) {
                    viewModel.confirmDeleteTransaction()
                }
            } message: {
                if let tx = viewModel.transactionToDelete {
                    Text("Are you sure you want to remove this deposit of \(viewModel.metrics.currency.format(amount: tx.amount)) from \(tx.bucketName)? This will recalculate your balances and progress.")
                } else {
                    Text("Are you sure you want to remove this entry? This will recalculate your balances.")
                }
            }
        }
    }

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.emeraldLight)
                        .font(.system(size: 11, weight: .bold))
                    Text("WEALTH GROWTH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.emeraldLight)
                        .tracking(0.6)
                }
                Text("Overview")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                AppTheme.playTapSound()
                viewModel.selectedBucketForModal = "emergency"
                viewModel.isAddModalPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Deposit")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var toolbarBrand: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.emerald, AppTheme.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Text("₹")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Savings Vault")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MONTHLY AVERAGE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.metrics.currency.format(amount: viewModel.metrics.avgMonthly))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    Text("/mo")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }

                Text("Based on historical data")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTED ANNUAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)

                Text(viewModel.metrics.currency.format(amount: viewModel.metrics.projectedAnnual))
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(AppTheme.emeraldLight)
                    .monospacedDigit()

                Text("Estimated year-end total")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
        }
    }

    private var recentDepositsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Deposits")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("See All") {
                    selectedTab = 3
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            }

            if viewModel.transactions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("No deposits recorded")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Tap '+ Deposit' above to log your first deposit.")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(viewModel.transactions.prefix(3)) { tx in
                    recentDepositRow(tx)
                }
            }
        }
    }

    private func recentDepositRow(_ tx: SavingsTransaction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.emerald.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.emeraldLight)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.note)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text("\(tx.bucketName) • \(tx.date.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text("+\(viewModel.metrics.currency.format(amount: tx.amount))")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(AppTheme.emeraldLight)
                .monospacedDigit()

            Button {
                viewModel.promptDeleteTransaction(tx)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.rose.opacity(0.85))
                    .padding(6)
                    .background(AppTheme.rose.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.promptDeleteTransaction(tx)
            } label: {
                Label("Remove Deposit Entry", systemImage: "trash")
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        let route = (url.host ?? "").lowercased()
        switch route {
        case "dashboard":
            selectedTab = 0
        case "monthly", "archive":
            selectedTab = 1
        case "buckets", "goals":
            selectedTab = 2
        case "activity", "ledger":
            selectedTab = 3
        case "security", "settings":
            selectedTab = 4
        case "deposit":
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !path.isEmpty {
                viewModel.selectedBucketForModal = path
            }
            viewModel.isAddModalPresented = true
        default:
            selectedTab = 0
        }
    }
}
