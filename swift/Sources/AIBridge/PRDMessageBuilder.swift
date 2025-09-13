import Foundation
import AIProviders

public enum PRDMessageBuilder {
    public static func build(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        projectContext: ProjectContext? = nil,
        includeHistory: Bool = false,
        history: [ChatMessage] = [],
        glossaryPolicy: String = ""
    ) -> [ChatMessage] {
        // Detect scope to adjust the PRD structure
        let scope = StructuredPRDGenerator.ProjectScope.detect(from: feature, context: context)
        
        // Get project context info
        let contextInfo = projectContext?.contextPrompt ?? ""
        
        // Adjust system prompt based on scope
        let scopeGuidance: String
        switch scope {
        case .migration:
            scopeGuidance = """
            This is a MIGRATION project. Focus on:
            - Version compatibility and breaking changes
            - Step-by-step migration process
            - Rollback procedures
            - Test validation
            Do NOT include new features, API design, or database schemas.
            """
        case .bugfix:
            scopeGuidance = """
            This is a BUGFIX. Focus on:
            - Root cause identification
            - Minimal fix approach
            - Regression testing
            - Verification steps
            """
        case .optimization:
            scopeGuidance = """
            This is an OPTIMIZATION project. Focus on:
            - Current performance baselines
            - Specific bottlenecks
            - Improvement targets
            - Measurement methods
            """
        default:
            scopeGuidance = "Structure the PRD appropriately for this \(scope) project."
        }
        
        let systemPrompt = """
        You are a senior technical product manager creating production-ready PRDs.
        
        \(contextInfo)
        
        \(scopeGuidance)
        
        Your PRD must be:
        1. **Actionable**: Use actual tools and commands from the project context
        2. **Specific**: Reference real versions, tools, and timelines
        3. **Executable**: Steps that developers can actually run
        4. **Measurable**: Quantified success criteria
        
        Use relative timelines (Week 1, Sprint 2) not absolute dates.
        Reference the actual CI/CD, test framework, and deployment methods provided.
        """
        
        // Build team context string
        let teamContext = if let pc = projectContext {
            "\(pc.teamSize ?? 0) devs, Sprint: \(pc.sprintDuration ?? "[SPRINT]"), CI: \(pc.ciPipeline ?? "[CI]"), Tests: \(pc.testFramework ?? "[TESTS]"), Deploy: \(pc.deploymentMethod ?? "[DEPLOY]"), Rollback: \(pc.rollbackMechanism ?? "[ROLLBACK]")"
        } else {
            "[TEAM] devs, Sprint: [SPRINT], CI: [CI], Tests: [TESTS], Deploy: [DEPLOY], Rollback: [ROLLBACK]"
        }
        
        let userPrompt = """
        Create a TIGHT, ACTIONABLE PRD:
        
        **Feature:** \(feature)
        **Context:** \(context)
        **Priority:** \(priority)
        **Requirements:**
        \(requirements.map { "- \($0)" }.joined(separator: "\n"))
        
        Format EXACTLY like this:
        
        **Scope:** \(scope) | team-size
        **Team:** \(teamContext)
        
        ## Requirements (with priorities):
        [Assign P0/P1/P2 based on criticality. Add specific thresholds]
        Example: • P0 – Build succeeds (0 errors, warnings ≤ 20)
        
        ## Acceptance (GWT):
        [GIVEN-WHEN-THEN with specific numbers]
        Example: • GIVEN: Code pushed, WHEN: CI runs, THEN: Tests pass 100%
        
        ## Timeline:
        [Use Sprint 1, Sprint 2, not absolute dates]
        
        ## Risks:
        [Specific risks with actionable mitigations]
        
        ## Next 5 Tasks:
        [Concrete, executable tasks]
        
        ## CI Stub & Rollback:
        [Actual configuration and rollback procedure]
        
        Be specific. Use the actual tools provided. Include numbers and thresholds.
        """
        
        var messages = [ChatMessage(role: .system, content: systemPrompt + (glossaryPolicy.isEmpty ? "" : "\n" + glossaryPolicy))]
        
        if includeHistory {
            messages.append(contentsOf: history.suffix(5))
        }
        
        messages.append(ChatMessage(role: .user, content: userPrompt))
        return messages
    }
}
