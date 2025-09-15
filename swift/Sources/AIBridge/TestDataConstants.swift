import Foundation

/// Constants for test data generation
public enum TestDataConstants {

    // MARK: - Test Generation Prompts

    public enum Prompts {
        public static let testDataExpert = "You are a test data generation expert. Generate comprehensive, realistic test data."

        public static let scenariosPromptTemplate = """
        Generate test scenarios for these requirements:
        %@

        Priority level: %@

        Include positive and negative test cases.
        Format as JSON matching the TestDataDefinition structure.
        """

        public static let edgeCasePromptTemplate = """
        Generate edge case and boundary condition tests for: %@

        Focus on:
        - Minimum and maximum values
        - Empty/null inputs
        - Special characters
        - Concurrent access scenarios
        - Resource exhaustion
        - Timeout conditions

        Format as JSON matching the TestDataDefinition structure.
        """

        public static let generateTestDataTemplate = """
        Generate comprehensive test data for: %@

        Include:
        1. Edge cases and boundary conditions
        2. Valid and invalid inputs
        3. Common user scenarios
        4. Error conditions
        5. Performance test cases

        Return as JSON in this format:
        {
          "scenarios": [
            {
              "id": "unique_id",
              "name": "Test Name",
              "description": "What this tests",
              "tags": ["category"],
              "preconditions": ["setup needed"],
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
    }

    // MARK: - Swift Test Generation

    // MARK: - JSON Parsing

    public enum JSONParsing {
        public static let jsonMarkerStart = "```json"
        public static let jsonMarkerEnd = "```"
        public static let openBrace = "{"
        public static let closeBrace = "}"
    }

    // MARK: - Prompt Components

    public enum PromptComponents {
        public static let requirementPrefix = "%d. %@"
        public static let minimumMaximumValues = "- Minimum and maximum values"
        public static let emptyNullInputs = "- Empty/null inputs"
        public static let specialCharacters = "- Special characters"
        public static let concurrentAccess = "- Concurrent access scenarios"
        public static let resourceExhaustion = "- Resource exhaustion"
        public static let timeoutConditions = "- Timeout conditions"
    }

    // MARK: - Swift Test Generation

    public enum SwiftTestGeneration {
        public static let defaultModuleName = "YourModule"
        public static let defaultClassName = "GeneratedTests"
        public static let importHeader = """
        import XCTest
        @testable import YourModule

        """

        public static let classHeaderFormat = "final class %@: XCTestCase {\n\n"
        public static let importHeaderFormat = "import XCTest\n@testable import %@\n\n"
        public static let classFooter = "}"

        public static let methodPrefix = "test"
        public static let asyncThrows = "async throws"

        public static let arrangeComment = "        // Arrange - Preconditions"
        public static let actComment = "        // Act & Assert - Test Steps"
        public static let verifyComment = "        // Verify Expected Results"
        public static let noPreconditions = "        // No preconditions"

        public static let stepCommentFormat = "        // Step %d: %@"
        public static let stepDataFormat = "        let stepData%d = %@"
        public static let assertFormat = "        XCTAssert%@"
        public static let resultFormat = "        // Expected: %@"
    }

    // MARK: - Validation Messages

    public enum Validation {
        public static let validatingFormat = "        // Validating: %@"
        public static let todoValidation = "        // TODO: Add validation for: %@"
    }

    // MARK: - Priority Levels

    public enum Priority {
        public static let critical = "critical"
        public static let high = "high"
        public static let medium = "medium"
        public static let low = "low"
        public static let defaultPriority = "medium"
    }

    // MARK: - Data Set Types

    public enum DataSetTypes {
        public static let valid = "valid"
        public static let invalid = "invalid"
        public static let boundary = "boundary"
        public static let edge = "edge"
        public static let stress = "stress"
        public static let security = "security"
    }

    // MARK: - Test Categories

    public enum TestCategories {
        public static let unit = "unit"
        public static let integration = "integration"
        public static let acceptance = "acceptance"
        public static let performance = "performance"
        public static let security = "security"
        public static let regression = "regression"
    }

    // MARK: - Assertions

    public enum Assertions {
        public static let assertEqual = "Equal"
        public static let assertNotEqual = "NotEqual"
        public static let assertTrue = "True"
        public static let assertFalse = "False"
        public static let assertNil = "Nil"
        public static let assertNotNil = "NotNil"
        public static let assertThrows = "ThrowsError"
        public static let assertNoThrow = "NoThrow"
    }

    // MARK: - Swift Code Generation

    public enum SwiftCodeGeneration {
        public static let dictionaryEntryFormat = "\"%@\": %@"
        public static let dictionaryFormat = "[%@]"
        public static let stringValueFormat = "\"%@\""
        public static let assertionCallFormat = "%@(actual, expected)"
        public static let assertionConditionFormat = "%@(condition)"
        public static let assertionValueFormat = "%@(value)"
        public static let assertionThrowsFormat = "%@ { try operation() }"
        public static let commentPrefix = "// "
        public static let generatedTestCasesComment = "// Generated Test Cases\n\n"
        public static let separator = ", "
        public static let newlineDouble = "\n\n"
        public static let newline = "\n"
    }

    // MARK: - Assertion Keywords

    public enum AssertionKeywords {
        public static let equal = "equal"
        public static let trueKeyword = "true"
        public static let falseKeyword = "false"
        public static let nilKeyword = "nil"
        public static let notKeyword = "not"
        public static let noKeyword = "no"
        public static let throwsKeyword = "throws"
        public static let errorKeyword = "error"
    }

    // MARK: - Format Strings

    public enum Format {
        public static let testMethodDocFormat = """
            /// %@
            /// %@
            /// Priority: %@
        """

        public static let testMethodSignatureFormat = "    func %@() %@ {"
        public static let testMethodEnd = "    }"

        public static let preconditionFormat = "        // - %@"
        public static let dataDeclarationFormat = "        let %@ = %@"
        public static let expectationFormat = "        wait(for: [%@], timeout: %.1f)"
    }

    // MARK: - Error Messages

    public enum Errors {
        public static let invalidResponse = "Invalid AI response format"
        public static let parsingFailed = "Failed to parse test data"
        public static let parsingFailedWithReason = "Failed to parse test data: %@"
        public static let noScenariosGenerated = "No test scenarios were generated"
        public static let invalidJSON = "Response is not valid JSON"
    }
}