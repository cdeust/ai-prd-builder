import XCTest
@testable import CommonModels

final class ErrorsTests: XCTestCase {

    func testAIProviderErrorDescriptions() {
        let testCases: [(AIProviderError, String)] = [
            (.invalidAPIKey, "Invalid or missing API key"),
            (.networkError("Connection failed"), "Network error: Connection failed"),
            (.rateLimitExceeded, "Rate limit exceeded"),
            (.invalidResponse, "Invalid response from provider"),
            (.serverError(500, "Internal error"), "Server error 500: Internal error"),
            (.timeout, "Request timed out"),
            (.cancelled, "Request was cancelled")
        ]

        for (error, expected) in testCases {
            XCTAssertEqual(error.errorDescription, expected, "Error description mismatch for \(error)")
        }
    }

    func testAIProviderErrorEquality() {
        XCTAssertEqual(AIProviderError.invalidAPIKey, AIProviderError.invalidAPIKey)
        XCTAssertEqual(AIProviderError.networkError("test"), AIProviderError.networkError("test"))
        XCTAssertNotEqual(AIProviderError.networkError("test1"), AIProviderError.networkError("test2"))
        XCTAssertNotEqual(AIProviderError.timeout, AIProviderError.cancelled)
    }

    func testValidationErrorDescriptions() {
        let testCases: [(ValidationError, String)] = [
            (.missingRequired(field: "email"), "Missing required field: email"),
            (.invalidFormat(field: "phone", expected: "XXX-XXX-XXXX"), "Invalid format for phone, expected: XXX-XXX-XXXX"),
            (.custom("Custom validation failed"), "Custom validation failed")
        ]

        for (error, expected) in testCases {
            XCTAssertEqual(error.errorDescription, expected, "Validation error description mismatch")
        }
    }

    func testValidationErrorOutOfRange() {
        let error1 = ValidationError.outOfRange(field: "age", min: 18, max: 65)
        XCTAssertEqual(error1.errorDescription, "Value for age out of range (18 - 65)")

        let error2 = ValidationError.outOfRange(field: "score", min: nil, max: nil)
        XCTAssertEqual(error2.errorDescription, "Value for score out of range")
    }
}