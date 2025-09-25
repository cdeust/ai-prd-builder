import Foundation

public enum PRDPrompts {

    // MARK: - System Instruction (YOUR EXACT PROMPT)

    public static let systemPrompt = """
    <instruction>
    You are a product development assistant. Your task is to generate a comprehensive Product Requirements Document (PRD) that aligns with Apple's technical and design standards.

    <goal>
    Plan and structure a comprehensive PRD based entirely on the user's input, including:
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
    <task>Generate Feature/Task Overview</task>

    <input>%%@</input>

    <instruction>
    Plan and structure your analysis of the task description provided, then write a focused overview of ONLY this specific feature or change.

    IMPORTANT ASSUMPTIONS:
    - This is likely an addition or modification to an EXISTING system
    - Core infrastructure, authentication, database, and basic features already exist
    - Focus ONLY on what's NEW or CHANGING with this specific task

    Explain:
    - What specific feature/change is being implemented
    - The problem this particular change solves
    - How it fits into the existing system
    - The value it adds to current functionality

    Keep it concise and task-focused. Do not describe the entire system.
    </instruction>
    """

    public static let userStoriesPrompt = """
    <task>Generate User Stories</task>

    <input>%%@</input>

    <instruction>
    Plan your user story creation. Think from the user's perspective and empathize with their needs. Extract user stories for ONLY this specific task/feature.

    ASSUMPTIONS:
    - Basic user roles and authentication already exist
    - Focus on stories specific to this NEW functionality
    - Don't include generic stories (login, logout, etc.) unless explicitly mentioned

    Format as a markdown table with these columns:
    | As a... | I want to... | So that... | Acceptance Criteria |

    Create stories ONLY for:
    - New user interactions introduced by this task
    - Modified workflows affected by this change
    - Specific acceptance criteria for this feature

    Keep it minimal and directly related to the described task.
    </instruction>
    """

    public static let dataModelPrompt = """
    <task>Generate Data Model Changes</task>

    <input>%%@</input>

    <instruction>
    Plan your data architecture. Think carefully about data relationships, integrity, and scalability. Define ONLY the data model CHANGES or ADDITIONS needed for this specific task.

    ASSUMPTIONS:
    - User, Auth, and other basic entities already exist
    - Only specify NEW entities or MODIFICATIONS to existing ones
    - If no data model changes are needed, state "No data model changes required"

    For NEW entities only:
    **[Entity Name]** (New)
    | Field | Type | Description | Required |
    |-------|------|-------------|----------|

    For MODIFIED entities:
    **[Entity Name]** (Modified)
    | New Field | Type | Description | Required |
    |-----------|------|-------------|----------|

    For NEW relationships:
    **New Relationships:**
    - [Entity1] → [Entity2]: [relationship description]

    Only include what's changing or being added for this task.
    </instruction>
    """

    public static let featuresPrompt = """
    <task>Generate Features List</task>

    <input>%%@</input>

    <instruction>
    Plan your feature breakdown and think strategically about functional requirements and user value. List ONLY the specific features/capabilities being added or modified by this task.

    ASSUMPTIONS:
    - Core features of the system already exist
    - Don't list existing features unless they're being modified
    - Focus on what's NEW or CHANGING

    Format as:
    ## New Features
    - [Feature name]: [Brief description of what it does]

    ## Modified Features (if any)
    - [Existing feature]: [What's changing]

    If this is a bug fix or minor enhancement, just list the single change.
    Keep it focused on THIS task only.
    </instruction>
    """

    public static let apiSpecPrompt = """
    <task>Generate API Operations for Task</task>

    <input>%%@</input>

    <instruction>
    Plan your API design. Research API best practices and industry standards. List ONLY the NEW or MODIFIED API operations needed for this specific task.

    ASSUMPTIONS:
    - Standard CRUD operations for existing entities are already implemented
    - Auth, user management, and basic APIs exist
    - Focus ONLY on operations specific to this task

    Format each NEW operation as:
    **[Operation Name]** (New)
    - Business action: [What it does]
    - Triggered by: [Who/when it's used]
    - Success: [Expected outcome]
    - Failures: [What could go wrong]

    Format MODIFIED operations as:
    **[Operation Name]** (Modified)
    - Change: [What's different]
    - Reason: [Why it needs to change]

    If no new API operations are needed, state "Uses existing API operations"
    </instruction>
    """

