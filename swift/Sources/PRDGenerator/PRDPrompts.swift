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
    Write clear, professional prose. Use markdown headings and formatting for structure. Avoid unnecessary code blocks or JSON formatting unless specifically displaying code or data structures.
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
    <task>Generate ONLY Overview Section</task>

    <input>%%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Do NOT invent or imagine requirements not explicitly mentioned in the input.
    This could be a feature, bug fix, improvement, refactoring, or any other type of change.

    Write 2-3 paragraphs for the Overview section:
    - What this specific request/change does (as described in the input)
    - The problem it solves or need it addresses (as stated in the input)
    - The value it provides (as mentioned in the input)

    CRITICAL: Output ONLY the overview content.
    Do NOT include user stories, features list, or any other sections.
    Do NOT mention "this document" or "this PRD" - just write the overview.
    Base your response ONLY on the input provided above.
    </instruction>
    """

    public static let userStoriesPrompt = """
    <task>Generate ONLY User Stories Section</task>

    <input>%%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Create user stories ONLY for that exact request, not imagined functionality.

    Write 2-4 user stories as clear paragraphs (not a table).

    For each story:
    - State the user type (from the input)
    - What they want to do (based on the input)
    - Why it matters to them (inferred from the input)
    - How we verify success (based on acceptance criteria in input)

    CRITICAL: Output ONLY the user stories.
    Do NOT include overview, features, or any other sections.
    Base your response ONLY on the input provided above.
    </instruction>
    """

    public static let dataModelPrompt = """
    <task>Generate Data Model Changes</task>

    <input>%%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Define ONLY the data model CHANGES or ADDITIONS needed for that exact request.

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
    <task>Generate ONLY Features List Section</task>

    <input>%%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Do NOT invent additional functionality beyond what is explicitly mentioned.
    List the specific functionality/capabilities described in the input.

    Use bullet points:
    - Feature name: Brief description
    - Another feature: What it does

    CRITICAL: Output ONLY the features list.
    Do NOT include overview, user stories, or technical details.
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
    Plan your testing approach. Think systematically about test coverage and edge cases. Generate test specifications for ONLY this specific request.

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
    Think critically about limitations and dependencies. Identify ONLY constraints specific to this request.

    ASSUMPTIONS:
    - System-wide constraints (auth, general performance, security) already defined
    - Focus ONLY on additional constraints introduced by this specific request

    List only if applicable:
    - **Performance**: Any special requirements for this request
    - **Security**: Additional security needs beyond standard
    - **Data**: Specific data constraints for this request
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
    - Focus on success criteria specific to this request

    **Task Completion Criteria**
    - Success looks like: [What indicates this task is done]
    - How to verify: [Specific verification for this request]
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
    Analyze the provided requirements to identify what information is missing or unclear.
    Focus on CRITICAL decisions that cannot be inferred and would significantly impact the architecture.

    Evaluate:
    1. What architectural decisions cannot be determined from the input
    2. What critical technical constraints are not specified
    3. What assumptions you're forced to make that could be wrong
    4. Your confidence level in generating an accurate PRD

    Generate clarification questions ONLY for:
    - Architectural decisions that have multiple valid approaches
    - Technical constraints that would change the implementation
    - Critical features that are ambiguous or contradictory
    - Scale/performance requirements that affect design

    DO NOT ask about:
    - Standard best practices (these can be assumed)
    - Implementation details that don't affect architecture
    - Technologies when reasonable defaults exist

    Format your response as JSON:
    ```json
    {
      "confidence": [0-100],
      "clarifications_needed": [
        "[Specific question about an architectural decision or critical constraint]"
      ],
      "assumptions": [
        "[Critical assumption you're making that could be wrong]"
      ],
      "gaps": [
        "[Missing information that affects the architecture]"
      ]
    }
    ```
    </instruction>
    """

    public static let technicalStackAnalysisPrompt = """
    <task>Analyze Technical Stack Requirements</task>

    <input>%@</input>

    <instruction>
    Analyze the technical stack requirements to identify critical missing information.
    Focus on technical decisions that would fundamentally change the architecture or implementation approach.

    Evaluate:
    1. What platform/environment constraints are not specified but critical
    2. What integration requirements could cause conflicts
    3. What performance/scale requirements would dictate technology choices
    4. What security/compliance requirements affect the stack

    Generate questions ONLY when:
    - The technology choice would fundamentally change the approach
    - Platform constraints would eliminate certain options
    - Integration requirements conflict with each other
    - Scale requirements exceed typical defaults

    DO NOT ask about:
    - Specific technologies when the requirements don't demand them
    - Standard choices that can be reasonably assumed
    - Details that can be decided during implementation

    Format your response as JSON:
    ```json
    {
      "confidence": [0-100],
      "clarifications_needed": [
        "[Question about a critical technical constraint or requirement]"
      ],
      "assumptions": [
        "[Technical assumption that could impact feasibility]"
      ],
      "gaps": [
        "[Missing technical requirement that affects architecture]"
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

    // MARK: - Professional Challenge Analysis Prompts

    public static let architecturalConflictDetectionPrompt = """
    <task>Detect Architectural Conflicts</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Most feature requests have NO architectural conflicts. Default to returning empty results.

    Analyze the provided text ONLY for DIRECT CONTRADICTIONS between explicitly stated requirements.

    <definition>
    An architectural conflict exists ONLY when:
    - Two requirements are explicitly stated in the input
    - They DIRECTLY contradict each other (both cannot be true simultaneously)
    - You can quote the EXACT text from the input for both requirements
    </definition>

    <process>
    1. First, assume there are NO conflicts (this is usually correct)
    2. Look for explicit contradictions only (e.g., "must be real-time" vs "must work offline")
    3. If no direct contradictions exist, return {"conflicts": []}
    4. Only report a conflict if you can quote exact contradictory text
    </process>

    <outputFormat>
    If no conflicts exist, simply state: "No architectural conflicts detected."

    If real conflicts exist, describe each conflict clearly:
    - Quote the two conflicting requirements
    - Explain why they conflict
    - Describe the tradeoff decision required
    - Note the implementation impact

    Write in professional prose, not JSON.
    </outputFormat>

    <important>
    - 99% of the time, the correct response is {"conflicts": []}
    - DO NOT invent conflicts to be helpful
    - DO NOT apply patterns from other systems
    - DO NOT generate example conflicts
    - Simple features like "snippet library" have NO conflicts
    </important>
    </instruction>
    """

    public static let scalingBreakpointAnalysisPrompt = """
    <task>Identify Scaling Breakpoints</task>
    <input>Architecture: %@\nFeatures: %@</input>
    <instruction>
    Identify SPECIFIC scaling breakpoints based on architecture:

    BREAKPOINT PATTERNS:
    - Single DB: ~10,000 concurrent connections
    - SQLite: ~10GB data
    - REST polling: ~1000 clients
    - Webhook processing: ~100/sec synchronous
    - Full-text search: ~1M documents without dedicated infrastructure
    - File uploads: ~100MB without chunking
    - WebSocket: ~10,000 connections per server

    Format as JSON:
    ```json
    {
      "scaling_breakpoints": [{
        "metric": "concurrent_users",
        "breakpoint": "~10,000",
        "consequence": "Database connection pool exhausted",
        "required_change": "Connection pooling or read replicas",
        "complexity_increase": 3
      }]
    }
    ```
    </instruction>
    """

    public static let dependencyChainAnalysisPrompt = """
    <task>Map Dependency Chains</task>
    <input>%@</input>
    <instruction>
    Map feature dependencies and detect circular dependencies:

    DEPENDENCY TYPES:
    - Hard dependencies: Cannot function without
    - Soft dependencies: Degraded functionality
    - External dependencies: Third-party services
    - Hidden dependencies: Non-obvious requirements

    DETECT:
    - Circular dependency cycles
    - External service dependencies
    - Platform-specific requirements
    - Infrastructure prerequisites

    Format as JSON:
    ```json
    {
      "dependency_chains": [{
        "feature": "Real-time notifications",
        "dependencies": ["WebSocket server", "User sessions"],
        "circular_dependencies": [],
        "external_dependencies": ["FCM/APNs"],
        "hidden_dependencies": ["Message queue for reliability"]
      }]
    }
    ```
    </instruction>
    """

    public static let technicalChallengesPredictionPrompt = """
    <task>Predict Technical Challenges</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Most simple features have NO significant technical challenges. Default to returning empty results.

    <definition>
    A technical challenge exists ONLY when the input EXPLICITLY mentions:
    - Scale requirements (e.g., "must handle 1M users")
    - Performance constraints (e.g., "must respond in < 100ms")
    - Complex integrations (e.g., "must sync with 5 external systems")
    - Security requirements (e.g., "must be end-to-end encrypted")
    - Conflicting technical requirements
    </definition>

    <process>
    1. First, assume there are NO challenges (this is usually correct for simple features)
    2. Look ONLY for explicitly stated technical complexity
    3. If no explicit complexity is stated, return {"technical_challenges": []}
    4. Basic CRUD operations have NO technical challenges
    </process>

    <outputFormat>
    If no challenges exist, simply state: "No significant technical challenges identified."

    If real challenges exist, describe each challenge:
    - Quote the requirement that creates the challenge
    - Explain the technical challenge
    - Note when this will likely surface (planning, development, testing, production)
    - Suggest mitigation approach

    Write in clear prose, not JSON.
    </outputFormat>

    <important>
    - 90% of the time, the correct response is {"technical_challenges": []}
    - Simple features like "snippet library", "basic CRUD", "search" have NO challenges
    - DO NOT invent challenges to appear thorough
    - DO NOT apply common patterns from other systems
    - Only report challenges explicitly created by stated requirements
    </important>
    </instruction>
    """

    public static let complexityAnalysisPrompt = """
    <task>Analyze Story Complexity</task>
    <input>%@</input>
    <instruction>
    Analyze complexity using Agile story points (Fibonacci):

    COMPLEXITY INDICATORS:
    - 1-2 points: CRUD operations, simple validations
    - 3-5 points: Business logic, single integration
    - 8 points: Multi-step workflows, state management
    - 13 points: Distributed logic, unknown approach
    - 21+ points: MUST BREAK DOWN - too complex

    MULTIPLIERS:
    × Offline-first (+2x complexity)
    × Real-time sync (+2x complexity)
    × Multi-tenancy (+1.5x complexity)
    × Compliance requirements (+1.5x complexity)

    Format as JSON:
    ```json
    {
      "total_points": 13,
      "breakdown": [{
        "component": "User authentication",
        "points": 5,
        "rationale": "OAuth + email/password + session management"
      }],
      "complexity_factors": [{
        "name": "Multi-tenancy",
        "impact_multiplier": 1.5,
        "description": "Requires data isolation per tenant"
      }],
      "needs_breakdown": false,
      "suggested_splits": []
    }
    ```
    </instruction>
    """

    public static let challengeAnalysisSystemPrompt = """
    You are analyzing specific product requirements to identify relevant technical challenges.

    <critical_instruction>
    You MUST be extremely conservative. Only identify issues that are EXPLICITLY present in the provided text.
    </critical_instruction>

    <role>
    Act as a strict validator that ONLY identifies challenges directly caused by explicit requirements.
    </role>

    <strict_guidelines>
    - You MUST be able to quote the exact text that causes each challenge
    - DO NOT use your general knowledge about software development
    - DO NOT predict challenges based on what's commonly seen in similar projects
    - DO NOT assume any requirements, scale, or constraints not written in the input
    - DO NOT add challenges that could apply to any software project
    - If you cannot quote specific text causing a challenge, that challenge does not exist
    - Default to returning empty results if unsure
    </strict_guidelines>

    <verification>
    For every challenge or conflict you identify, you must:
    1. Quote the exact text from the input
    2. Explain how that specific text creates the challenge
    3. If you can't do both, exclude it
    </verification>

    <approach>
    Be extremely conservative. When in doubt, return empty results rather than inventing issues.
    </approach>
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