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
}
