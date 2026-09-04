import SwiftUI

/// Main Overview Dashboard view containing the Hero card, Spline chart, Donut chart, and metrics.
public struct DashboardView: View {

    @StateObject public var viewModel = DashboardViewModel()
    @State private var selectedTab: Int = 0

    #if os(iOS)
    private var headerPlacement: ToolbarItemPlacement { .topBarLeading }
    #else
    private var headerPlacement: ToolbarItemPlacement { .navigation }
    #endif

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Overview Dashboard
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Top Greeting Header
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

                        // Hero Savings Card
                        HeroSavingsCard(
                            metrics: viewModel.metrics,
                            isHighlighted: viewModel.isHeroCardHighlighted,
                            onQuickAdd: { amount in
                                viewModel.quickDeposit(amount: amount, bucketId: "emergency")
                            }
                        )

                        // Spline Curve Area Chart
                        SplineChartView(
                            records: viewModel.monthlyRecords,
                            currency: viewModel.metrics.currency,
                            targetGoal: viewModel.metrics.currentGoal,
                            selectedTimeframe: $viewModel.selectedTimeframe
                        )

                        // Asset Allocation Donut Chart
                        DonutChartView(
                            goals: viewModel.goals,
                            currency: viewModel.metrics.currency
                        )

                        // 2-Column Key Financial Metrics Grid
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

                        // Recent Activity Preview
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

                            ForEach(viewModel.transactions.prefix(3)) { tx in
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
                                        Text(tx.bucketName)
                                            .font(.system(size: 10))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text("+\(viewModel.metrics.currency.format(amount: tx.amount))")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(AppTheme.emeraldLight)
                                        .monospacedDigit()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(18)
                }
                .background(AppTheme.background.ignoresSafeArea())
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbarBackground(AppTheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: headerPlacement) {
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
                                Text("September 2026")
                                    .font(.system(size: 9))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .init("SavingsTrackerDidUnlockWithPendingDeepLink"))) { notification in
            if let url = notification.object as? URL {
                handleDeepLink(url)
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
