import SwiftUI

/// MainActor-isolated ViewModel orchestrating UI state, security validation, and animations.
@MainActor
public final class DashboardViewModel: ObservableObject {

    private let repository: SavingsRepository

    @Published public var metrics: FinancialMetrics = FinancialMetrics()
    @Published public var goals: [SavingsGoal] = []
    @Published public var monthlyRecords: [MonthlyRecord] = []
    @Published public var transactions: [SavingsTransaction] = []

    // Modal & Sheet States
    @Published public var selectedTimeframe: String = "6M"
    @Published public var isAddModalPresented: Bool = false
    @Published public var selectedBucketForModal: String? = nil
    @Published public var isCreateBucketModalPresented: Bool = false
    @Published public var bucketToEdit: SavingsGoal? = nil
    @Published public var bucketToDelete: SavingsGoal? = nil
    @Published public var isDeleteConfirmationPresented: Bool = false
    @Published public var transactionToDelete: SavingsTransaction? = nil
    @Published public var isDeleteTxConfirmationPresented: Bool = false
    @Published public var monthRecordToDelete: MonthlyRecord? = nil
    @Published public var isDeleteMonthRecordConfirmationPresented: Bool = false

    // Animation & Feedback States
    @Published public var isHeroCardHighlighted: Bool = false
    @Published public var highlightedBucketId: String? = nil
    @Published public var showConfettiCelebration: Bool = false

    // Error Reporting
    @Published public var errorMessage: String? = nil

    public init(repository: SavingsRepository = .shared) {
        self.repository = repository
        Task {
            await self.loadData()
        }
    }

    public func loadData() async {
        self.metrics = await self.repository.getFinancialMetrics()
        self.goals = await self.repository.getGoals()
        self.monthlyRecords = await self.repository.getMonthlyRecords()
        self.transactions = await self.repository.getTransactions()
    }

