import Foundation

/// High-level computed metrics for the main Dashboard view.
public struct FinancialMetrics: Equatable, Sendable {
    public let totalSavings: Decimal
    public let currentMonthSaved: Decimal
    public let currentGoal: Decimal
    public let progressPercent: Int
    public let momRate: Int
    public let avgMonthly: Decimal
    public let projectedAnnual: Decimal
    public let currency: CurrencyType
    public let totalBucketTargets: Decimal
    public let activeBucketsCount: Int

    public init(
        totalSavings: Decimal = 0,
        currentMonthSaved: Decimal = 0,
        currentGoal: Decimal = 0,
        progressPercent: Int = 0,
        momRate: Int = 0,
        avgMonthly: Decimal = 0,
        projectedAnnual: Decimal = 0,
        currency: CurrencyType = .inr,
        totalBucketTargets: Decimal = 0,
        activeBucketsCount: Int = 0
    ) {
        self.totalSavings = totalSavings
        self.currentMonthSaved = currentMonthSaved
        self.currentGoal = currentGoal
        self.progressPercent = progressPercent
        self.momRate = momRate
        self.avgMonthly = avgMonthly
        self.projectedAnnual = projectedAnnual
        self.currency = currency
        self.totalBucketTargets = totalBucketTargets
        self.activeBucketsCount = activeBucketsCount
    }
}
