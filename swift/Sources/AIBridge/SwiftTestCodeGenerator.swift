import Foundation

/// Generates Swift XCTest code from test scenarios
public class SwiftTestCodeGenerator {

    // MARK: - Public Interface

    /// Generates complete Swift test file from scenarios
    public static func generateTestFile(
        from scenarios: [TestScenario],
        moduleName: String = TestDataConstants.SwiftTestGeneration.defaultModuleName,
        className: String = TestDataConstants.SwiftTestGeneration.defaultClassName
    ) -> String {
        var result = generateFileHeader(moduleName: moduleName)
        result += generateClassHeader(className: className)
        result += generateTestMethods(from: scenarios)
        result += TestDataConstants.SwiftTestGeneration.classFooter

        return result
    }

    /// Generates a single test method from a scenario
    public static func generateTestMethod(from scenario: TestScenario) -> String {
        let methodName = generateMethodName(from: scenario)
        let documentation = generateMethodDocumentation(scenario)
        let signature = generateMethodSignature(methodName)
        let body = generateMethodBody(scenario)

        return """
        \(documentation)
        \(signature)
        \(body)
        \(TestDataConstants.Format.testMethodEnd)
        """
    }

    // MARK: - File Structure Generation

    private static func generateFileHeader(moduleName: String) -> String {
        return String(
            format: TestDataConstants.SwiftTestGeneration.importHeaderFormat,
            moduleName
        )
    }

    private static func generateClassHeader(className: String) -> String {
        return String(
            format: TestDataConstants.SwiftTestGeneration.classHeaderFormat,
            className
        )
    }

    private static func generateTestMethods(from scenarios: [TestScenario]) -> String {
        return scenarios
            .map { generateTestMethod(from: $0) }
            .joined(separator: TestDataConstants.SwiftCodeGeneration.newlineDouble)
    }

    // MARK: - Method Generation

    private static func generateMethodName(from scenario: TestScenario) -> String {
        let sanitized = sanitizeForSwiftMethodName(scenario.id)
        return "\(TestDataConstants.SwiftTestGeneration.methodPrefix)\(sanitized)"
    }

    private static func generateMethodDocumentation(_ scenario: TestScenario) -> String {
        let priority = scenario.priority ?? TestDataConstants.Priority.defaultPriority
        return String(
            format: TestDataConstants.Format.testMethodDocFormat,
            scenario.name,
            scenario.description,
            priority
        )
    }

    private static func generateMethodSignature(_ methodName: String) -> String {
        return String(
            format: TestDataConstants.Format.testMethodSignatureFormat,
            methodName,
            TestDataConstants.SwiftTestGeneration.asyncThrows
        )
    }

    private static func generateMethodBody(_ scenario: TestScenario) -> String {
        var body = ""

        // Add preconditions
        body += "\(TestDataConstants.SwiftTestGeneration.arrangeComment)\n"
        body += formatPreconditions(scenario.preconditions)
        body += "\n\n"

        // Add test steps
        body += "\(TestDataConstants.SwiftTestGeneration.actComment)\n"
        body += formatTestSteps(scenario.steps)
        body += "\n\n"

        // Add expected results
        body += "\(TestDataConstants.SwiftTestGeneration.verifyComment)\n"
        body += formatExpectedResults(scenario.expectedResults)

        return body
    }

    // MARK: - Formatting Helpers

