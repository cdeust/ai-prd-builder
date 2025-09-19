import XCTest
@testable import PRDGenerator
@testable import CommonModels
@testable import DomainCore
@testable import AIProvidersCore

final class PRDGeneratorTests: XCTestCase {

    private var generator: PRDGeneratorClean!
    private var mockProvider: MockAIProvider!
    private var configuration: Configuration!

    override func setUp() {
        super.setUp()
        mockProvider = MockAIProvider()
        configuration = Configuration(maxPrivacyLevel: .onDevice)
        generator = PRDGeneratorClean(
            provider: mockProvider,
            configuration: configuration
        )
    }

    override func tearDown() {
        generator = nil
        mockProvider = nil
        configuration = nil
        super.tearDown()
    }

    func testGeneratePRDSuccess() async throws {
        // Given
        let input = "Todo list app with AI features"
        mockProvider.responseToReturn = """
        This is a comprehensive todo list application with AI-powered features.
        The app helps users manage tasks intelligently using machine learning.
        """

        // When
        let prd = try await generator.generatePRD(from: input)

        // Then
        XCTAssertTrue(prd.title.contains("Todo list app"))
        XCTAssertTrue(prd.title.contains("Product Requirements Document"))
        XCTAssertEqual(prd.sections.count, 5)

        let sectionTitles = prd.sections.map { $0.title }
        XCTAssertTrue(sectionTitles.contains("Product Overview"))
        XCTAssertTrue(sectionTitles.contains("Core Features"))
        XCTAssertTrue(sectionTitles.contains("Target Users & Personas"))
        XCTAssertTrue(sectionTitles.contains("Success Metrics"))
        XCTAssertTrue(sectionTitles.contains("Technical Requirements"))

        XCTAssertEqual(mockProvider.sendMessagesCalled, 5) // One for each phase
    }

    func testGeneratePRDWithProviderError() async {
        // Given
        let input = "Test product"
        mockProvider.errorToThrow = AIProviderError.rateLimitExceeded

        // When/Then
        do {
            _ = try await generator.generatePRD(from: input)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? AIProviderError, .rateLimitExceeded)
        }
    }

    func testPRDMetadata() async throws {
        // Given
        let input = "Mobile banking app"
        mockProvider.responseToReturn = "Generic response"

        // When
        let prd = try await generator.generatePRD(from: input)

        // Then
        XCTAssertNotNil(prd.metadata["generator"])
        XCTAssertEqual(prd.metadata["generator"] as? String, "PRDGeneratorClean")
        XCTAssertEqual(prd.metadata["version"] as? String, "2.0")
        XCTAssertEqual(prd.metadata["phases"] as? Int, 5)
        XCTAssertNotNil(prd.metadata["timestamp"])
    }

    func testFeatureExtraction() async throws {
        // Given
        let input = "E-commerce platform"
        mockProvider.responsesQueue = [
            "Product overview response",
            """
            - User Authentication
            - Product Catalog
            - Shopping Cart
            - Payment Processing
            - Order Tracking
            """,
            "User personas response",
            "Success metrics response",
            "Technical requirements response"
        ]

        // When
        let prd = try await generator.generatePRD(from: input)

        // Then
        let featuresSection = prd.sections.first { $0.title == "Core Features" }
        XCTAssertNotNil(featuresSection)
        XCTAssertEqual(featuresSection?.subsections.count, 5)

        let featureNames = featuresSection?.subsections.map { $0.title } ?? []
        XCTAssertTrue(featureNames.contains("User Authentication"))
        XCTAssertTrue(featureNames.contains("Product Catalog"))
        XCTAssertTrue(featureNames.contains("Shopping Cart"))
    }
}

// MARK: - Mock AIProvider

final class MockAIProvider: AIProvider {
    var name = "MockProvider"
    var sendMessagesCalled = 0
    var responseToReturn = "Mock response"
    var responsesQueue: [String] = []
    var errorToThrow: AIProviderError?

    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        sendMessagesCalled += 1

        if let error = errorToThrow {
            return .failure(error)
        }

        if !responsesQueue.isEmpty {
            let response = responsesQueue.removeFirst()
            return .success(response)
        }

        return .success(responseToReturn)
    }
}