    public static let testSpecPrompt = """
    <task>Generate Test Specifications</task>

    <input>%%@</input>

    <instruction>
    Plan your testing approach. Think systematically about test coverage and edge cases. Generate test specifications for ONLY this specific task/feature.

    ASSUMPTIONS:
    - Existing test suite and infrastructure is in place
    - Basic tests for auth, CRUD operations, etc. already exist
    - Focus ONLY on tests specific to this new functionality

    Structure your response as:

    ## New Tests Required

    ### Unit Tests
    - [Specific feature]: [What to verify]

    ### Integration Tests
    - [How this integrates]: [Expected behavior]

    ### Edge Cases (if any)
    - [Task-specific edge case]: [How to handle]

    If this task requires minimal testing, state that and list 2-3 key tests.
    Don't over-specify - assume standard testing practices are followed.
    </instruction>
    """

    public static let constraintsPrompt = """
    <task>Define Task-Specific Constraints</task>

    <input>%%@</input>
    <technicalStack>%%@</technicalStack>

    <instruction>
    Think critically about limitations and dependencies. Identify ONLY constraints specific to this task/feature.

    ASSUMPTIONS:
    - System-wide constraints (auth, general performance, security) already defined
    - Focus ONLY on additional constraints introduced by this specific feature

    List only if applicable:
    - **Performance**: Any special requirements for this feature
    - **Security**: Additional security needs beyond standard
    - **Data**: Specific data constraints for this feature
    - **Integration**: Constraints from external systems

    If this task introduces no special constraints beyond standard practices,
    state: "No additional constraints. Follows existing system standards."

    Keep it brief and task-specific.
    </instruction>
    """

    public static let validationPrompt = """
    <task>Generate Validation Criteria</task>

    <input>%%@</input>

    <instruction>
    Think rigorously about verification and quality assurance. Define validation criteria for THIS specific task only.

    ASSUMPTIONS:
    - Standard validation (auth, data integrity, etc.) already exists
    - Focus on success criteria specific to this feature

    **Task Completion Criteria**
    - Success looks like: [What indicates this task is done]
    - How to verify: [Specific verification for this feature]
    - Key metrics: [If applicable]

    Keep it minimal - 2-4 criteria maximum.
    Must be directly related to the described task.
    If it's a simple task, one clear success criteria is sufficient.
    </instruction>
    """

    public static let roadmapPrompt = """
    <task>Generate Implementation Steps</task>

    <input>%%@</input>

    <instruction>
    Plan systematically and think step-by-step through the implementation timeline and dependencies. Create a focused implementation plan for ONLY this specific task.

    ASSUMPTIONS:
    - Development environment, CI/CD, and deployment pipelines already exist
    - Basic architecture and infrastructure is in place
    - This is an incremental change to an existing system

    Format as simple steps:

    **Implementation Steps:**
    TODO: [First concrete action for this task]
    TODO: [Next step specific to this feature]
    TODO: [Continue with task-specific steps]

    **Integration Points:**
    - [How this integrates with existing system]
    - [Any existing components that need updates]

    **Testing Strategy:**
    - [Specific tests for this feature]
    - [Integration tests needed]

    Keep it practical and focused on THIS task only.
    Typically 3-7 steps maximum.
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

    <input>%%@</input>

    <instruction>
    Plan your technical discovery approach. Research and explore the technical requirements implied by this product description. Think about potential technical challenges and identify clarifying questions about:
    - Programming languages to be used
    - Testing frameworks and methodologies
    - CI/CD pipeline preferences
    - Deployment environment (cloud, on-premise, hybrid)
    - Database and storage requirements
    - Security and compliance requirements
    - Performance requirements and SLAs
    - Integration requirements with existing systems

    IMPORTANT: Consider platform compatibility when asking questions.
    Avoid suggesting platform-specific technologies unless explicitly mentioned.

    Format as a list of specific questions that need answers before proceeding.
    </instruction>
    """

    // MARK: - Validation and Verification Prompts

