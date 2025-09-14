import Foundation

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
        case performance = "performance"
        case security = "security"
        case stress = "stress"
        case negative = "negative"
        case custom = "custom"
    }
}

/// Manager for test data operations using AI providers
public class TestDataManager {
    
    /// Load test data from configuration
    public static func loadTestData(from url: URL) throws -> TestDataDefinition {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(TestDataDefinition.self, from: data)
    }
    
    
    /// Generate test data using AI based on requirements
    public static func generateTestDataWithAI(
        requirements: String,
        domain: String,
        orchestrator: Orchestrator
    ) async throws -> TestDataDefinition {
        
        let prompt = """
        Generate comprehensive test data for the following requirements:
        
        Domain: \(domain)
        Requirements: \(requirements)
        
        Create test scenarios with:
        1. Happy path scenarios
        2. Edge cases
        3. Error scenarios
        4. Performance boundaries
        
        Output as JSON with this structure:
        {
          "scenarios": [
            {
              "id": "unique-id",
              "name": "scenario name",
              "description": "what this tests",
              "tags": ["tag1", "tag2"],
              "preconditions": ["condition1"],
              "steps": [
                {
                  "action": "what to do",
                  "data": {"key": "value"},
                  "validation": "what to check"
                }
              ],
              "expected_results": ["result1"],
              "priority": "high|medium|low|critical"
            }
          ],
          "data_sets": {
            "valid_data": {
              "name": "Valid Input Set",
              "type": "valid",
              "values": {"field": "value"}
            }
          }
        }
        """
        
        let (response, _) = try await orchestrator.sendMessage(
            prompt,
            systemPrompt: "You are a test data generation expert. Generate comprehensive, realistic test data.",
            needsJSON: true
        )
        
        // Parse the AI response into TestDataDefinition
        guard let data = response.data(using: .utf8) else {
            throw TestDataError.invalidResponse
        }
        
        return try JSONDecoder().decode(TestDataDefinition.self, from: data)
    }
    
    /// Generate Swift XCTest code from test scenarios
    public static func generateSwiftTests(from scenarios: [TestScenario]) -> String {
        var result = """
        import XCTest
        @testable import YourModule
        
        final class GeneratedTests: XCTestCase {
        
        """
        
        for scenario in scenarios {
            result += generateSwiftTest(from: scenario)
            result += "\n\n"
        }
        
        result += "}"
        return result
    }
    
    private static func generateSwiftTest(from scenario: TestScenario) -> String {
        let methodName = sanitizeForSwiftMethodName(scenario.id)
        
        return """
            /// \(scenario.name)
            /// \(scenario.description)
            /// Priority: \(scenario.priority ?? "medium")
            func test\(methodName)() async throws {
                // Arrange - Preconditions
        \(formatPreconditions(scenario.preconditions))
                
                // Act & Assert - Test Steps
        \(formatTestSteps(scenario.steps))
                
                // Verify Expected Results
        \(formatExpectedResults(scenario.expectedResults))
            }
        """
    }
    
    private static func sanitizeForSwiftMethodName(_ text: String) -> String {
        let components = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, component in
                index == 0 ? component.capitalized : component.capitalized
            }
            .joined()
    }
    
    private static func formatPreconditions(_ preconditions: [String]?) -> String {
        guard let preconditions = preconditions, !preconditions.isEmpty else {
            return "        // No preconditions"
        }
        
        return preconditions.map { "        // - \($0)" }.joined(separator: "\n")
    }
    
    private static func formatTestSteps(_ steps: [TestStep]) -> String {
        return steps.enumerated().map { index, step in
            var result = "        // Step \(index + 1): \(step.action)\n"
            
            if let data = step.data {
                result += "        let stepData\(index + 1) = \(formatTestData(data))\n"
            }
            
            result += "        // TODO: Implement action\n"
            
            if let validation = step.validation {
                result += "        \n"
                result += "        // Validation: \(validation)\n"
                result += "        XCTAssertTrue(false, \"Implement validation: \(validation)\")"
            }
            
            return result
        }.joined(separator: "\n\n")
    }
    
    private static func formatTestData(_ data: [String: AnyCodable]) -> String {
        let entries = data.map { key, value in
            "\"\(key)\": \(formatValue(value.value))"
        }.joined(separator: ", ")
        return "[\(entries)]"
    }
    
    private static func formatValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            return "\"\(string)\""
        case let number as NSNumber:
            return "\(number)"
        case let array as [Any]:
            let items = array.map { formatValue($0) }.joined(separator: ", ")
            return "[\(items)]"
        case let dict as [String: Any]:
            let items = dict.map { "\"\($0.key)\": \(formatValue($0.value))" }.joined(separator: ", ")
            return "[\(items)]"
        default:
            return "nil"
        }
    }
    
    private static func formatExpectedResults(_ results: [String]) -> String {
        if results.isEmpty {
            return "        // No specific expected results defined"
        }
        
        return results.map { result in
            "        // Expected: \(result)\n        XCTAssertTrue(false, \"Verify: \(result)\")"
        }.joined(separator: "\n")
    }
    
    /// Generate a test execution report
    public static func generateTestReport(_ scenarios: [TestScenario]) -> String {
        var report = """
        # Test Execution Report
        
        **Generated:** \(Date().formatted())
        **Total Scenarios:** \(scenarios.count)
        
        ## Coverage Summary
        
        """
        
        // Group by priority
        let byPriority = Dictionary(grouping: scenarios) { $0.priority ?? "medium" }
        
        report += "| Priority | Count | Percentage |\n"
        report += "|----------|-------|------------|\n"
        
        for priority in ["critical", "high", "medium", "low"] {
            let count = byPriority[priority]?.count ?? 0
            let percentage = scenarios.isEmpty ? 0 : (count * 100) / scenarios.count
            report += "| \(priority.capitalized) | \(count) | \(percentage)% |\n"
        }
        
        report += "\n## Test Scenarios\n\n"
        
        for (priority, scenarios) in byPriority.sorted(by: { priorityOrder($0.key) < priorityOrder($1.key) }) {
            report += "### \(priority.capitalized) Priority\n\n"
            
            for scenario in scenarios {
                report += "- **\(scenario.name)** (\(scenario.id))\n"
                report += "  - \(scenario.description)\n"
                report += "  - Steps: \(scenario.steps.count)\n"
                report += "  - Tags: \(scenario.tags?.joined(separator: ", ") ?? "none")\n\n"
            }
        }
        
        return report
    }
    
    private static func priorityOrder(_ priority: String) -> Int {
        switch priority {
        case "critical": return 0
        case "high": return 1
        case "medium": return 2
        case "low": return 3
        default: return 4
        }
    }
}

// Error types for test data operations
public enum TestDataError: Error {
    case invalidResponse
    case parsingFailed
    case fileNotFound
    case invalidDomain
}

// Helper for encoding/decoding Any types
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}