import Foundation
import CryptoKit

/// Encrypted local persistence service using Apple's `CryptoKit` and `Security` framework.
/// Financial data is encrypted using AES-GCM with a 256-bit symmetric key protected in the iOS Keychain.
public final class SecureStorageService: Sendable {

    public static let shared = SecureStorageService()

    private let keychain: KeychainService
    private let keyIdentifier = "com.savingstracker.app.master_encryption_key"

    public init(keychain: KeychainService = .shared) {
        self.keychain = keychain
    }

    /// Obtains or creates the master 256-bit encryption key from Keychain.
    private func getOrCreateMasterKey() throws -> SymmetricKey {
        do {
            let keyData = try keychain.read(key: keyIdentifier)
            return SymmetricKey(data: keyData)
        } catch KeychainService.KeychainError.itemNotFound {
            // Generate a secure, cryptographically random 256-bit symmetric key
            let newKey = SymmetricKey(size: .bits256)
            let rawData = newKey.withUnsafeBytes { Data($0) }
            try keychain.save(key: keyIdentifier, data: rawData)
            SecureLogger.security.info("Generated and stored new 256-bit master encryption key in Keychain.")
            return newKey
        }
    }

    /// Encrypts and persists a `Codable` object to disk with `completeFileProtection`.
    public func saveEncrypted<T: Encodable>(_ object: T, to filename: String) throws {
        let masterKey = try getOrCreateMasterKey()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let plainData = try encoder.encode(object)

        // Encrypt with AES-GCM authenticated encryption
        let sealedBox = try AES.GCM.seal(plainData, using: masterKey)
        guard let encryptedData = sealedBox.combined else {
            throw CocoaError(.fileWriteUnknown)
        }

        let fileURL = try getSecureFileURL(filename: filename)
        try encryptedData.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    /// Reads and decrypts a `Codable` object from disk.
    public func loadDecrypted<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let fileURL = try getSecureFileURL(filename: filename)
        let encryptedData = try Data(contentsOf: fileURL)

        let masterKey = try getOrCreateMasterKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: masterKey)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: decryptedData)
    }

    /// Resolves the secure Application Support directory for the app.
    private func getSecureFileURL(filename: String) throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupportURL.appendingPathComponent(filename)
    }
}
