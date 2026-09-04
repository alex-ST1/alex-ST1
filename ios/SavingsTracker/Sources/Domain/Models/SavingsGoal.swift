import Foundation

/// Represents a dedicated savings goal or bucket (e.g. Emergency Fund, Investments, Travel).
public struct SavingsGoal: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var target: Decimal
    public var current: Decimal
    public var colorHex: String
    public var iconName: String
    public var category: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        target: Decimal,
        current: Decimal = 0,
        colorHex: String,
        iconName: String,
        category: String
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.current = current
        self.colorHex = colorHex
        self.iconName = iconName
        self.category = category
    }

    /// Progress percentage from 0 to 100.
    public var progressPercentage: Int {
        guard target > 0 else { return 0 }
        let ratio = (current as NSDecimalNumber).doubleValue / (target as NSDecimalNumber).doubleValue
        return min(100, max(0, Int((ratio * 100).rounded())))
    }

    /// Remaining amount needed to reach target.
    public var remainingAmount: Decimal {
        return max(0, target - current)
    }

    /// True if goal has met or exceeded target.
    public var isGoalCompleted: Bool {
        return current >= target
    }
}
