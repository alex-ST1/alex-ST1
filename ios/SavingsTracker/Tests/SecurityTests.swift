import XCTest
import CryptoKit
@testable import SavingsTrackerCore

final class SecurityTests: XCTestCase {

    func testCryptoKitAESGCMEncryptionAndDecryption() throws {
        // Generate a 256-bit key
        let symmetricKey = SymmetricKey(size: .bits256)
        let samplePlaintext = "Confidential INR Savings: ₹1,45,000".data(using: .utf8)!

        // Seal with AES-GCM
        let sealedBox = try AES.GCM.seal(samplePlaintext, using: symmetricKey)
        guard let combinedData = sealedBox.combined else {
            XCTFail("Failed to serialize sealed box")
            return
        }

        // Ciphertext should not contain plaintext
        XCTAssertFalse(combinedData.contains(samplePlaintext))

        // Decrypt
        let openedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(openedBox, using: symmetricKey)

        XCTAssertEqual(decryptedData, samplePlaintext)
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(decryptedString, "Confidential INR Savings: ₹1,45,000")
    }

    func testTamperedCiphertextThrowsAuthenticationError() throws {
        let symmetricKey = SymmetricKey(size: .bits256)
        let samplePlaintext = "Secret Data".data(using: .utf8)!

        let sealedBox = try AES.GCM.seal(samplePlaintext, using: symmetricKey)
        guard var combinedData = sealedBox.combined else {
            XCTFail("Failed to serialize sealed box")
            return
        }

        // Tamper with one byte in the ciphertext
        let tamperIndex = combinedData.count / 2
        combinedData[tamperIndex] ^= 0xFF

        // Attempting to decrypt tampered data must fail integrity verification
        XCTAssertThrowsError(try {
            let tamperedBox = try AES.GCM.SealedBox(combined: combinedData)
            _ = try AES.GCM.open(tamperedBox, using: symmetricKey)
        }())
    }

    func testSQLAndScriptInjectionSanitization() {
        let injectionStrings = [
            "<script>document.cookie='steal'</script>",
            "' OR '1'='1",
            "DROP TABLE transactions;--",
            "<img src=x onerror=alert(1)>"
        ]

        for payload in injectionStrings {
            let sanitized = InputSanitizer.sanitizeText(payload)
            switch sanitized {
            case .success(let text):
                XCTAssertFalse(text.contains("<script>"))
                XCTAssertFalse(text.contains("<img"))
                XCTAssertFalse(text.contains("'")) // Single quote is encoded to &#x27;
            case .failure(let error):
                XCTFail("Validation failed unexpectedly: \(error)")
            }
        }
    }
}
