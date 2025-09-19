import Foundation

public enum PRDPrompts {

    // MARK: - System Instruction (YOUR EXACT PROMPT)

    public static let systemPrompt = """
    <instruction>
    You are a product development assistant. Your task is to generate a comprehensive Product Requirements Document (PRD) that aligns with Apple's technical and design standards.

    <goal>
    Create a PRD based entirely on the user's input, including:
    - Product goals derived from the description
    - Target users identified from the context
    - User stories extracted from requirements
    - Features list based on described functionality
    - OpenAPI 3.1.0 specification for mentioned APIs
    - Test specifications for described features
    - Performance, security, and compatibility constraints
    - Validation criteria for stated requirements
    - Technical roadmap based on scope
    </goal>

    <outputFormat>
    Present PRD sections in Markdown. For API specifications, use YAML code blocks. For summary lists or validation checklists, use JSON code blocks. All output must be valid and immediately usable by developers.
    </outputFormat>

    <requirements>
    - Use Apple Human Interface Guidelines styling for any UI reasoning
    - Never invent facts or make unsupported assumptions; only use content provided
    - Generate specifications based solely on the user's input
    - After each PRD section, provide a one-sentence summary on how it fulfills the requirements
    </requirements>
    </instruction>
    """

    // MARK: - Split Prompts for Each Section

    public static let overviewPrompt = """
    <task>Generate Product Overview</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create only the Product Overview section including:
    - Product goals (2-3 sentences)
    - Target users and usage contexts
    </instruction>
    """

    public static let userStoriesPrompt = """
    <task>Generate User Stories</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create user stories in table format:
    | As a... | I want to... | So that... | Acceptance Criteria |
    </instruction>
    """

    public static let featuresPrompt = """
    <task>Generate Features List</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create features list (major and minor) based on the described functionality.
    </instruction>
    """

    public static let apiSpecPrompt = """
    <task>Generate API Specification</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create OpenAPI 3.1.0 specification in YAML:
    ```yaml
    openapi: 3.1.0
    info:
      title: "API Title"
      version: "1.0.0"
    paths:
      # Define endpoints based on features
    components:
      schemas:
        # Define data models
    ```
    </instruction>
    """

    public static let testSpecPrompt = """
    <task>Generate Test Specifications</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create detailed test specifications:
    - Unit tests
    - Functional tests
    - Edge case tests
    - Acceptance tests

    Use XCTest format for examples:
    ```swift
    import XCTest
    @testable import Module

    final class Tests: XCTestCase {
        func test() async throws {
            // Test implementation
        }
    }
    ```
    </instruction>
    """

    public static let constraintsPrompt = """
    <task>Define Constraints</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Define performance, security, and compatibility constraints for the Apple ecosystem.
    </instruction>
    """

    public static let validationPrompt = """
    <task>Generate Validation Criteria</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create validation criteria for every requirement in JSON format:
    ```json
    {
      "features": [
        { "name": "Feature Name", "priority": "High/Medium/Low" }
      ]
    }
    ```
    </instruction>
    """

    public static let roadmapPrompt = """
    <task>Generate Technical Roadmap</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create technical roadmap and CI/CD pipeline suggestions.
    </instruction>
    """

    // MARK: - Example Output Formats

    public static let exampleAPIOutput = """
    <exampleOutput>
    openapi: "3.1.0"
    info:
      title: "Support Task API"
      version: "1.0.0"
    # ... additional OpenAPI specification
    </exampleOutput>
    """

    public static let exampleFeaturesOutput = """
    <exampleOutput>
    {
      "features": [
        { "name": "Real-Time Sync", "priority": "High" },
        { "name": "Notifications", "priority": "Medium" }
      ]
    }
    </exampleOutput>
    """

    // MARK: - Context Enhancement

    public static func enhanceWithContext(_ prompt: String, context: String) -> String {
        return """
        <context>
        \(context)
        </context>

        <instruction>
        \(prompt)
        </instruction>
        """
    }
}