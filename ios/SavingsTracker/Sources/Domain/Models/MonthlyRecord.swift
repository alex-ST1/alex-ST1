import Foundation

/// Represents the aggregate savings record for a specific calendar month (`YYYY-MM`).
public struct MonthlyRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: String { period } // e.g. "2026-09"
    public let period: String
    public var saved: Decimal
    public var goal: Decimal
    public var income: Decimal
    public var expenses: Decimal

    public init(
        period: String,
        saved: Decimal,
        goal: Decimal,
        income: Decimal = 0,
        expenses: Decimal = 0
    ) {
        self.period = period
        self.saved = saved
        self.goal = goal
        self.income = income
        self.expenses = expenses
    }

    /// Progress percentage towards the monthly goal.
    public var progressPercentage: Int {
        guard goal > 0 else { return 0 }
        let ratio = (saved as NSDecimalNumber).doubleValue / (goal as NSDecimalNumber).doubleValue
        return min(100, max(0, Int((ratio * 100).rounded())))
    }

    /// Short month label for chart x-axis (e.g. "Sep '26").
    public var shortLabel: String {
        let parts = period.split(separator: "-")
        guard parts.count == 2,
              let year = parts.first,
              let monthNum = Int(parts[1]) else {
            return period
        }
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        guard monthNum >= 1 && monthNum <= 12 else { return period }
        let shortYear = year.suffix(2)
        return "\(monthNames[monthNum - 1]) '\(shortYear)"
    }
}
