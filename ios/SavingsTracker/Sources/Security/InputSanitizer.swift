import Foundation

/// Validates and sanitizes user input to protect against injection, overflow, and invalid transactions.
public enum InputSanitizer {

    public enum ValidationError: LocalizedError, Equatable {
        case emptyInput
        case nonNumeric
        case negativeOrZeroAmount
        case exceedsMaximumAllowed(limit: Decimal)
        case excessiveDecimals(max: Int)
        case textTooLong(max: Int)
        case invalidCharacters

        public var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "The input field cannot be empty."
            case .nonNumeric:
                return "Please enter a valid numeric amount."
            case .negativeOrZeroAmount:
                return "Deposit amount must be strictly greater than zero."
            case .exceedsMaximumAllowed(let limit):
                return "Amount exceeds single transaction safety threshold (\(limit))."
            case .excessiveDecimals(let max):
                return "Currency amounts cannot have more than \(max) decimal places."
            case .textTooLong(let max):
                return "Text input exceeds maximum length of \(max) characters."
            case .invalidCharacters:
                return "Input contains disallowed or unsafe characters."
            }
        }
    }

    /// Hard limit for a single transaction (e.g. ₹10 Crore / $10,000,000) to prevent numeric overflow.
    public static let maxSingleDeposit: Decimal = 100_000_000

    /// Maximum length for transaction notes.
    public static let maxNoteLength: Int = 120

    /// Validates and parses a string into a sanitized `Decimal` amount.
    /// - Parameters:
    ///   - rawString: User-entered raw string from textfield.
    ///   - maxDecimals: Permitted decimal precision (default: 2 for standard fiat currency).
    /// - Returns: Validated `Decimal` or `ValidationError`.
    public static func validateAmount(_ rawString: String, maxDecimals: Int = 2) -> Result<Decimal, ValidationError> {
        let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.emptyInput)
        }

        // Standardize comma and dot separators
        let sanitized = trimmed.replacingOccurrences(of: ",", with: ".")

        // Verify numeric format using scanner
        guard let decimal = Decimal(string: sanitized, locale: Locale(identifier: "en_US")),
              !decimal.isNaN else {
            return .failure(.nonNumeric)
        }

        guard decimal > 0 else {
            return .failure(.negativeOrZeroAmount)
        }

        guard decimal <= maxSingleDeposit else {
            return .failure(.exceedsMaximumAllowed(limit: maxSingleDeposit))
        }

        // Validate decimal places
        if sanitized.contains(".") {
            let parts = sanitized.split(separator: ".")
            if parts.count == 2, parts[1].count > maxDecimals {
                return .failure(.excessiveDecimals(max: maxDecimals))
            }
        }

        return .success(decimal)
    }

    /// Sanitizes free-form text input (e.g. deposit notes or goal titles).
    /// Strips control characters, strips potential script/injection tags, and enforces max length.
    public static func sanitizeText(_ text: String, maxLength: Int = maxNoteLength) -> Result<String, ValidationError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count <= maxLength else {
            return .failure(.textTooLong(max: maxLength))
        }

        // Filter out ASCII control characters (0...31, 127) except standard newline/space
        let safeCharacters = trimmed.unicodeScalars.filter { scalar in
            let val = scalar.value
            return (val >= 32 && val != 127) || val == 10 || val == 13
        }

        var sanitized = String(String.UnicodeScalarView(safeCharacters))

        // Basic escape for HTML/Script injection tokens (<, >, &, ")
        let replacements: [String: String] = [
            "<": "&lt;",
            ">": "&gt;",
            "\"": "&quot;",
            "'": "&#x27;"
        ]

        for (target, replacement) in replacements {
            sanitized = sanitized.replacingOccurrences(of: target, with: replacement)
        }

        return .success(sanitized)
    }
}
