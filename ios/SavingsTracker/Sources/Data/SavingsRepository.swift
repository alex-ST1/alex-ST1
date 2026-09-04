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
        if let loaded = try? storage.loadDecrypted(SavingsSnapshot.self, from: "savings_vault_v1.enc") {
            self.snapshot = loaded
        } else {
            self.snapshot = SavingsRepository.createInitialSnapshot()
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

    private func period(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    public func getFinancialMetrics() -> FinancialMetrics {
        let totalSavings = snapshot.goals.reduce(Decimal(0)) { $0 + $1.current }
        let totalBucketTargets = snapshot.goals.reduce(Decimal(0)) { $0 + $1.target }
        let activeBucketsCount = snapshot.goals.count

        let currentSaved: Decimal
        let currentGoal: Decimal

        if snapshot.goals.isEmpty {
            currentSaved = 0
            currentGoal = 0
        } else {
            let currentRecord = snapshot.monthlyRecords[snapshot.currentPeriod]
            currentSaved = currentRecord?.saved ?? 0
            let rawGoal = currentRecord?.goal ?? snapshot.monthlyGoal
            currentGoal = totalBucketTargets > 0 ? min(rawGoal, totalBucketTargets) : rawGoal
        }

        let progressPercent: Int
        if currentGoal > 0 {
            let ratio = (currentSaved as NSDecimalNumber).doubleValue / (currentGoal as NSDecimalNumber).doubleValue
            progressPercent = min(100, max(0, Int((ratio * 100).rounded())))
        } else {
            progressPercent = 0
        }

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
            currency: snapshot.currency,
            totalBucketTargets: totalBucketTargets,
            activeBucketsCount: activeBucketsCount
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

    // MARK: - Goal / Bucket Management

    /// Creates a new custom savings bucket.
    @discardableResult
    public func createGoal(
        name: String,
        target: Decimal,
        colorHex: String,
        iconName: String,
        category: String
    ) -> SavingsGoal {
        let newGoal = SavingsGoal(
            id: UUID().uuidString.lowercased(),
            name: name,
            target: target,
            current: 0,
            colorHex: colorHex,
            iconName: iconName,
            category: category
        )
        snapshot.goals.append(newGoal)
        saveData()
        SecureLogger.finance.info("Custom savings bucket created: \(name, privacy: .public)")
        return newGoal
    }

    /// Updates an existing savings bucket's metadata and target.
    @discardableResult
    public func updateGoal(
        id: String,
        name: String,
        target: Decimal,
        colorHex: String,
        iconName: String,
        category: String
    ) -> Bool {
        guard let idx = snapshot.goals.firstIndex(where: { $0.id == id }) else {
            return false
        }
        snapshot.goals[idx].name = name
        snapshot.goals[idx].target = target
        snapshot.goals[idx].colorHex = colorHex
        snapshot.goals[idx].iconName = iconName
        snapshot.goals[idx].category = category

        // Sync bucket name on existing transactions
        for i in 0..<snapshot.transactions.count {
            if snapshot.transactions[i].bucketId == id {
                snapshot.transactions[i].bucketName = name
            }
        }

        saveData()
        SecureLogger.finance.info("Custom savings bucket updated: \(name, privacy: .public)")
        return true
    }

    /// Deletes a specific transaction by ID, adjusts bucket balances and monthly records, and persists.
    @discardableResult
    public func deleteTransaction(id: String) -> Bool {
        guard let idx = snapshot.transactions.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let tx = snapshot.transactions.remove(at: idx)

        // 1. Decrement Goal Bucket
        if let gIdx = snapshot.goals.firstIndex(where: { $0.id == tx.bucketId }) {
            snapshot.goals[gIdx].current = max(0, snapshot.goals[gIdx].current - tx.amount)
        }

        // 2. Decrement Monthly Record
        let txPeriod = period(for: tx.date)
        let targetPeriod = snapshot.monthlyRecords[txPeriod] != nil ? txPeriod : snapshot.currentPeriod
        if var record = snapshot.monthlyRecords[targetPeriod] {
            record.saved = max(0, record.saved - tx.amount)
            snapshot.monthlyRecords[targetPeriod] = record
        }

        saveData()
        SecureLogger.finance.info("Transaction deleted: \(tx.id, privacy: .public), amount: \(tx.amount, privacy: .public)")
        return true
    }

    /// Clears all recorded transactions and resets current bucket balances.
    public func clearAllTransactions() {
        snapshot.transactions.removeAll()
        for i in 0..<snapshot.goals.count {
            snapshot.goals[i].current = 0
        }
        if var record = snapshot.monthlyRecords[snapshot.currentPeriod] {
            record.saved = 0
            snapshot.monthlyRecords[snapshot.currentPeriod] = record
        }
        saveData()
        SecureLogger.finance.info("All transactions cleared and bucket balances reset.")
    }

    /// Deletes a savings bucket and safely reassigns or clears transactions.
    @discardableResult
    public func deleteGoal(id: String) -> Bool {
        guard let idx = snapshot.goals.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let deletedGoal = snapshot.goals.remove(at: idx)

        // If no buckets remain, clear all transactions and reset monthly savings
        if snapshot.goals.isEmpty {
            snapshot.transactions.removeAll()
            if var currentRec = snapshot.monthlyRecords[snapshot.currentPeriod] {
                currentRec.saved = 0
                snapshot.monthlyRecords[snapshot.currentPeriod] = currentRec
            }
            saveData()
            SecureLogger.finance.info("All savings buckets removed. Cleared all related transactions and reset calculations.")
            return true
        }

        // Find fallback bucket (first remaining bucket or General)
        let fallback = snapshot.goals.first
        let fallbackId = fallback?.id ?? "general"
        let fallbackName = fallback?.name ?? "General Savings"

        // If the deleted goal had saved funds, migrate funds to the fallback bucket
        if deletedGoal.current > 0, let fIdx = snapshot.goals.firstIndex(where: { $0.id == fallbackId }) {
            snapshot.goals[fIdx].current += deletedGoal.current
        }

        // Reassign transactions
        for i in 0..<snapshot.transactions.count {
            if snapshot.transactions[i].bucketId == id {
                snapshot.transactions[i].bucketId = fallbackId
                snapshot.transactions[i].bucketName = fallbackName
            }
        }

        saveData()
        SecureLogger.finance.info("Custom savings bucket deleted: \(deletedGoal.name, privacy: .public)")
        return true
    }

    public func resetToDefaults() {
        self.snapshot = SavingsRepository.createInitialSnapshot()
        saveData()
    }
}
