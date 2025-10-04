import Foundation

/// Prompts specific to implementation analysis and codebase verification
public enum ImplementationPrompts {

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
}