    public var currentPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    /// Executes a verified deposit with strict validation and optional custom date.
    public func deposit(rawAmount: String, bucketId: String, rawNote: String, date: Date = Date()) {
        // 1. Strict Input Sanitization
        let amountResult = InputSanitizer.validateAmount(rawAmount)
        guard case .success(let amount) = amountResult else {
            if case .failure(let err) = amountResult {
                self.errorMessage = err.localizedDescription
                AppTheme.triggerNotificationHaptic(type: .error)
            }
            return
        }

        let noteResult = InputSanitizer.sanitizeText(rawNote)
        let note: String
        switch noteResult {
        case .success(let sanitized): note = sanitized
        case .failure(let err):
            self.errorMessage = err.localizedDescription
            AppTheme.triggerNotificationHaptic(type: .error)
            return
        }

        Task {
            let prevMonthSaved = self.metrics.currentMonthSaved
            let targetGoal = self.metrics.currentGoal

            // 2. Perform Repository Mutation (actor-safe)
            let tx = await self.repository.addDeposit(amount: amount, bucketId: bucketId, note: note, date: date)
            await self.loadData()

            // 3. Audio & Haptic Feedback
            AppTheme.playDepositSound()

            // 4. Trigger Rapid Reactive Flash & Counter Tweening
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHeroCardHighlighted = true
                self.highlightedBucketId = bucketId
            }

            // Reset highlight after 1 second
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isHeroCardHighlighted = false
                    self.highlightedBucketId = nil
                }
            }

            // 5. Celebration if Goal Target Passed
            if prevMonthSaved < targetGoal && self.metrics.currentMonthSaved >= targetGoal {
                self.showConfettiCelebration = true
                AppTheme.playCelebrationSound()
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.showConfettiCelebration = false
                }
            }

            SecureLogger.finance.info("Deposit executed successfully for bucket: \(tx.bucketName, privacy: .public)")
        }
    }

    /// Quick deposit convenience method.
    public func quickDeposit(amount: Decimal, bucketId: String = "emergency") {
        deposit(rawAmount: "\(amount)", bucketId: bucketId, rawNote: "Quick Deposit")
    }

    // MARK: - Bucket Management

    /// Creates a new dedicated savings bucket.
    @discardableResult
    public func createBucket(
        name: String,
        rawTarget: String,
        colorHex: String,
        iconName: String,
        category: String
    ) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            self.errorMessage = "Bucket name cannot be empty."
            AppTheme.triggerNotificationHaptic(type: .error)
            return false
        }

        let targetResult = InputSanitizer.validateAmount(rawTarget)
        guard case .success(let target) = targetResult else {
            if case .failure(let err) = targetResult {
                self.errorMessage = err.localizedDescription
                AppTheme.triggerNotificationHaptic(type: .error)
            }
            return false
        }

        Task {
            _ = await self.repository.createGoal(
                name: cleanName,
                target: target,
                colorHex: colorHex,
                iconName: iconName,
                category: category.isEmpty ? "Custom" : category
            )
            await self.loadData()
            AppTheme.playDepositSound()
        }
        return true
    }

    /// Updates an existing bucket.
    @discardableResult
    public func updateBucket(
        id: String,
        name: String,
        rawTarget: String,
        colorHex: String,
        iconName: String,
        category: String
    ) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            self.errorMessage = "Bucket name cannot be empty."
            AppTheme.triggerNotificationHaptic(type: .error)
            return false
        }

        let targetResult = InputSanitizer.validateAmount(rawTarget)
        guard case .success(let target) = targetResult else {
            if case .failure(let err) = targetResult {
                self.errorMessage = err.localizedDescription
                AppTheme.triggerNotificationHaptic(type: .error)
            }
            return false
        }

        Task {
            _ = await self.repository.updateGoal(
                id: id,
                name: cleanName,
                target: target,
                colorHex: colorHex,
                iconName: iconName,
                category: category.isEmpty ? "Custom" : category
            )
            await self.loadData()
            AppTheme.playTapSound()
        }
        return true
    }

    /// Deletes a bucket and safely reassigns associated transactions.
    public func deleteBucket(id: String) {
        Task {
            _ = await self.repository.deleteGoal(id: id)
            await self.loadData()
            AppTheme.playDeleteSound()
        }
    }

    // MARK: - Transaction Deletion & Management

    /// Prompts user to confirm deletion of a specific transaction entry.
    public func promptDeleteTransaction(_ tx: SavingsTransaction) {
        self.transactionToDelete = tx
        self.isDeleteTxConfirmationPresented = true
        AppTheme.triggerHaptic(style: .medium)
    }

    /// Confirms deletion of the staged transaction.
    public func confirmDeleteTransaction() {
        guard let tx = transactionToDelete else { return }
        deleteTransaction(id: tx.id)
        self.transactionToDelete = nil
        self.isDeleteTxConfirmationPresented = false
    }

    /// Deletes a transaction by ID, restores bucket balance, and refreshes all metrics.
    public func deleteTransaction(id: String) {
        Task {
            _ = await self.repository.deleteTransaction(id: id)
            await self.loadData()
            AppTheme.playDeleteSound()
            AppTheme.triggerNotificationHaptic(type: .success)
        }
    }

    /// Clears all transactions and resets bucket balances.
    public func clearAllEntries() {
        Task {
            await self.repository.clearAllTransactions()
            await self.loadData()
            AppTheme.playDeleteSound()
        }
    }

    // MARK: - Monthly Archive Deletion

    /// Prompts user to confirm deletion of a historical monthly record.
    public func promptDeleteMonthlyRecord(_ record: MonthlyRecord) {
        self.monthRecordToDelete = record
        self.isDeleteMonthRecordConfirmationPresented = true
        AppTheme.triggerHaptic(style: .medium)
    }

    /// Confirms deletion of the staged monthly record.
    public func confirmDeleteMonthlyRecord() {
        guard let record = monthRecordToDelete else { return }
        deleteMonthlyRecord(period: record.period)
        self.monthRecordToDelete = nil
        self.isDeleteMonthRecordConfirmationPresented = false
    }

    /// Deletes a monthly record by period, updating monthly average, projected annual, and spline trajectory.
    public func deleteMonthlyRecord(period: String) {
        Task {
            _ = await self.repository.deleteMonthlyRecord(period: period)
            await self.loadData()
            AppTheme.playDeleteSound()
            AppTheme.triggerNotificationHaptic(type: .success)
        }
    }

    public func updateCurrency(_ newCurrency: CurrencyType) {
        Task {
            await self.repository.updateCurrency(newCurrency)
            await self.loadData()
        }
    }

    public func resetData() {
        Task {
            await self.repository.resetToDefaults()
            await self.loadData()
        }
    }
}
