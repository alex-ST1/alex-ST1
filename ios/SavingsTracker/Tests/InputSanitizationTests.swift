import XCTest
@testable import SavingsTrackerCore

final class InputSanitizationTests: XCTestCase {

    func testValidAmounts() {
        // Standard integers
        let result1 = InputSanitizer.validateAmount("5000")
        XCTAssertEqual(result1, .success(Decimal(5000)))

        // Decimal with 2 places
        let result2 = InputSanitizer.validateAmount("14500.50")
        XCTAssertEqual(result2, .success(Decimal(string: "14500.50")!))

        // Comma decimal separator normalization
        let result3 = InputSanitizer.validateAmount("25000,75")
        XCTAssertEqual(result3, .success(Decimal(string: "25000.75")!))

        // Single digit decimal
        let result4 = InputSanitizer.validateAmount("100.5")
        XCTAssertEqual(result4, .success(Decimal(string: "100.5")!))
    }

    func testRejectionOfZeroAndNegative() {
        let resultZero = InputSanitizer.validateAmount("0")
        XCTAssertEqual(resultZero, .failure(.negativeOrZeroAmount))

        let resultNegative = InputSanitizer.validateAmount("-500")
        XCTAssertEqual(resultNegative, .failure(.negativeOrZeroAmount))
    }

    func testRejectionOfEmptyAndWhitespace() {
        let resultEmpty = InputSanitizer.validateAmount("")
        XCTAssertEqual(resultEmpty, .failure(.emptyInput))

        let resultWhitespace = InputSanitizer.validateAmount("   ")
        XCTAssertEqual(resultWhitespace, .failure(.emptyInput))
    }

    func testRejectionOfNonNumeric() {
        let resultAlpha = InputSanitizer.validateAmount("abc")
        XCTAssertEqual(resultAlpha, .failure(.nonNumeric))

        let resultCurrencySign = InputSanitizer.validateAmount("₹5000")
        XCTAssertEqual(resultCurrencySign, .failure(.nonNumeric))
    }

    func testExcessiveDecimals() {
        let resultExcessive = InputSanitizer.validateAmount("100.555")
        XCTAssertEqual(resultExcessive, .failure(.excessiveDecimals(max: 2)))
    }

    func testExceedsMaximumAllowed() {
        let excessiveAmount = "100000001"
        let resultMax = InputSanitizer.validateAmount(excessiveAmount)
        XCTAssertEqual(resultMax, .failure(.exceedsMaximumAllowed(limit: InputSanitizer.maxSingleDeposit)))
    }

    func testTextSanitizationAndXSSPrevention() {
        let rawNote = "<script>alert('xss')</script> Salary & Bonus"
        let sanitizedResult = InputSanitizer.sanitizeText(rawNote)
        switch sanitizedResult {
        case .success(let cleanText):
            XCTAssertFalse(cleanText.contains("<script>"))
            XCTAssertTrue(cleanText.contains("&lt;script&gt;"))
            XCTAssertTrue(cleanText.contains("Salary &amp; Bonus") || cleanText.contains("Salary & Bonus") || cleanText.contains("&amp;"))
        case .failure(let error):
            XCTFail("Unexpected failure: \(error.localizedDescription)")
        }
    }

    func testTextLengthLimit() {
        let veryLongText = String(repeating: "A", count: 200)
        let result = InputSanitizer.sanitizeText(veryLongText, maxLength: 50)
        XCTAssertEqual(result, .failure(.textTooLong(max: 50)))
    }
}
