import XCTest
@testable import DomainCore
@testable import CommonModels

final class ConfigurationTests: XCTestCase {

    func testConfigurationDefaultValues() {
        let config = Configuration()

        XCTAssertNil(config.anthropicAPIKey)
        XCTAssertNil(config.openAIAPIKey)
        XCTAssertNil(config.geminiAPIKey)
        XCTAssertEqual(config.maxPrivacyLevel, .onDevice)
        XCTAssertNil(config.preferredProvider)
        XCTAssertEqual(config.modelPreferences.temperature, 0.7)
        XCTAssertEqual(config.modelPreferences.maxTokens, 4096)
        XCTAssertEqual(config.modelPreferences.topP, 0.95)
    }

    func testConfigurationCustomValues() {
        let modelPrefs = ModelPreferences(
            temperature: 0.9,
            maxTokens: 8192,
            topP: 0.8
        )

        let config = Configuration(
            anthropicAPIKey: "test-key-1",
            openAIAPIKey: "test-key-2",
            geminiAPIKey: "test-key-3",
            maxPrivacyLevel: .external,
            preferredProvider: "OpenAI",
            modelPreferences: modelPrefs
        )

        XCTAssertEqual(config.anthropicAPIKey, "test-key-1")
        XCTAssertEqual(config.openAIAPIKey, "test-key-2")
        XCTAssertEqual(config.geminiAPIKey, "test-key-3")
        XCTAssertEqual(config.maxPrivacyLevel, .external)
        XCTAssertEqual(config.preferredProvider, "OpenAI")
        XCTAssertEqual(config.modelPreferences.temperature, 0.9)
        XCTAssertEqual(config.modelPreferences.maxTokens, 8192)
        XCTAssertEqual(config.modelPreferences.topP, 0.8)
    }

    func testConfigurationCodable() throws {
        let original = Configuration(
            anthropicAPIKey: "key1",
            maxPrivacyLevel: .privateCloud
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Configuration.self, from: data)

        XCTAssertEqual(decoded.anthropicAPIKey, original.anthropicAPIKey)
        XCTAssertEqual(decoded.maxPrivacyLevel, original.maxPrivacyLevel)
    }
}