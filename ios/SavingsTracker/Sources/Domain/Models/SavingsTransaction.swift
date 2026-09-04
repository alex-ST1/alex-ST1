import Foundation

/// Represents a validated, persistent savings deposit transaction.
public struct SavingsTransaction: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let date: Date
    public let amount: Decimal
    public var bucketId: String
    public var bucketName: String
    public let note: String

    public init(
        id: String = "tx_\(UUID().uuidString.prefix(8))",
        date: Date = Date(),
        amount: Decimal,
        bucketId: String,
        bucketName: String,
        note: String
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.bucketId = bucketId
        self.bucketName = bucketName
        self.note = note
    }
}
