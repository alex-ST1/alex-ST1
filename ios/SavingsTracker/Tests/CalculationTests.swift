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

        // Audit integrity: transactions should now be reassigned to fallback
        let txsAfter = await repo.getTransactions()
        let targetTx = txsAfter.first(where: { $0.note == "Gift savings" })
        XCTAssertNotNil(targetTx)
        XCTAssertNotEqual(targetTx?.bucketId, created.id)
    }
}
