import Foundation
import CommonModels
import DomainCore
import AIProvidersCore

public final class TestGenerator: TestGeneratorProtocol {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public func generateTests(for spec: OpenAPISpecification) async throws -> TestSuite {
        var tests: [TestCase] = []

        // Generate API endpoint tests
        for (path, _) in spec.paths {
            let endpointTests = try await generateEndpointTests(path: path, spec: spec)
            tests.append(contentsOf: endpointTests)
        }

        // Generate integration tests
        let integrationTests = try await generateIntegrationTests(spec: spec)
        tests.append(contentsOf: integrationTests)

        // Generate validation tests
        let validationTests = try await generateValidationTests(spec: spec)
        tests.append(contentsOf: validationTests)

        return TestSuite(
            name: "\(spec.info["title"] as? String ?? "API") Test Suite",
            tests: tests
        )
    }

    private func generateEndpointTests(path: String, spec: OpenAPISpecification) async throws -> [TestCase] {
        let prompt = """
        Generate comprehensive test cases for API endpoint: \(path)

        Include:
        - Happy path tests
        - Error handling tests
        - Edge case tests
        - Authentication tests

        Format each test with:
        - Test name
        - Description
        - Steps
        - Expected result
        """

        let messages = [
            ChatMessage(role: .system, content: "You are an expert QA engineer."),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return parseTestCases(from: response, prefix: "Endpoint_\(path)")
        case .failure(let error):
            throw error
        }
    }

    private func generateIntegrationTests(spec: OpenAPISpecification) async throws -> [TestCase] {
        let paths = Array(spec.paths.keys).joined(separator: ", ")
        let prompt = """
        Generate integration test cases for API with endpoints: \(paths)

        Focus on:
        - Cross-endpoint workflows
        - Data consistency
        - Transaction flows
        - State management
        """

        let messages = [
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return parseTestCases(from: response, prefix: "Integration")
        case .failure(let error):
            throw error
        }
    }

    private func generateValidationTests(spec: OpenAPISpecification) async throws -> [TestCase] {
        let prompt = """
        Generate validation test cases for OpenAPI spec validation.

        Include:
        - Schema validation
        - Required field validation
        - Data type validation
        - Constraint validation
        """

        let messages = [
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return parseTestCases(from: response, prefix: "Validation")
        case .failure(let error):
            throw error
        }
    }

    private func parseTestCases(from response: String, prefix: String) -> [TestCase] {
        var tests: [TestCase] = []
        let sections = response.split(separator: "\n\n")

        for (index, section) in sections.enumerated() {
            let lines = section.split(separator: "\n")
            guard lines.count > 0 else { continue }

            let name = "\(prefix)_Test_\(index + 1)"
            let description = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""

            var steps: [String] = []
            var expectedResult = ""
            var inSteps = false
            var inExpected = false

            for line in lines.dropFirst() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if trimmed.lowercased().contains("step") || trimmed.hasPrefix("-") || trimmed.hasPrefix("•") {
                    inSteps = true
                    inExpected = false
                    if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") {
                        steps.append(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
                    }
                } else if trimmed.lowercased().contains("expected") {
                    inSteps = false
                    inExpected = true
                } else if inSteps && !trimmed.isEmpty {
                    steps.append(trimmed)
                } else if inExpected && !trimmed.isEmpty {
                    expectedResult += trimmed + " "
                }
            }

            if !steps.isEmpty {
                tests.append(TestCase(
                    name: name,
                    description: String(description),
                    steps: steps,
                    expectedResult: expectedResult.trimmingCharacters(in: .whitespaces)
                ))
            }
        }

        return tests
    }
}