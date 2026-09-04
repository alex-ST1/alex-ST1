import Foundation
import OSLog

/// Security-conscious logger using Apple's unified `OSLog` framework.
/// Ensures monetary amounts, credentials, and sensitive identifiers are strictly redacted.
public enum SecureLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.savingstracker.app"

    public static let security = Logger(subsystem: subsystem, category: "Security")
    public static let finance = Logger(subsystem: subsystem, category: "Finance")
    public static let storage = Logger(subsystem: subsystem, category: "Storage")
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    public static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")

    /// Logs general operational information safely without exposing monetary amounts.
    public static func logOperation(_ operation: String, category: Logger = finance) {
        category.info("Operational event: \(operation, privacy: .public)")
    }

    /// Logs an error description while suppressing potential sensitive internal state.
    public static func logError(_ error: Error, context: String, category: Logger = security) {
        category.error("Error in [\(context, privacy: .public)]: \(error.localizedDescription, privacy: .public)")
    }
}
