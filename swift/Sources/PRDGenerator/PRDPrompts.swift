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
    - API endpoints overview with business logic descriptions
    - Test specifications for described features
    - Performance, security, and compatibility constraints
    - Validation criteria for stated requirements
    - Technical roadmap based on scope
    </goal>

    <outputFormat>
    Present PRD sections in Markdown. For API endpoints, use simple bulleted lists with descriptions. For summary lists or validation checklists, use JSON code blocks. All output must be valid and immediately usable by developers.
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
    <task>Generate API Endpoints Overview</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create a high-level overview of API endpoints needed for this product.
    Focus on WHAT endpoints are needed and WHY, not implementation details.
    DO NOT generate OpenAPI specifications, YAML schemas, or technical contracts.

    For each endpoint, provide:
    - Endpoint path and HTTP method
    - Purpose and use case
    - Main success/error scenarios to handle
    - Brief description of data flow

    Format as a simple Markdown list (NO YAML, NO OpenAPI):

    ## API Endpoints

    ### User Management
    - `POST /api/users/register` - User registration
      - Purpose: Create new user account
      - Success: User created, return user ID
      - Errors: Duplicate email, invalid data
      - Data flow: Receive user details → Validate → Store → Return confirmation

    - `GET /api/users/{id}` - Get user profile
      - Purpose: Retrieve user information
      - Success: Return user data
      - Errors: User not found, unauthorized
      - Data flow: Verify auth → Fetch user → Return filtered data

    ### [Other sections as needed]

    Focus on business logic and use cases. Developers will handle the technical contract implementation.
    IMPORTANT: Output should be in plain Markdown format only. No YAML blocks, no OpenAPI specifications.
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

    // MARK: - Stack Discovery Prompts

    public static let stackDiscoveryPrompt = """
    <task>Discover Technical Stack</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Based on the product description, identify and ask clarifying questions about:
    1. Programming languages to be used
    2. Testing frameworks and methodologies
    3. CI/CD pipeline preferences
    4. Deployment environment (cloud, on-premise, hybrid)
    5. Database and storage requirements
    6. Security and compliance requirements
    7. Performance requirements and SLAs
    8. Integration requirements with existing systems

    IMPORTANT: Consider platform compatibility when asking questions.
    Avoid suggesting platform-specific technologies unless explicitly mentioned.

    Format as a list of specific questions that need answers before proceeding.
    </instruction>
    """

    // MARK: - Validation and Verification Prompts

    public static let responseValidationPrompt = """
    <task>Validate Response Quality</task>

    <originalInput>%%@</originalInput>
    <generatedResponse>%%@</generatedResponse>

    <instruction>
    Analyze the generated response and provide:
    1. Confidence score (0-100) in how well it matches requirements
    2. List of assumptions made that weren't explicit in the input
    3. List of potential gaps or missing information
    4. Areas that need clarification or could be misinterpreted
    5. Recommendations for improvement

    Format as JSON:
    ```json
    {
      "confidence": 85,
      "assumptions": ["assumption1", "assumption2"],
      "gaps": ["gap1", "gap2"],
      "clarifications_needed": ["clarification1"],
      "recommendations": ["recommendation1"]
    }
    ```
    </instruction>
    """

    public static let hypothesisVerificationPrompt = """
    <task>Verify Assumptions and Hypotheses</task>

    <assumptions>%%@</assumptions>
    <context>%%@</context>

    <instruction>
    For each assumption listed:
    1. Determine if it's explicitly stated or inferred
    2. Assess the risk if the assumption is incorrect
    3. Suggest how to verify or validate the assumption
    4. Provide alternative interpretations if possible

    Format as structured analysis with clear verification steps.
    </instruction>
    """

    public static let challengeResponsePrompt = """
    <task>Challenge and Improve Response</task>

    <originalResponse>%%@</originalResponse>
    <validationResults>%%@</validationResults>

    <instruction>
    Based on the validation results, generate an improved version that:
    1. Addresses identified gaps
    2. Makes assumptions explicit
    3. Provides alternatives where uncertainty exists
    4. Includes confidence indicators for each section
    5. Adds clarification requests where needed

    Maintain the same format but enhance quality and accuracy.
    </instruction>
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