    public static let responseValidationPrompt = """
    <task>Validate Response Quality</task>

    <input>
    Original Input: %%@
    Generated Response: %%@
    </input>

    <instruction>
    Think carefully and critically analyze the generated response. Consider edge cases and potential issues, then provide:
    - Confidence score (0-100) in how well it matches requirements
    - List of assumptions made that weren't explicit in the input
    - List of potential gaps or missing information
    - Areas that need clarification or could be misinterpreted
    - Recommendations for improvement

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

    <input>
    Assumptions: %%@
    Context: %%@
    </input>

    <instruction>
    Think step-by-step through each assumption. For each one:
    - Determine if it's explicitly stated or inferred
    - Assess the risk if the assumption is incorrect
    - Suggest how to verify or validate the assumption
    - Provide alternative interpretations if possible

    Format as structured analysis with clear verification steps.
    </instruction>
    """

    public static let challengeResponsePrompt = """
    <task>Challenge and Improve Response</task>

    <input>
    Original Response: %%@
    Validation Results: %%@
    </input>

    <instruction>
    Reflect on the validation feedback and think about how to improve. Generate an enhanced version that:
    - Addresses identified gaps
    - Makes assumptions explicit
    - Provides alternatives where uncertainty exists
    - Includes confidence indicators for each section
    - Adds clarification requests where needed

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

    // MARK: - Analysis Prompts

    public static let requirementsAnalysisPrompt = """
    <task>Analyze Requirements Completeness</task>

    <input>%@</input>

    <instruction>
    Think deeply about the provided product requirements. Consider what might be missing or unclear, then identify:
    - Areas that need clarification for accurate PRD generation
    - Implicit assumptions that should be validated
    - Critical gaps that would affect implementation
    - Overall confidence score (0-100) for generating a complete PRD

    Focus on ACTIONABLE clarifications that would significantly improve the PRD quality.

    Format your response as JSON:
    ```json
    {
      "confidence": 75,
      "clarifications_needed": [
        "What specific authentication method should be used (OAuth, JWT, etc.)?",
        "Should the snippets support versioning or history tracking?",
        "What are the expected performance requirements (response times, concurrent users)?"
      ],
      "assumptions": [
        "Assuming REST API architecture",
        "Assuming PostgreSQL for database"
      ],
      "gaps": [
        "No error handling strategy defined",
        "Missing scalability requirements"
      ]
    }
    ```
    </instruction>
    """

    public static let technicalStackAnalysisPrompt = """
    <task>Analyze Technical Stack Requirements</task>

    <input>%@</input>

    <instruction>
    Think systematically about the technical stack requirements. Consider dependencies, integrations, and architectural implications, then identify:
    - Missing technical stack details that need clarification
    - Platform-specific requirements that should be validated
    - Integration requirements that need confirmation
    - Performance and scalability requirements

    Focus on TECHNICAL clarifications that affect architecture and implementation.

    Format your response as JSON:
    ```json
    {
      "confidence": 70,
      "clarifications_needed": [
        "What programming language/framework should be used?",
        "What database system is preferred (PostgreSQL, MongoDB, etc.)?",
        "What are the expected performance requirements (response times, concurrent users)?",
        "Should this include CI/CD pipeline setup?",
        "What authentication method should be implemented (JWT, OAuth, etc.)?"
      ],
      "assumptions": [
        "Assuming REST API architecture",
        "Assuming cloud deployment"
      ],
      "gaps": [
        "No deployment strategy specified",
        "Missing security requirements"
      ]
    }
    ```
    </instruction>
    """

    public static let reanalysisWithContextPrompt = """
    <task>Re-analyze Requirements with Additional Context</task>

    <input>%@</input>

    <instruction>
    Think through the requirements again with the new context. Re-analyze and reconsider your confidence level.
    Calculate a new confidence score based on the enriched context.

    Format your response as JSON:
    ```json
    {
      "confidence": 85,
      "clarifications_needed": [],
      "assumptions": [
        "Using provided technology choices",
        "Following specified requirements"
      ],
      "gaps": []
    }
    ```
    </instruction>
    """

    // MARK: - Mockup Analysis Prompts

    public static let mockupSystemRolePrompt = "You are analyzing mockups to extract product requirements. Focus on observable features and implied functionality."

    public static let mockupAnalysisPrompt = """
    <task>Analyze Mockups for Requirements</task>

    <instruction>
    Plan your mockup analysis systematically. Extract and describe:
    - Key features visible in the UI
    - User workflows and interactions
    - Data fields and forms present
    - Navigation structure
    - Business logic implied by the interface
    - User roles if apparent
    - Any integration points suggested

