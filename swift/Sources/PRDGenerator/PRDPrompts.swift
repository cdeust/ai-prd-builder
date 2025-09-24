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
    Based on the description provided, write a comprehensive product overview.
    Focus ONLY on this section - do not generate other PRD sections.

    Explain:
    - What the product is and its core purpose
    - The problems it solves
    - Who will use it and why
    - The main value proposition

    Adapt the length and detail based on the complexity of the product described.
    </instruction>
    """

    public static let userStoriesPrompt = """
    <task>Generate User Stories</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Extract user stories from the product description.
    Focus ONLY on user stories - do not generate other PRD sections.

    Format as a markdown table with these columns:
    | As a... | I want to... | So that... | Acceptance Criteria |

    Example:
    | As a... | I want to... | So that... | Acceptance Criteria |
    |---------|--------------|------------|---------------------|
    | Product Manager | create snippets | I can reuse text blocks | Snippet saved with all fields |
    | Engineer | search snippets | I can find relevant content | Search returns matching results |

    Create one row for each distinct user action or feature.
    Keep acceptance criteria concise and measurable.
    </instruction>
    """

    public static let dataModelPrompt = """
    <task>Generate Data Model Overview</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Define ONLY the data model using simple tables. DO NOT generate any other PRD content.
    DO NOT include product goals, user stories, or API endpoints.

    For each entity needed, create a table like this:

    **[Entity Name]**
    | Field | Type | Description | Required |
    |-------|------|-------------|----------|
    | id | UUID | Unique identifier | Yes |
    | name | String | Display name | Yes |

    Then add a relationships section:
    **Relationships:**
    - [Entity1] → [Entity2]: [relationship type and description]

    Include only entities directly needed for the features described.
    Keep descriptions brief and technical.
    </instruction>
    """

    public static let featuresPrompt = """
    <task>Generate Features List</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Extract and list all features mentioned or implied in the product description.
    Focus ONLY on the features list - do not generate other PRD sections.

    Organize features logically based on:
    - Their importance to the core functionality
    - How they relate to each other
    - User-facing vs system capabilities

    Provide clear, concise descriptions of what each feature does.
    The structure should adapt to the type and complexity of the product.
    </instruction>
    """

    public static let apiSpecPrompt = """
    <task>Generate API Operations Overview</task>

    <productDescription>%%@</productDescription>

    <instruction>
    List ONLY the API operations needed. DO NOT include any PRD sections like goals, user stories, or features.
    DO NOT number sections or create a full PRD structure.

    Format each operation as:

    **[Operation Name]**
    - Business action: [What it does]
    - Triggered by: [Who/when it's used]
    - Success: [Expected outcome]
    - Failures: [What could go wrong]

    Example:
    **Create Snippet**
    - Business action: Adds new snippet to library
    - Triggered by: User clicking save button
    - Success: Snippet stored with unique ID
    - Failures: Duplicate title, invalid content

    Group related operations together but keep it simple.
    Focus on business logic, not technical implementation.
    </instruction>
    """

    public static let testSpecPrompt = """
    <task>Generate Test Specifications</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Generate ONLY test specifications based on the features described.
    DO NOT include product overview, user stories, or any other PRD sections.

    Structure your response as:

    ## Unit Tests
    - [Feature to test]: [What to verify]
    - [Feature to test]: [What to verify]

    ## Integration Tests
    - [Integration point]: [Expected behavior]
    - [Integration point]: [Expected behavior]

    ## Edge Cases
    - [Edge scenario]: [How it should be handled]
    - [Edge scenario]: [How it should be handled]

    ## Performance Tests
    - [Performance aspect]: [Target metric]
    - [Performance aspect]: [Target metric]

    Include 1-2 code examples ONLY if critical.
    Focus on what to test, not how to implement tests.
    </instruction>
    """

    public static let constraintsPrompt = """
    <task>Define Constraints</task>

    <productDescription>%%@</productDescription>
    <technicalStack>%%@</technicalStack>

    <instruction>
    Based on the product description and technical stack, identify constraints.
    Focus ONLY on constraints - do not generate other PRD sections.

    Consider:
    - Performance: Use metrics appropriate to the stack (API: p95/p99 latency, throughput; UI: fps, responsiveness)
    - Security: High-level needs (authentication required, data privacy, audit logging)
    - Platform compatibility based on target users
    - Scalability needs based on expected usage
    - Data constraints (retention, size limits)

    Keep security requirements high-level - implementation details are for the security team.
    Match performance metrics to the technical context.
    </instruction>
    """

    public static let validationPrompt = """
    <task>Generate Validation Criteria</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Define ONLY validation criteria. DO NOT include product goals, features, or test specs.

    List what needs to be validated:

    **[Feature/Requirement Name]**
    - Success looks like: [Measurable outcome]
    - How to verify: [Test method]
    - Priority: [High/Medium/Low]

    Keep it concise and measurable.
    Group related validations together.
    Use simple bullet points, not complex JSON unless necessary.
    </instruction>
    """

    public static let roadmapPrompt = """
    <task>Generate Technical Roadmap</task>

    <productDescription>%%@</productDescription>

    <instruction>
    Create ONLY a development roadmap. DO NOT include API endpoints, data models, or other sections.

    Format as:

    **Phase 1: [Name] (Timeline)**
    - [Key deliverable]
    - [Key deliverable]
    - Dependencies: [What must be done first]

    **Phase 2: [Name] (Timeline)**
    - [Key deliverable]
    - [Key deliverable]
    - Dependencies: [What from Phase 1]

    Include CI/CD setup where it fits naturally.
    Keep phases realistic and focused.
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