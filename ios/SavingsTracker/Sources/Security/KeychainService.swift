import Foundation
import Security

/// Thread-safe, production-ready Keychain wrapper adhering to Apple Security Guidelines.
/// Encapsulates operations against Apple's `Security` framework with strict access control.
public final class KeychainService: Sendable {

    public static let shared = KeychainService()

    public enum KeychainError: LocalizedError, Sendable {
        case itemNotFound
        case duplicateItem
        case unexpectedData
        case unhandledError(status: OSStatus)

        public var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "The requested secure credential was not found in the Keychain."
            case .duplicateItem:
                return "An item with this key already exists in the Keychain."
            case .unexpectedData:
                return "The data retrieved from the Keychain was corrupted or malformed."
            case .unhandledError(let status):
                return "Keychain operation failed with OSStatus: \(status)."
            }
        }
    }

    private let serviceIdentifier: String

    public init(serviceIdentifier: String = "com.savingstracker.app.keychain") {
        self.serviceIdentifier = serviceIdentifier
    }

    /// Stores a secret securely in the Keychain.
    /// Uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` to ensure the item cannot be transferred via iCloud/iTunes backups.
    public func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete any existing item before adding
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Reads a secret securely from the Keychain.
    public func read(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = item as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    /// Deletes an item from the Keychain.
    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