    private static func sanitizeForSwiftMethodName(_ text: String) -> String {
        let components = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, component in
                component.capitalized
            }
            .joined()
    }

    private static func formatPreconditions(_ preconditions: [String]?) -> String {
        guard let preconditions = preconditions, !preconditions.isEmpty else {
            return TestDataConstants.SwiftTestGeneration.noPreconditions
        }

        return preconditions
            .map { String(format: TestDataConstants.Format.preconditionFormat, $0) }
            .joined(separator: TestDataConstants.SwiftCodeGeneration.newline)
    }

    private static func formatTestSteps(_ steps: [TestStep]) -> String {
        return steps.enumerated().map { index, step in
            formatTestStep(step, index: index)
        }.joined(separator: "\n\n")
    }

    private static func formatTestStep(_ step: TestStep, index: Int) -> String {
        var result = String(
            format: TestDataConstants.SwiftTestGeneration.stepCommentFormat,
            index + 1,
            step.action
        )

        if let data = step.data {
            result += TestDataConstants.SwiftCodeGeneration.newline
            result += String(
                format: TestDataConstants.SwiftTestGeneration.stepDataFormat,
                index + 1,
                formatTestData(data)
            )
        }

        if let validation = step.validation {
            result += TestDataConstants.SwiftCodeGeneration.newline
            result += String(
                format: TestDataConstants.Validation.validatingFormat,
                validation
            )
        }

        return result
    }

    private static func formatTestData(_ data: [String: AnyCodable]) -> String {
        // Generate Swift dictionary literal
        let entries = data.map { key, value in
            String(format: TestDataConstants.SwiftCodeGeneration.dictionaryEntryFormat, key, formatValue(value))
        }
        return String(
            format: TestDataConstants.SwiftCodeGeneration.dictionaryFormat,
            entries.joined(separator: TestDataConstants.SwiftCodeGeneration.separator)
        )
    }

    private static func formatValue(_ value: AnyCodable) -> String {
        if let stringValue = value.value as? String {
            return String(format: TestDataConstants.SwiftCodeGeneration.stringValueFormat, stringValue)
        } else if let numberValue = value.value as? NSNumber {
            return "\(numberValue)"
        } else if let boolValue = value.value as? Bool {
            return "\(boolValue)"
        } else {
            return TestDataConstants.AssertionKeywords.nilKeyword
        }
    }

    private static func formatExpectedResults(_ results: [String]) -> String {
        return results
            .map { String(format: TestDataConstants.SwiftTestGeneration.resultFormat, $0) }
            .joined(separator: TestDataConstants.SwiftCodeGeneration.newline)
    }

    // MARK: - Assertion Generation

    /// Generates XCTest assertions from expected results
    public static func generateAssertions(for results: [String]) -> [String] {
        return results.map { result in
            generateAssertion(for: result)
        }
    }

    private static func generateAssertion(for result: String) -> String {
        // Parse the result to determine assertion type
        if result.contains(TestDataConstants.AssertionKeywords.equal) {
            return generateEqualityAssertion(result)
        } else if result.contains(TestDataConstants.AssertionKeywords.trueKeyword) || result.contains(TestDataConstants.AssertionKeywords.falseKeyword) {
            return generateBooleanAssertion(result)
        } else if result.contains(TestDataConstants.AssertionKeywords.nilKeyword) {
            return generateNilAssertion(result)
        } else if result.contains(TestDataConstants.AssertionKeywords.throwsKeyword) || result.contains(TestDataConstants.AssertionKeywords.errorKeyword) {
            return generateErrorAssertion(result)
        } else {
            // Default assertion
            return String(
                format: TestDataConstants.Validation.todoValidation,
                result
            )
        }
    }

    private static func generateEqualityAssertion(_ result: String) -> String {
        return String(
            format: TestDataConstants.SwiftTestGeneration.assertFormat,
            TestDataConstants.Assertions.assertEqual
        ) + "(actual, expected)"
    }

    private static func generateBooleanAssertion(_ result: String) -> String {
        let assertType = result.contains(TestDataConstants.AssertionKeywords.falseKeyword) ?
            TestDataConstants.Assertions.assertFalse :
            TestDataConstants.Assertions.assertTrue

        return String(
            format: TestDataConstants.SwiftTestGeneration.assertFormat,
            assertType
        ) + "(condition)"
    }

    private static func generateNilAssertion(_ result: String) -> String {
        let assertType = result.contains(TestDataConstants.AssertionKeywords.notKeyword) ?
            TestDataConstants.Assertions.assertNotNil :
            TestDataConstants.Assertions.assertNil

        return String(
            format: TestDataConstants.SwiftTestGeneration.assertFormat,
            assertType
        ) + "(value)"
    }

    private static func generateErrorAssertion(_ result: String) -> String {
        let assertType = result.contains(TestDataConstants.AssertionKeywords.noKeyword) || result.contains(TestDataConstants.AssertionKeywords.notKeyword) ?
            TestDataConstants.Assertions.assertNoThrow :
            TestDataConstants.Assertions.assertThrows

        return String(
            format: TestDataConstants.SwiftTestGeneration.assertFormat,
            assertType
        ) + " { try operation() }"
    }
}