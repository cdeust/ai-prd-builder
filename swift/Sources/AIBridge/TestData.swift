import Foundation

// MARK: - Test Data Models

/// Generic test data definition that can work with any domain
public struct TestDataDefinition: Codable {
    public let scenarios: [TestScenario]
    public let dataSets: [String: DataSet]?
    public let fixtures: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case scenarios
        case dataSets = "data_sets"
        case fixtures
    }
}

/// Represents a single test scenario
public struct TestScenario: Codable {
    public let id: String
    public let name: String
    public let description: String
    public let tags: [String]?
    public let preconditions: [String]?
    public let steps: [TestStep]
    public let expectedResults: [String]
    public let priority: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, tags, preconditions, steps
        case expectedResults = "expected_results"
        case priority
    }
}

/// Represents a single test step
public struct TestStep: Codable {
    public let action: String
    public let data: [String: AnyCodable]?
    public let validation: String?
}

/// Generic data set that can represent any type of test data
public struct DataSet: Codable {
    public let name: String
    public let description: String?
    public let type: DataSetType
    public let values: [String: AnyCodable]

    public enum DataSetType: String, Codable {
        case valid = "valid"
        case invalid = "invalid"
        case boundary = "boundary"
        case edge = "edge"
        case stress = "stress"
        case security = "security"
    }
}

// MARK: - Test Data Factory

/// Main interface for test data operations
public struct TestData {

    private let generator: TestDataGenerator
    private let codeGenerator = SwiftTestCodeGenerator.self

    public init(orchestrator: Orchestrator) {
        self.generator = TestDataGenerator(orchestrator: orchestrator)
    }

    // MARK: - Test Data Generation

    /// Generates comprehensive test data for a feature
    public func generateFor(
        _ feature: String
    ) async throws -> TestDataDefinition {
        return try await generator.generateTestData(for: feature)
    }

    /// Generates test scenarios from requirements
    public func generateScenarios(
        from requirements: [String],
        priority: String = TestDataConstants.Priority.medium
    ) async throws -> [TestScenario] {
        return try await generator.generateScenarios(
            for: requirements,
            priority: priority
        )
    }

    /// Generates edge case scenarios
    public func generateEdgeCases(
        for feature: String
    ) async throws -> [TestScenario] {
        return try await generator.generateEdgeCases(for: feature)
    }

    // MARK: - Swift Code Generation

    /// Generates Swift test file from scenarios
    public func generateSwiftTests(
        from scenarios: [TestScenario],
        moduleName: String = "YourModule"
    ) -> String {
        return codeGenerator.generateTestFile(
            from: scenarios,
            moduleName: moduleName
        )
    }

    /// Generates a single Swift test method
    public func generateSwiftTest(
        from scenario: TestScenario
    ) -> String {
        return codeGenerator.generateTestMethod(from: scenario)
    }

    // MARK: - Validation

    /// Validates test data structure
    public static func validate(
        _ testData: TestDataDefinition
    ) -> ValidationResult {
        var issues: [String] = []

        // Check for empty scenarios
        if testData.scenarios.isEmpty {
            issues.append("No test scenarios defined")
        }

        // Validate each scenario
        for scenario in testData.scenarios {
            issues.append(contentsOf: validateScenario(scenario))
        }

        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    private static func validateScenario(
        _ scenario: TestScenario
    ) -> [String] {
        var issues: [String] = []

        if scenario.id.isEmpty {
            issues.append("Scenario missing ID")
        }

        if scenario.steps.isEmpty {
            issues.append("Scenario '\(scenario.id)' has no test steps")
        }

        if scenario.expectedResults.isEmpty {
            issues.append("Scenario '\(scenario.id)' has no expected results")
        }

        return issues
    }
}

// MARK: - Validation Result

public struct ValidationResult {
    public let isValid: Bool
    public let issues: [String]

    public var summary: String {
        if isValid {
            return "✅ Test data is valid"
        } else {
            return "❌ Test data has \(issues.count) issue(s):\n" +
                   issues.map { "  - \($0)" }.joined(separator: "\n")
        }
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for handling dynamic JSON
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}