import Foundation

/// Supported currencies with localized formatting rules.
public enum CurrencyType: String, CaseIterable, Codable, Sendable {
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    public var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }

    public var displayName: String {
        switch self {
        case .inr: return "Indian Rupee (₹)"
        case .usd: return "US Dollar ($)"
        case .eur: return "Euro (€)"
        case .gbp: return "British Pound (£)"
        }
    }

    public var locale: Locale {
        switch self {
        case .inr: return Locale(identifier: "en_IN")
        case .usd: return Locale(identifier: "en_US")
        case .eur: return Locale(identifier: "de_DE")
        case .gbp: return Locale(identifier: "en_GB")
        }
    }

    /// Formats a Decimal value with the proper locale and currency grouping.
    public func format(amount: Decimal, includeDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.locale
        formatter.currencySymbol = self.symbol
        formatter.maximumFractionDigits = includeDecimals ? 2 : 0
        formatter.minimumFractionDigits = includeDecimals ? 2 : 0

        let nsNumber = NSDecimalNumber(decimal: amount)
        return formatter.string(from: nsNumber) ?? "\(self.symbol)\(amount)"
    }
}
