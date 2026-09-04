import XCTest
@testable import SavingsTrackerCore

final class CalculationTests: XCTestCase {

    func testCurrencyFormattingINR() {
        let currency = CurrencyType.inr
        XCTAssertEqual(currency.symbol, "₹")

        // ₹1,45,000 formatted with en_IN rules
        let formatted = currency.format(amount: 145000)
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("1,45,000") || formatted.contains("145,000"))
    }

    func testSavingsGoalProgressCalculations() {
        let goal = SavingsGoal(
            name: "Emergency Fund",
            target: 200000,
            current: 150000,
            colorHex: "#10B981",
            iconName: "shield.fill",
            category: "Safety"
        )

        // Progress should be 75%
        XCTAssertEqual(goal.progressPercentage, 75)
        // Remaining should be 50,000
        XCTAssertEqual(goal.remainingAmount, 50000)
        XCTAssertFalse(goal.isGoalCompleted)
    }

    func testSavingsGoalCompleted() {
        let goal = SavingsGoal(
            name: "Tech Goal",
            target: 50000,
            current: 55000,
            colorHex: "#A855F7",
            iconName: "laptopcomputer",
            category: "Gadgets"
        )

        // Capped at 100%
        XCTAssertEqual(goal.progressPercentage, 100)
        XCTAssertEqual(goal.remainingAmount, 0)
        XCTAssertTrue(goal.isGoalCompleted)
    }

    func testSavingsGoalZeroTarget() {
        let goal = SavingsGoal(
            name: "Zero Target",
            target: 0,
            current: 1000,
            colorHex: "#A855F7",
            iconName: "circle",
            category: "Test"
        )

        XCTAssertEqual(goal.progressPercentage, 0)
        XCTAssertEqual(goal.remainingAmount, 0)
    }

    func testFinancialMetricsCalculation() {
        let metrics = FinancialMetrics(
            totalSavings: 314000,
            currentMonthSaved: 18500,
            currentGoal: 25000,
            progressPercent: 74,
            momRate: -42,
            avgMonthly: 24500,
            projectedAnnual: 293500,
            currency: .inr
        )

        XCTAssertEqual(metrics.totalSavings, 314000)
        XCTAssertEqual(metrics.progressPercent, 74)
        XCTAssertEqual(metrics.currency, .inr)
    }

    func testCustomBucketCreationAndUpdate() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()
        let created = await repo.createGoal(
            name: "New Car Fund",
            target: 500000,
            colorHex: "#F97316",
            iconName: "car.fill",
            category: "Vehicle"
        )

        XCTAssertEqual(created.name, "New Car Fund")
        XCTAssertEqual(created.target, 500000)
        XCTAssertEqual(created.colorHex, "#F97316")

        let allGoals = await repo.getGoals()
        XCTAssertTrue(allGoals.contains(where: { $0.id == created.id }))

        // Test update
        let updated = await repo.updateGoal(
            id: created.id,
            name: "EV Car Fund",
            target: 600000,
            colorHex: "#10B981",
            iconName: "car.side.fill",
            category: "Automobile"
        )
        XCTAssertTrue(updated)

        let goalsAfterUpdate = await repo.getGoals()
        let updatedGoal = goalsAfterUpdate.first(where: { $0.id == created.id })
        XCTAssertEqual(updatedGoal?.name, "EV Car Fund")
        XCTAssertEqual(updatedGoal?.target, 600000)
    }

    func testCustomBucketDeletionAndReassignment() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()
        let mainBucket = await repo.createGoal(
            name: "Main Savings",
            target: 100000,
            colorHex: "#10B981",
            iconName: "shield.fill",
            category: "Safety"
        )
        let created = await repo.createGoal(
            name: "Temporary Bucket",
            target: 10000,
            colorHex: "#A855F7",
            iconName: "gift.fill",
            category: "Gifts"
        )

        _ = await repo.addDeposit(amount: 3000, bucketId: created.id, note: "Gift savings")

        let txsBefore = await repo.getTransactions()
        XCTAssertTrue(txsBefore.contains(where: { $0.bucketId == created.id }))

        // Delete goal
        let deleted = await repo.deleteGoal(id: created.id)
        XCTAssertTrue(deleted)

        let goalsAfter = await repo.getGoals()
        XCTAssertFalse(goalsAfter.contains(where: { $0.id == created.id }))
        XCTAssertTrue(goalsAfter.contains(where: { $0.id == mainBucket.id }))

        // Audit integrity: transactions should now be reassigned to fallback
        let txsAfter = await repo.getTransactions()
        let targetTx = txsAfter.first(where: { $0.note == "Gift savings" })
        XCTAssertNotNil(targetTx)
        XCTAssertEqual(targetTx?.bucketId, mainBucket.id)
    }

    func testTransactionDeletionAndBalanceRecalculation() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()
        let bucket = await repo.createGoal(
            name: "Emergency Fund",
            target: 200000,
            colorHex: "#10B981",
            iconName: "shield.fill",
            category: "Safety"
        )
        let metricsBefore = await repo.getFinancialMetrics()
        let goalsBefore = await repo.getGoals()
        let emergencyBefore = goalsBefore.first(where: { $0.id == bucket.id })?.current ?? 0

        // Add a deposit
        let depositTx = await repo.addDeposit(amount: 5000, bucketId: bucket.id, note: "Test deposit for removal")
        let metricsMid = await repo.getFinancialMetrics()
        let goalsMid = await repo.getGoals()
        let emergencyMid = goalsMid.first(where: { $0.id == bucket.id })?.current ?? 0

        XCTAssertEqual(emergencyMid, emergencyBefore + 5000)
        XCTAssertEqual(metricsMid.totalSavings, metricsBefore.totalSavings + 5000)
        XCTAssertEqual(metricsMid.currentMonthSaved, metricsBefore.currentMonthSaved + 5000)

        // Delete the deposit transaction
        let deleted = await repo.deleteTransaction(id: depositTx.id)
        XCTAssertTrue(deleted)

        let metricsAfter = await repo.getFinancialMetrics()
        let goalsAfter = await repo.getGoals()
        let emergencyAfter = goalsAfter.first(where: { $0.id == bucket.id })?.current ?? 0
        let txsAfter = await repo.getTransactions()

        // Balances must exactly return to baseline
        XCTAssertEqual(emergencyAfter, emergencyBefore)
        XCTAssertEqual(metricsAfter.totalSavings, metricsBefore.totalSavings)
        XCTAssertEqual(metricsAfter.currentMonthSaved, metricsBefore.currentMonthSaved)
        XCTAssertFalse(txsAfter.contains(where: { $0.id == depositTx.id }))
    }

    func testAllBucketsRemovedGoalBarZero() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()
        let goal1 = await repo.createGoal(name: "Goal 1", target: 50000, colorHex: "#10B981", iconName: "star", category: "General")
        let goal2 = await repo.createGoal(name: "Goal 2", target: 50000, colorHex: "#3B82F6", iconName: "star", category: "General")
        _ = await repo.addDeposit(amount: 10000, bucketId: goal1.id, note: "Deposit")

        let initialGoals = await repo.getGoals()
        XCTAssertEqual(initialGoals.count, 2)

        // Delete every bucket
        for goal in initialGoals {
            _ = await repo.deleteGoal(id: goal.id)
        }

        let remainingGoals = await repo.getGoals()
        XCTAssertTrue(remainingGoals.isEmpty)

        let metrics = await repo.getFinancialMetrics()
        XCTAssertEqual(metrics.totalSavings, 0)
        XCTAssertEqual(metrics.currentGoal, 0)
        XCTAssertEqual(metrics.currentMonthSaved, 0)
        XCTAssertEqual(metrics.progressPercent, 0)
        XCTAssertEqual(metrics.activeBucketsCount, 0)
        XCTAssertEqual(metrics.totalBucketTargets, 0)

        let txs = await repo.getTransactions()
        XCTAssertTrue(txs.isEmpty)
    }

    func testClearAllTransactions() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()
        let goal = await repo.createGoal(name: "Savings", target: 50000, colorHex: "#10B981", iconName: "star", category: "General")
        _ = await repo.addDeposit(amount: 15000, bucketId: goal.id, note: "Deposit")

        await repo.clearAllTransactions()

        let txs = await repo.getTransactions()
        XCTAssertTrue(txs.isEmpty)

        let goals = await repo.getGoals()
        for g in goals {
            XCTAssertEqual(g.current, 0)
        }

        let metrics = await repo.getFinancialMetrics()
        XCTAssertEqual(metrics.totalSavings, 0)
        XCTAssertEqual(metrics.currentMonthSaved, 0)
    }

    func testMonthlyRecordDeletionAndAverageRecalculation() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()

        // Initially no monthly records
        let initialMetrics = await repo.getFinancialMetrics()
        XCTAssertEqual(initialMetrics.avgMonthly, 0)
        XCTAssertEqual(initialMetrics.projectedAnnual, 0)

        // Add a deposit to simulate month activity
        let bucket = await repo.createGoal(name: "Investments", target: 100000, colorHex: "#10B981", iconName: "chart.line.uptrend.xyaxis", category: "Wealth")
        _ = await repo.addDeposit(amount: 20000, bucketId: bucket.id, note: "Deposit 1")

        let recordsBefore = await repo.getMonthlyRecords()
        XCTAssertEqual(recordsBefore.count, 1)

        let metrics1 = await repo.getFinancialMetrics()
        XCTAssertEqual(metrics1.avgMonthly, 20000)
        // 20000 + (20000 * 11) = 240000
        XCTAssertEqual(metrics1.projectedAnnual, 240000)

        // Delete the monthly record
        let deleted = await repo.deleteMonthlyRecord(period: "2026-09")
        XCTAssertTrue(deleted)

        let recordsAfter = await repo.getMonthlyRecords()
        XCTAssertTrue(recordsAfter.isEmpty)

        let metricsAfter = await repo.getFinancialMetrics()
        XCTAssertEqual(metricsAfter.avgMonthly, 0)
        XCTAssertEqual(metricsAfter.projectedAnnual, 0)
    }

    func testBucketCreationUpdatesGoalAndProgress() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()

        // 1. Initial empty state: no buckets, 0 target, 0% progress
        let initialMetrics = await repo.getFinancialMetrics()
        XCTAssertEqual(initialMetrics.currentGoal, 0)
        XCTAssertEqual(initialMetrics.totalBucketTargets, 0)
        XCTAssertEqual(initialMetrics.progressPercent, 0)

        // 2. Create a bucket with target 50,000
        let bucket = await repo.createGoal(
            name: "Emergency Fund",
            target: 50000,
            colorHex: "#10B981",
            iconName: "shield.fill",
            category: "Safety"
        )

        let metricsAfterBucket = await repo.getFinancialMetrics()
        // Goal must immediately equal bucket target (NOT 0)
        XCTAssertEqual(metricsAfterBucket.currentGoal, 50000)
        XCTAssertEqual(metricsAfterBucket.totalBucketTargets, 50000)
        XCTAssertEqual(metricsAfterBucket.progressPercent, 0)

        // 3. Deposit 10,000 into the bucket -> progress must be 20%
        _ = await repo.addDeposit(amount: 10000, bucketId: bucket.id, note: "Initial seed")
        let metricsAfterDeposit = await repo.getFinancialMetrics()
        XCTAssertEqual(metricsAfterDeposit.currentGoal, 50000)
        XCTAssertEqual(metricsAfterDeposit.totalSavings, 10000)
        XCTAssertEqual(metricsAfterDeposit.progressPercent, 20)

        // 4. Create second bucket with target 50,000 -> total target = 100,000, progress = 10%
        _ = await repo.createGoal(
            name: "Travel Fund",
            target: 50000,
            colorHex: "#06B6D4",
            iconName: "airplane",
            category: "Leisure"
        )
        let metricsWithTwoBuckets = await repo.getFinancialMetrics()
        XCTAssertEqual(metricsWithTwoBuckets.currentGoal, 100000)
        XCTAssertEqual(metricsWithTwoBuckets.totalBucketTargets, 100000)
        XCTAssertEqual(metricsWithTwoBuckets.progressPercent, 10)
    }

    func testDepositWithCustomDateRouting() async {
        let repo = SavingsRepository()
        await repo.resetToDefaults()

        let bucket = await repo.createGoal(
            name: "Retirement",
            target: 100000,
            colorHex: "#10B981",
            iconName: "lock.shield.fill",
            category: "LongTerm"
        )

        // Create a date in 2026-05
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 15
        components.hour = 12
        let calendar = Calendar(identifier: .gregorian)
        let pastDate = calendar.date(from: components)!

        let tx = await repo.addDeposit(amount: 25000, bucketId: bucket.id, note: "May Deposit", date: pastDate)
        XCTAssertEqual(tx.date, pastDate)

        // Monthly record for 2026-05 must exist
        let records = await repo.getMonthlyRecords()
        let mayRecord = records.first(where: { $0.period == "2026-05" })
        XCTAssertNotNil(mayRecord)
        XCTAssertEqual(mayRecord?.saved, 25000)
        XCTAssertEqual(mayRecord?.goal, 100000)

        let metrics = await repo.getFinancialMetrics()
        XCTAssertEqual(metrics.totalSavings, 25000)
        XCTAssertEqual(metrics.currentGoal, 100000)
        XCTAssertEqual(metrics.progressPercent, 25)
    }
}