    Provide a comprehensive description that can be used to generate a PRD.
    </instruction>
    """

    public static func buildMockupAnalysisPrompt(paths: [String], guidelines: String?, context: String?) -> String {
        var inputSection = """
        Mockup Files:
        \(paths.map { "- \($0)" }.joined(separator: "\n"))
        """

        if let guidelines = guidelines {
            inputSection += "\n\nDesign Guidelines:\n\(guidelines)"
        }

        if let context = context {
            inputSection += "\n\nAdditional Context:\n\(context)"
        }

        return """
        <task>Analyze Mockups for Requirements</task>

        <input>
        \(inputSection)
        </input>

        <instruction>
        Plan your mockup analysis approach. Analyze the mockup/wireframe files to extract requirements.

        Extract and describe:
        - Key features visible in the UI
        - User workflows and interactions
        - Data fields and forms present
        - Navigation structure
        - Business logic implied by the interface
        - User roles if apparent
        - Any integration points suggested

        Provide a comprehensive description that can be used to generate a PRD.
        </instruction>
        """
    }

    // MARK: - Test Generation Prompts

    public static let endpointTestPrompt = """
    <task>Generate Endpoint Test Cases</task>

    <input>API Endpoint: %@</input>

    <instruction>
    Generate comprehensive test cases for the specified API endpoint.

    Include:
    - Success scenarios
    - Error cases
    - Validation tests
    - Edge cases
    - Expected result for each test
    </instruction>
    """

    public static let integrationTestPrompt = """
    <task>Generate Integration Test Cases</task>

    <input>API Endpoints: %@</input>

    <instruction>
    Plan comprehensive integration test cases for the API with the specified endpoints. Structure your test scenarios systematically.

    Include:
    - Workflow tests
    - State transitions
    - Cross-endpoint dependencies
    - Data consistency checks
    - State management validation
    </instruction>
    """

    public static let validationTestPrompt = """
    <task>Generate Validation Test Cases</task>

    <instruction>
    Generate validation test cases for OpenAPI specification validation.

    Include:
    - Schema validation
    - Request/response format validation
    - Required fields verification
    - Type checking
    - Constraint validation
    </instruction>
    """

    // MARK: - Code Analysis Prompts (Archaeological)

    public static let codebaseStructurePrompt = """
    <task>Analyze Codebase Structure</task>

    <input>Codebase Path: %@</input>

    <instruction>
    Plan your codebase exploration strategy. Explore and investigate the codebase structure at the specified path. Think about the architectural patterns and design decisions.

    Identify:
    - File and directory organization
    - Primary programming language
    - Frameworks and libraries used
    - Architectural patterns
    - Key entry points
    </instruction>
    """

    public static let codingPatternsPrompt = """
    <task>Identify Coding Patterns</task>

    <input>
    Structure: %@
    Focus area: %@
    </input>

    <instruction>
    Research and discover coding patterns in the specified codebase structure. Think about consistency and best practices.

    Look for:
    - Design patterns (MVC, MVVM, etc.)
    - Code organization principles
    - Naming conventions
    - Testing strategies
    - Error handling patterns
    </instruction>
    """

    public static let codeArtifactsPrompt = """
    <task>Analyze Code Artifacts</task>

    <input>
    Focus: %@
    Patterns found: %@
    </input>

    <instruction>
    Analyze significant code artifacts based on the identified patterns.

    Identify:
    - Core business logic components
    - Key data models
    - Critical algorithms
    - Integration points
    - Technical debt indicators
    </instruction>
    """

    public static let dependencyChainPrompt = """
    <task>Map Dependency Chains</task>

    <input>Artifacts: %@</input>

    <instruction>
    Plan and map dependency chains for the specified artifacts systematically.

    For each significant dependency:
    - Direct dependencies
    - Transitive dependencies
    - Circular dependencies
    - External dependencies
    - Risk assessment
    </instruction>
    """

    public static let historicalAnalysisPrompt = """
    <task>Analyze Historical Evolution</task>

    <input>
    Based on patterns: %@
    And artifacts: %@ items
    </input>

    <instruction>
    Think like an archaeologist - piece together clues to reconstruct the historical evolution of this codebase. Consider the layers of changes over time.

