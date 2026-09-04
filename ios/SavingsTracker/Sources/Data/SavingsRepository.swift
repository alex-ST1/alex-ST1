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

    /// Clean initial snapshot with no sample data so user can enter actual entries.
    public static func createInitialSnapshot() -> SavingsSnapshot {
        return SavingsSnapshot(
            currency: .inr,
            currentPeriod: "2026-09",
            monthlyGoal: 0,
            monthlyRecords: [:],
            goals: [],
            transactions: []
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
        let progressPercent: Int

        if totalBucketTargets > 0 {
            currentGoal = totalBucketTargets
            let ratio = (totalSavings as NSDecimalNumber).doubleValue / (totalBucketTargets as NSDecimalNumber).doubleValue
            progressPercent = min(100, max(0, Int((ratio * 100).rounded())))
            let currentRecord = snapshot.monthlyRecords[snapshot.currentPeriod]
            currentSaved = currentRecord?.saved ?? 0
        } else if snapshot.monthlyGoal > 0 {
            currentGoal = snapshot.monthlyGoal
            let currentRecord = snapshot.monthlyRecords[snapshot.currentPeriod]
            currentSaved = currentRecord?.saved ?? 0
            let ratio = (currentSaved as NSDecimalNumber).doubleValue / (currentGoal as NSDecimalNumber).doubleValue
            progressPercent = min(100, max(0, Int((ratio * 100).rounded())))
        } else {
            currentGoal = 0
            progressPercent = 0
            currentSaved = snapshot.monthlyRecords[snapshot.currentPeriod]?.saved ?? 0
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
        let remainingMonths = max(0, 12 - allSaved.count)
        let projectedAnnual = allSaved.isEmpty ? Decimal(0) : (sumSaved + (avgMonthly * Decimal(remainingMonths)))

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

    /// Adds a validated deposit to a specific bucket with an optional custom date, updating records and trajectories.
    public func addDeposit(amount: Decimal, bucketId: String, note: String, date: Date = Date()) -> SavingsTransaction {
        let period = period(for: date)
        let totalBucketTargets = snapshot.goals.reduce(Decimal(0)) { $0 + $1.target }
        let targetGoal = totalBucketTargets > 0 ? totalBucketTargets : snapshot.monthlyGoal

        // 1. Update Monthly Record for the specific transaction date's period
        if var record = snapshot.monthlyRecords[period] {
            record.saved += amount
            if record.goal == 0 && targetGoal > 0 {
                record.goal = targetGoal
            }
            snapshot.monthlyRecords[period] = record
        } else {
            let newRecord = MonthlyRecord(period: period, saved: amount, goal: targetGoal)
            snapshot.monthlyRecords[period] = newRecord
        }

        // 2. Update Goal Bucket
        var targetBucketId = bucketId
        var bucketName = "General Savings"
        if snapshot.goals.isEmpty {
            let autoBucket = SavingsGoal(
                id: "general",
                name: "General Savings",
                target: max(amount, 50000),
                current: amount,
                colorHex: "#10B981",
                iconName: "vault.fill",
                category: "Savings"
            )
            snapshot.goals.append(autoBucket)
            targetBucketId = autoBucket.id
            bucketName = autoBucket.name
        } else if let idx = snapshot.goals.firstIndex(where: { $0.id == bucketId }) {
            snapshot.goals[idx].current += amount
            bucketName = snapshot.goals[idx].name
        } else {
            snapshot.goals[0].current += amount
            targetBucketId = snapshot.goals[0].id
            bucketName = snapshot.goals[0].name
        }

        // 3. Create Transaction with chosen date
        let tx = SavingsTransaction(
            date: date,
            amount: amount,
            bucketId: targetBucketId,
            bucketName: bucketName,
            note: note.isEmpty ? "Quick Deposit" : note
        )
        snapshot.transactions.append(tx)
        snapshot.transactions.sort { $0.date > $1.date }

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
            for key in snapshot.monthlyRecords.keys {
                snapshot.monthlyRecords[key]?.saved = 0
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

    /// Deletes a monthly history record by period (e.g. "2026-08") and updates persisted state.
    public func deleteMonthlyRecord(period: String) -> Bool {
        guard snapshot.monthlyRecords[period] != nil else { return false }
        snapshot.monthlyRecords.removeValue(forKey: period)
        saveData()
        SecureLogger.finance.info("Deleted monthly history record for period: \(period, privacy: .public)")
        return true
    }

    public func resetToDefaults() {
        self.snapshot = SavingsRepository.createInitialSnapshot()
        saveData()
    }
}
