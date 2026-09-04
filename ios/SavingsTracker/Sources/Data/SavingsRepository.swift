import Foundation

/// Data container serialized to encrypted storage.
public struct SavingsSnapshot: Codable, Sendable {
    public var currency: CurrencyType
    public var currentPeriod: String
    public var monthlyGoal: Decimal
    public var monthlyRecords: [String: MonthlyRecord]
    public var goals: [SavingsGoal]
    public var transactions: [SavingsTransaction]
}

/// Actor-based, thread-safe repository managing savings data and encrypted persistence.
public actor SavingsRepository {

    public static let shared = SavingsRepository()

    private let storage: SecureStorageService
    private let storageFilename = "savings_vault_v1.enc"

    private var snapshot: SavingsSnapshot

    public init(storage: SecureStorageService = .shared) {
        self.storage = storage
        self.snapshot = SavingsRepository.createInitialSnapshot()
        Task {
            await self.loadData()
        }
    }

    /// Default sample data matching our production INR settings.
    public static func createInitialSnapshot() -> SavingsSnapshot {
        let defaultGoals: [SavingsGoal] = [
            SavingsGoal(
                id: "emergency",
                name: "Emergency Fund",
                target: 200_000,
                current: 145_000,
                colorHex: "#10B981",
                iconName: "shield.fill",
                category: "Safety"
            ),
            SavingsGoal(
                id: "investments",
                name: "Mutual Funds & SIP",
                target: 150_000,
                current: 95_000,
                colorHex: "#3B82F6",
                iconName: "chart.line.uptrend.xyaxis",
                category: "Wealth"
            ),
            SavingsGoal(
                id: "travel",
                name: "Goa & Ladakh Trip",
                target: 60_000,
                current: 42_000,
                colorHex: "#06B6D4",
                iconName: "airplane",
                category: "Leisure"
            ),
            SavingsGoal(
                id: "tech",
                name: "Workstation & Tech",
                target: 50_000,
                current: 32_000,
                colorHex: "#A855F7",
                iconName: "laptopcomputer",
                category: "Gadgets"
            )
        ]

        let initialHistory: [String: MonthlyRecord] = [
            "2026-01": MonthlyRecord(period: "2026-01", saved: 18_000, goal: 20_000, income: 65_000, expenses: 47_000),
            "2026-02": MonthlyRecord(period: "2026-02", saved: 22_000, goal: 20_000, income: 65_000, expenses: 43_000),
            "2026-03": MonthlyRecord(period: "2026-03", saved: 25_000, goal: 25_000, income: 70_000, expenses: 45_000),
            "2026-04": MonthlyRecord(period: "2026-04", saved: 21_000, goal: 25_000, income: 68_000, expenses: 47_000),
            "2026-05": MonthlyRecord(period: "2026-05", saved: 28_000, goal: 25_000, income: 75_000, expenses: 47_000),
            "2026-06": MonthlyRecord(period: "2026-06", saved: 30_000, goal: 25_000, income: 78_000, expenses: 48_000),
            "2026-07": MonthlyRecord(period: "2026-07", saved: 26_000, goal: 25_000, income: 72_000, expenses: 46_000),
            "2026-08": MonthlyRecord(period: "2026-08", saved: 32_000, goal: 25_000, income: 80_000, expenses: 48_000),
            "2026-09": MonthlyRecord(period: "2026-09", saved: 18_500, goal: 25_000, income: 75_000, expenses: 56_500)
        ]

        let initialTxs: [SavingsTransaction] = [
            SavingsTransaction(amount: 5_000, bucketId: "emergency", bucketName: "Emergency Fund", note: "Monthly salary allocation"),
            SavingsTransaction(amount: 2_500, bucketId: "travel", bucketName: "Goa & Ladakh Trip", note: "Weekend savings deposit"),
            SavingsTransaction(amount: 6_000, bucketId: "investments", bucketName: "Mutual Funds & SIP", note: "Monthly SIP auto-debit"),
            SavingsTransaction(amount: 3_500, bucketId: "tech", bucketName: "Workstation & Tech", note: "Freelance project milestone"),
            SavingsTransaction(amount: 8_000, bucketId: "emergency", bucketName: "Emergency Fund", note: "Performance bonus")
        ]

        return SavingsSnapshot(
            currency: .inr,
            currentPeriod: "2026-09",
            monthlyGoal: 25_000,
            monthlyRecords: initialHistory,
            goals: defaultGoals,
            transactions: initialTxs
        )
    }

    /// Loads encrypted snapshot from disk.
    public func loadData() {
        do {
            self.snapshot = try storage.loadDecrypted(SavingsSnapshot.self, from: storageFilename)
            SecureLogger.storage.info("Decrypted savings vault loaded successfully.")
        } catch {
            SecureLogger.storage.notice("No existing vault found or failed to decrypt; initializing default vault.")
            self.snapshot = SavingsRepository.createInitialSnapshot()
            saveData()
        }
    }

    /// Persists encrypted snapshot to disk.
    private func saveData() {
        do {
            try storage.saveEncrypted(snapshot, to: storageFilename)
            SecureLogger.storage.debug("Saved encrypted savings snapshot.")
        } catch {
            SecureLogger.storage.error("Failed to save encrypted vault: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Queries

    public func getSnapshot() -> SavingsSnapshot {
        return snapshot
    }

    public func getGoals() -> [SavingsGoal] {
        return snapshot.goals
    }

    public func getTransactions() -> [SavingsTransaction] {
        return snapshot.transactions
    }

    public func getMonthlyRecords() -> [MonthlyRecord] {
        return snapshot.monthlyRecords.values.sorted { $0.period < $1.period }
    }

    public func getFinancialMetrics() -> FinancialMetrics {
        let totalSavings = snapshot.goals.reduce(Decimal(0)) { $0 + $1.current }
        let currentRecord = snapshot.monthlyRecords[snapshot.currentPeriod]
        let currentSaved = currentRecord?.saved ?? 0
        let currentGoal = currentRecord?.goal ?? snapshot.monthlyGoal

        let progressPercent = currentGoal > 0
            ? min(100, Int(((currentSaved as NSDecimalNumber).doubleValue / (currentGoal as NSDecimalNumber).doubleValue * 100).rounded()))
            : 0

        // Calculate Month-over-Month change
        let sortedPeriods = snapshot.monthlyRecords.keys.sorted()
        var momRate = 0
        if let curIdx = sortedPeriods.firstIndex(of: snapshot.currentPeriod), curIdx > 0 {
            let prevPeriod = sortedPeriods[curIdx - 1]
            if let prevSaved = snapshot.monthlyRecords[prevPeriod]?.saved, prevSaved > 0 {
                let diff = (currentSaved - prevSaved) as NSDecimalNumber
                let base = prevSaved as NSDecimalNumber
                momRate = Int((diff.doubleValue / base.doubleValue * 100).rounded())
            }
        }

        let allSaved = snapshot.monthlyRecords.values.map { $0.saved }
        let sumSaved = allSaved.reduce(Decimal(0), +)
        let avgMonthly = allSaved.isEmpty ? Decimal(0) : sumSaved / Decimal(allSaved.count)
        let projectedAnnual = sumSaved + (avgMonthly * 3)

        return FinancialMetrics(
            totalSavings: totalSavings,
            currentMonthSaved: currentSaved,
            currentGoal: currentGoal,
            progressPercent: progressPercent,
            momRate: momRate,
            avgMonthly: avgMonthly,
            projectedAnnual: projectedAnnual,
            currency: snapshot.currency
        )
    }

    // MARK: - Mutations

    /// Adds a validated deposit to a specific bucket and updates current month records.
    public func addDeposit(amount: Decimal, bucketId: String, note: String) -> SavingsTransaction {
        let period = snapshot.currentPeriod

        // 1. Update Monthly Record
        if var record = snapshot.monthlyRecords[period] {
            record.saved += amount
            snapshot.monthlyRecords[period] = record
        } else {
            let newRecord = MonthlyRecord(period: period, saved: amount, goal: snapshot.monthlyGoal)
            snapshot.monthlyRecords[period] = newRecord
        }

        // 2. Update Goal Bucket
        var bucketName = "General Savings"
        if let idx = snapshot.goals.firstIndex(where: { $0.id == bucketId }) {
            snapshot.goals[idx].current += amount
            bucketName = snapshot.goals[idx].name
        }

        // 3. Create Transaction
        let tx = SavingsTransaction(
            amount: amount,
            bucketId: bucketId,
            bucketName: bucketName,
            note: note.isEmpty ? "Quick Deposit" : note
        )
        snapshot.transactions.insert(tx, at: 0)

        // Persist
        saveData()
        return tx
    }

    public func updateCurrency(_ newCurrency: CurrencyType) {
        snapshot.currency = newCurrency
        saveData()
    }

    public func updateMonthlyGoal(_ newGoal: Decimal) {
        snapshot.monthlyGoal = newGoal
        if var record = snapshot.monthlyRecords[snapshot.currentPeriod] {
            record.goal = newGoal
            snapshot.monthlyRecords[snapshot.currentPeriod] = record
        }
        saveData()
    }

    public func resetToDefaults() {
        self.snapshot = SavingsRepository.createInitialSnapshot()
        saveData()
    }
}