    Infer:
    - Original architecture
    - Major refactorings
    - Technology migrations
    - Team changes evident in code style
    - Technical debt accumulation
    </instruction>
    """

    // MARK: - Implementation Analysis Prompts

    public static let implementationHypothesisPrompt = """
    <task>Generate Implementation Hypotheses</task>

    <input>
    PRD requirement: %@
    Architecture: %@
    Key patterns: %@
    </input>

    <instruction>
    Plan your implementation approach. Think critically about where and how this feature would fit into the existing codebase. Reason through the implementation and generate hypotheses about:
    - Where this feature would be implemented
    - What existing code needs modification
    - Integration points required
    - Potential conflicts or challenges
    </instruction>
    """

    public static let discrepancyAnalysisPrompt = """
    <task>Analyze Implementation Discrepancies</task>

    <input>
    PRD: %@
    Verification Results: %@
    </input>

    <instruction>
    Carefully compare the PRD requirements against the verification results. Think about what's missing or different, then identify discrepancies:
    - Missing implementations
    - Partial implementations
    - Conflicting implementations
    - Unexpected behaviors
    </instruction>
    """

    public static let rootCauseAnalysisPrompt = """
    <task>Perform Root Cause Analysis</task>

    <input>Discrepancies: %@</input>

    <instruction>
    Think deeply and systematically to perform root cause analysis on the identified discrepancies. Use first principles thinking.

    For each major issue:
    - Start with the symptom
    - Ask "why" five times
    - Identify root technical cause
    - Suggest remediation
    </instruction>
    """

    public static let implementationStrategyPrompt = """
    <task>Create Implementation Strategy</task>

    <input>
    Requirements: %@
    Verified State: %@
    Gaps: %@
    </input>

    <instruction>
    Plan comprehensively and think strategically about the implementation approach. Consider risks, dependencies, and order of operations to create a comprehensive strategy.

    Provide:
    - Priority order for changes
    - Risk assessment
    - Dependencies between changes
    - Migration path if needed
    </instruction>
    """

    public static let criticalChangesPrompt = """
    <task>Identify Critical Changes</task>

    <input>
    Strategy: %@
    Discrepancies: %@
    </input>

    <instruction>
    Plan your migration approach. Identify critical changes that need careful migration.

    For each critical change:
    - Impact radius
    - Breaking changes
    - Data migration needs
    - Rollback plan
    </instruction>
    """

    public static let testStrategyPrompt = """
    <task>Create Test Strategy</task>

    <input>
    Requirements: %@
    Critical Changes: %@ changes
    </input>

    <instruction>
    Plan a comprehensive test strategy for the requirements and changes. Organize your testing approach systematically.

    Include:
    - Unit test coverage targets
    - Integration test scenarios
    - Performance benchmarks
    - Regression test suite
    </instruction>
    """

    public static let rolloutPlanPrompt = """
    <task>Create Rollout Plan</task>

    <input>
    Critical Changes: %@
    Strategy: %@
    </input>

    <instruction>
    Plan the deployment carefully. Think about risk mitigation and safe deployment practices. Create a thoughtful rollout plan for the changes.

    Define:
    - Deployment phases
    - Feature flags needed
    - Monitoring requirements
    - Rollback triggers
    </instruction>
    """

    // MARK: - PRD-Code Bridge Prompts

    public static let featureToCodeMappingPrompt = """
    <task>Map Feature to Code</task>

    <input>
    Feature from PRD: "%@"
    Source files in project:
    %@
    </input>

    <instruction>
    Identify which files are most likely to contain or need implementation for this feature.
    List top 5-10 files with confidence scores.
    </instruction>
    """

    public static let codeFeatureAnalysisPrompt = """
    <task>Analyze Code for Feature Implementation</task>

    <input>
    Feature: "%@"
    File: %@
    Content preview:
    %@
    </input>

    <instruction>
    Analyze this code file for implementation of the specified feature.

    Determine if this feature is:
    - Fully implemented
    - Partially implemented
    - Not implemented
    - Has related code but different from PRD

    Provide evidence and line numbers.
    </instruction>
    """

    public static let extractFeaturesFromPRDPrompt = """
    <task>Extract Features from PRD</task>

    <input>%@</input>

    <instruction>
    Extract distinct features from this PRD.
    List each feature as a single line description.
    Focus on implementable features, not requirements or constraints.
    </instruction>
    """
}