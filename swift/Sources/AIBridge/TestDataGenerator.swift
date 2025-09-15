import Foundation

/// Generates test data using AI assistance
public class TestDataGenerator {

    // MARK: - Properties

    private let orchestrator: Orchestrator

    // MARK: - Initialization

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    // MARK: - Test Data Generation

    /// Generates comprehensive test data for a feature using AI
    public func generateTestData(for feature: String) async throws -> TestDataDefinition {
        let prompt = buildTestDataPrompt(for: feature)
        let response = try await requestTestData(with: prompt)
        return try parseTestDataResponse(response)
    }

    /// Generates test scenarios for specific requirements
    public func generateScenarios(
        for requirements: [String],
        priority: String = TestDataConstants.Priority.medium
    ) async throws -> [TestScenario] {
        let prompt = buildScenariosPrompt(requirements: requirements, priority: priority)
        let response = try await requestTestData(with: prompt)
        let testData = try parseTestDataResponse(response)
        return testData.scenarios
    }

    /// Generates edge case test data
    public func generateEdgeCases(for feature: String) async throws -> [TestScenario] {
        let prompt = buildEdgeCasePrompt(for: feature)
        let response = try await requestTestData(with: prompt)
        let testData = try parseTestDataResponse(response)
        return testData.scenarios
    }

    // MARK: - Prompt Building

    private func buildTestDataPrompt(for feature: String) -> String {
        return String(format: TestDataConstants.Prompts.generateTestDataTemplate, feature)
    }

    private func buildScenariosPrompt(requirements: [String], priority: String) -> String {
        let requirementsList = requirements.enumerated()
            .map { index, req in String(format: TestDataConstants.PromptComponents.requirementPrefix, index + 1, req) }
            .joined(separator: TestDataConstants.SwiftCodeGeneration.newline)

        return String(
            format: TestDataConstants.Prompts.scenariosPromptTemplate,
            requirementsList,
            priority
        )
    }

    private func buildEdgeCasePrompt(for feature: String) -> String {
        return String(
            format: TestDataConstants.Prompts.edgeCasePromptTemplate,
            feature
        )
    }

    // MARK: - AI Communication

    private func requestTestData(with prompt: String) async throws -> String {
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            options: ChatOptions(injectContext: false)
        )

        guard !response.isEmpty else {
            throw TestDataError.invalidResponse
        }

        return response
    }

    // MARK: - Response Parsing

    private func parseTestDataResponse(_ response: String) throws -> TestDataDefinition {
        // Extract JSON from response (AI might include explanation text)
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw TestDataError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(TestDataDefinition.self, from: data)
        } catch {
            throw TestDataError.parsingFailed(error.localizedDescription)
        }
    }

    private func extractJSON(from response: String) -> String {
        // Look for JSON content between ```json and ``` markers
        if let range = response.range(of: TestDataConstants.JSONParsing.jsonMarkerStart) {
            let afterMarker = response[range.upperBound...]
            if let endRange = afterMarker.range(of: TestDataConstants.JSONParsing.jsonMarkerEnd) {
                return String(afterMarker[..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Try to find JSON object directly
        if let startIndex = response.firstIndex(where: { String($0) == TestDataConstants.JSONParsing.openBrace }),
           let endIndex = response.lastIndex(where: { String($0) == TestDataConstants.JSONParsing.closeBrace }) {
            return String(response[startIndex...endIndex])
        }

        // Return as-is and hope it's valid JSON
        return response
    }
}

// MARK: - Test Data Errors

public enum TestDataError: LocalizedError {
    case invalidResponse
    case parsingFailed(String)
    case noScenariosGenerated
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return TestDataConstants.Errors.invalidResponse
        case .parsingFailed(let reason):
            return String(format: TestDataConstants.Errors.parsingFailedWithReason, reason)
        case .noScenariosGenerated:
            return TestDataConstants.Errors.noScenariosGenerated
        case .invalidJSON:
            return TestDataConstants.Errors.invalidJSON
        }
    }
}