import Foundation

// MARK: - PRD Generator with Structured Approach

public class StructuredPRDGenerator {
    
    // MARK: - Multi-Stage Generation Pipeline
    
    public enum GenerationStage {
        case research
        case planning 
        case drafting
        case critique
        case refinement
        case validation
    }
    
    // MARK: - Project Scope Detection
    
    public enum ProjectScope {
        case migration      // Compiler updates, version migrations, tech debt
        case feature        // New user-facing functionality  
        case platform       // New product/service, major architecture
        case bugfix         // Defect resolution, patches
        case optimization   // Performance, cost, efficiency improvements
        
        public static func detect(from feature: String, context: String, existingProject: Bool = true) -> ProjectScope {
            let combined = "\(feature) \(context)".lowercased()
            
            // Detection keywords
            if combined.contains("migration") || combined.contains("upgrade") || 
               combined.contains("swift 6") || combined.contains("compiler") ||
               combined.contains("deprecat") {
                return .migration
            }
            
            if combined.contains("bug") || combined.contains("fix") || 
               combined.contains("issue") || combined.contains("error") ||
               combined.contains("crash") {
                return .bugfix
            }
            
            if combined.contains("platform") || combined.contains("saas") ||
               combined.contains("marketplace") || combined.contains("ecosystem") ||
               combined.contains("infrastructure") {
                return .platform
            }
            
            if combined.contains("performance") || combined.contains("optimize") ||
               combined.contains("speed") || combined.contains("latency") ||
               combined.contains("cost reduction") {
                return .optimization
            }
            
            // Default to feature for general cases
            return .feature
        }
        
        var needsBusinessMetrics: Bool {
            switch self {
            case .platform, .feature: return true
            case .migration, .bugfix, .optimization: return false
            }
        }
        
        var needsScalabilityMetrics: Bool {
            switch self {
            case .platform: return true
            case .feature, .optimization: return true  // Conditionally
            case .migration, .bugfix: return false
            }
        }
        
        var needsROIAnalysis: Bool {
            switch self {
            case .platform, .feature: return true
            case .optimization: return true
            case .migration, .bugfix: return false
            }
        }
    }
    
    // MARK: - Context Integration
    
    private static func getExistingProjectContext(
        for scope: ProjectScope,
        projectContext: ProjectContext? = nil
    ) -> String {
        let contextInfo = projectContext?.contextPrompt ?? """
        CONTEXT NOT PROVIDED:
        - Use placeholders: [CI_PIPELINE], [TEST_FRAMEWORK], [SPRINT_DURATION]
        - Use relative timelines: "Week 1", "Sprint 2" (not January 15)
        - Ask for clarification when critical info missing
        - Avoid making up specific dates, tools, or metrics
        """
        
        switch scope {
        case .migration, .bugfix, .optimization:
            return """
            \(contextInfo)
            
            CRITICAL REQUIREMENTS:
            - System currently works - don't break it
            - Provide EXECUTABLE steps (not "develop plan")
            - Quantitative thresholds (fail if warnings > 50, rollback if latency > 300ms)
            - No contradictions (don't say "missing rollback" then describe rollback)
            - No synthetic dates - use relative timing
            """
        case .feature:
            return """
            \(contextInfo)
            
            REQUIREMENTS:
            - Integrate with existing system
            - Follow current patterns
            - Define success quantitatively
            """
        case .platform:
            return """
            \(contextInfo)
            
            New system - more flexibility in design.
            """
        }
    }
    
    // MARK: - Stage 1: Deep Research & Analysis
    
    public static func createResearchPrompt(
        feature: String,
        context: String,
        requirements: [String],
        projectContext: ProjectContext? = nil
    ) -> String {
        let scope = ProjectScope.detect(from: feature, context: context)
        let existingContext = getExistingProjectContext(for: scope, projectContext: projectContext)
        let contextReference = DomainKnowledge.generateContextReference(
            feature: feature,
            context: context,
            requirements: requirements
        )
        
        // Build prompt guidance based on scope
        let scopeGuidance: String
        switch scope {
        case .migration:
            scopeGuidance = """
            IMPORTANT: This is a migration/upgrade of an EXISTING system, not a new implementation.
            
            Focus on:
            - What changes between current version and target version
            - Specific breaking changes and their remediation
            - Concrete rollback procedure (e.g., "git revert to commit X", "restore from backup Y", "feature flag Z")
            - Which existing tests need updates vs what stays the same
            - Actual migration steps (e.g., "run swift-migrate tool", "update Package.swift", "fix deprecation warnings")
            
            Assume the following exists:
            - Current working system/codebase
            - Existing test suite
            - Deployment infrastructure
            - User base and workflows
            
            Do NOT suggest:
            - Building new architecture from scratch
            - Market research for an existing product
            - User personas (they already exist)
            - Revenue projections for a technical migration
            """
            
        case .bugfix:
            scopeGuidance = """
            IMPORTANT: This is fixing a bug in an EXISTING system.
            
            Focus on:
            - Specific root cause (e.g., "null pointer at line X when Y is empty")
            - Exact reproduction steps
            - Minimal code change to fix (don't refactor unrelated code)
            - Specific test to prevent regression
            - Verification steps (e.g., "run test X", "check log Y")
            
            Assume:
            - System is already in production
            - Bug is impacting real users
            - Need minimal, safe fix
            
            Skip entirely:
            - Architecture redesign
            - Feature additions
            - Performance optimizations (unless bug is performance)
            """
            
        case .platform:
            scopeGuidance = """
            Focus on:
            - Architecture patterns and scalability
            - Business model and revenue impact
            - Market positioning and differentiation
            - Full lifecycle from MVP to scale
            
            Include comprehensive analysis of all aspects.
            """
            
        case .optimization:
            scopeGuidance = """
            IMPORTANT: This is optimizing an EXISTING system that already works.
            
            Focus on:
            - Current measured baseline (e.g., "API takes 500ms p95", "Uses 4GB RAM")
            - Specific bottleneck identified (e.g., "N+1 query in getUserData()")
            - Target improvement with rationale (e.g., "Reduce to 100ms to meet SLA")
            - Exact optimization technique (e.g., "Add caching layer", "Batch queries")
            - How to measure improvement (e.g., "Run load test X", "Monitor metric Y")
            
            Assume:
            - System is functional but needs performance improvement
            - Don't change functionality, only performance
            
            Skip:
            - Feature changes
            - UI/UX modifications
            - Market analysis
            """
            
        case .feature:
            scopeGuidance = """
            Focus on:
            - User needs and use cases
            - Technical implementation approach
            - Success metrics and KPIs
            - Integration with existing systems
            
            Balance technical and business perspectives.
            """
        }
        
        return """
        # PRD Research for \(String(describing: scope))
        
        \(existingContext)
        
        Feature: \(feature)
        Context: \(context)
        Requirements: \(requirements.joined(separator: "\n- "))
        
        \(scopeGuidance)
        
        List the key facts for this \(String(describing: scope)) in simple bullet points:
        - Current state
        - Target state  
        - Main challenges
        - Success criteria
        - Timeline estimate
        
        Be specific. Use the actual tools and versions provided.
        Keep it concise and factual.
        """
    }
    
    // MARK: - Stage 2: Strategic Planning
    
    public static func createPlannerPrompt(
        feature: String,
        context: String,
        requirements: [String],
        research: String? = nil,
        projectContext: ProjectContext? = nil
    ) -> String {
        let scope = ProjectScope.detect(from: feature, context: context)
        let existingContext = getExistingProjectContext(for: scope, projectContext: projectContext)
        let researchContext = research != nil ? "\nBased on research:\n\(research!)\n" : ""
        
        let planningGuidance: String
        switch scope {
        case .migration:
            planningGuidance = """
            Create a CONCRETE migration plan for upgrading an EXISTING system.
            
            Required sections:
            - migration_steps: Exact commands/actions (e.g., "1. Update Package.swift line 25", "2. Run swift build", "3. Fix errors in files X,Y,Z")
            - rollback_procedure: Specific steps (e.g., "1. git checkout previous-tag", "2. Restore database backup", "3. Redeploy version X.Y")
            - breaking_changes: List actual breaking changes with fixes (e.g., "API foo() now requires parameter bar - add default value")
            - test_updates: Which tests need changes and why
            - validation: How to verify migration success (e.g., "All tests pass", "App launches", "No deprecation warnings")
            
            Timeline: Be realistic (hours for simple, days for complex)
            Risks: Focus on actual technical risks (e.g., "Third-party library X may not be compatible")
            
            Do NOT include new feature development or architecture changes.
            """
            
        case .bugfix:
            planningGuidance = """
            Create a SPECIFIC fix plan for an EXISTING bug.
            
            Required sections:
            - reproduction_steps: Exact steps to reproduce (e.g., "1. Open app, 2. Click X, 3. Enter empty value, 4. Crash occurs")
            - root_cause: Specific cause (e.g., "Array index out of bounds in ViewController.swift:142")
            - fix_implementation: Exact change (e.g., "Add guard statement before array access")
            - test_case: New test to prevent regression (e.g., "testEmptyInputHandling()")
            - verification: How to confirm fix (e.g., "Follow reproduction steps - should show error message instead of crash")
            
            Timeline: Hours to 1-2 days max
            Skip: Feature additions, refactoring, performance unless directly related to bug
            """
            
        case .platform:
            planningGuidance = """
            Create a comprehensive platform plan including:
            - Multi-phase delivery (MVP → Scale)
            - Architecture decisions with trade-offs
            - Business metrics and success criteria
            - Risk assessment across technical/business/market dimensions
            
            Include detailed timeline, comprehensive metrics, and strategic decisions.
            """
            
        case .optimization:
            planningGuidance = """
            Create a CONCRETE optimization plan for an EXISTING system.
            
            Required sections:
            - current_baseline: Actual measurements (e.g., "API latency: 500ms p95, Memory: 4GB peak")
            - bottleneck_analysis: Specific issues found (e.g., "Profiler shows 60% time in JSON parsing")
            - optimization_approach: Exact technique (e.g., "Replace JSON with Protocol Buffers")
            - implementation_steps: Specific changes (e.g., "1. Add protobuf schema, 2. Update serialization in X.swift")
            - validation_plan: How to verify improvement (e.g., "Run benchmark Y, expect 200ms p95")
            - rollback_plan: How to revert if worse (e.g., "Feature flag to toggle old/new implementation")
            
            Timeline: Days to weeks depending on complexity
            Focus on: Measurable improvements, not theoretical optimizations
            """
            
        case .feature:
            planningGuidance = """
            Create a balanced feature plan with:
            - User-facing functionality and acceptance criteria
            - Technical implementation approach
            - Success metrics
            - Phased delivery if complex
            
            Balance user needs with technical constraints.
            """
        }
        
        return """
        # Planning \(String(describing: scope))
        
        \(existingContext)
        
        Feature: \(feature)
        Requirements: \(requirements.joined(separator: "; "))
        \(researchContext)
        
        \(planningGuidance)
        
        Create a tight action plan:
        
        1. Requirements with priorities (P0/P1/P2)
        2. Acceptance criteria (GIVEN-WHEN-THEN with numbers)
        3. Timeline (Sprint 1, Sprint 2, etc.)
        4. Risks and mitigations
        5. Next 5 concrete tasks
        
        Use the actual CI/CD, test framework, and deployment from context.
        Be specific with thresholds (e.g., "warnings ≤ 20", "coverage ≥ 85%").
        """
    }
    
    // MARK: - Stage 3: Detailed Drafting
    
    public static func createDrafterPrompt(
        plan: String,
        section: String,
        feature: String,
        context: String? = nil,
        projectContext: ProjectContext? = nil
    ) -> String {
        let scope = ProjectScope.detect(from: feature, context: context ?? "")
        let existingContext = getExistingProjectContext(for: scope, projectContext: projectContext)
        let contextInfo = context != nil ? "\nContext: \(context!)\n" : ""
        
        return """
        # Final PRD for \(String(describing: scope))
        
        \(existingContext)
        
        Based on planning:
        \(plan)
        
        Feature: \(feature)
        \(contextInfo)
        
        Generate a TIGHT, ACTIONABLE PRD in this exact format:
        
        **Scope:** \(String(describing: scope)) | team-size
        **Team:** [team details from context]
        
        ## Requirements (with priorities):
        • P0 – [requirement with specific threshold]
        • P1 – [requirement with measurement]
        
        ## Acceptance (GWT):
        • GIVEN: [state], WHEN: [action], THEN: [measurable outcome]
        
        ## Timeline:
        • Sprint 1: [specific deliverables]
        • Sprint 2: [specific deliverables]
        
        ## Risks:
        • [risk] (mitigation: [specific action])
        
        ## Next 5 Tasks:
        1. [Specific executable task]
        2. [Specific executable task]
        
        ## CI Stub & Rollback:
        [Actual CI configuration and rollback steps]
        
        Use the actual tools from context. Include specific numbers and thresholds.
        """
    }
    
    private static func getSectionRequirements(_ section: String, scope: ProjectScope) -> String {
        // Provide guidance, not rigid requirements
        let baseGuidance = "Create a \(section) section appropriate for a \(String(describing: scope)) project."
        
        switch (section, scope) {
        case ("acceptance_criteria", .migration):
            return "\(baseGuidance)\nFocus on: compatibility verification, regression prevention, rollback validation."
        case ("acceptance_criteria", .bugfix):
            return "\(baseGuidance)\nFocus on: issue reproduction, fix verification, regression tests."
        case ("acceptance_criteria", _):
            return "\(baseGuidance)\nUse GIVEN-WHEN-THEN format where appropriate. Include performance criteria."
            
        case ("technical_specification", .migration):
            return "\(baseGuidance)\nEmphasize: version changes, compatibility, migration steps."
        case ("technical_specification", .bugfix):
            return "\(baseGuidance)\nEmphasize: root cause, fix approach, testing."
        case ("technical_specification", .platform):
            return "\(baseGuidance)\nInclude: architecture, APIs, security, scalability."
        case ("technical_specification", _):
            return "\(baseGuidance)\nInclude relevant technical details without over-engineering."
            
        case ("metrics", _):
            return "\(baseGuidance)\nProvide measurable success criteria relevant to \(String(describing: scope))."
            
        case ("implementation", _):
            return "\(baseGuidance)\nOutline practical steps, dependencies, and validation approach."
            
        default:
            return baseGuidance
        }
    }
    
    private static func getSchemaForSection(_ section: String, scope: ProjectScope) -> String {
        // Provide flexible schema guidance based on scope
        let schemaGuidance = """
        Generate valid JSON for \(section) that fits a \(String(describing: scope)) project.
        Use appropriate structure and fields - don't force irrelevant data.
        """
        
        switch (section, scope) {
        case ("acceptance_criteria", _):
            return """
            \(schemaGuidance)
            Structure as an array of test criteria.
            Include relevant fields like: title, steps, expected outcomes, verification method.
            For \(String(describing: scope)): focus on what matters for validation.
            """
            
        case ("technical_specification", _):
            return """
            \(schemaGuidance)
            Structure as an object with relevant technical details.
            For \(String(describing: scope)): include appropriate technical aspects without bloat.
            """
            
        case ("metrics", _):
            return """
            \(schemaGuidance)
            Structure as metrics/criteria relevant to \(String(describing: scope)).
            Include measurable targets with realistic values.
            """
            
        case ("implementation", _):
            return """
            \(schemaGuidance)
            Structure as phases, steps, or approach description.
            Keep it practical and actionable.
            """
        default:
            return "{}"
        }
    }
    
    // MARK: - Stage 4: Critical Analysis
    
    public static func createCritiquePrompt(_ draft: String) -> String {
        return """
        # PRD Critical Review
        
        You are a senior technical reviewer evaluating this PRD for production readiness.
        
        PRD Draft:
        \(draft)
        
        Provide a critical review. For each point, be specific:
        
        ## Completeness (1-10):
        [Score and what's missing]
        
        ## Clarity (1-10):
        [Score and what's vague]
        
        ## Feasibility (1-10):
        [Score and concerns]
        
        ## Key Gaps:
        - [Specific missing items]
        
        ## Improvements Needed:
        - [Current issue] → [Suggested fix]
        
        ## Overall: 
        [Ready for development? Yes/No and why]
        
        Be thorough and critical. Focus on actionability.
        """
    }
    
    // MARK: - Stage 5: Iterative Refinement
    
    public static func createRefinementPrompt(_ draft: String, _ critique: String) -> String {
        return """
        # PRD Refinement
        
        You are refining this PRD based on critical feedback.
        
        Current PRD:
        \(draft)
        
        Critical Feedback:
        \(critique)
        
        Generate an improved PRD that:
        1. Addresses ALL identified gaps
        2. Incorporates ALL suggested improvements
        3. Maintains the tight format
        4. Adds missing technical details with specifics
        5. Includes actual commands/tools from context
        
        Keep the same tight format but fix the issues identified.
        Every item must be specific, measurable, and actionable.
        """
    }
    
    // MARK: - Enhanced Scoring & Validation
    
    public static func scoreOutput(_ output: String, feature: String, context: String, requirements: [String]) -> Double {
        var score = 0.0
        
        // Completeness: check for required sections in tight format
        let requiredSections = ["Scope:", "Team:", "Requirements", "Acceptance", "Timeline", "Risks", "Next 5 Tasks"]
        for section in requiredSections {
            if output.contains(section) {
                score += 10
            }
        }
        
        // Specificity: count numbers and concrete values
        let digitCount = output.filter { $0.isNumber }.count
        score += Double(min(digitCount, 20)) * 2  // Cap at 20 numbers
        
        // Check for actual tools/commands mentioned
        let toolKeywords = ["git", "npm", "swift", "xcode", "test", "CI", "deploy"]
        for tool in toolKeywords {
            if output.lowercased().contains(tool.lowercased()) {
                score += 5
            }
        }
        
        // Context relevance: dynamically extracted keywords
        let contextKeywords = DomainKnowledge.extractKeywords(
            feature: feature,
            context: context,
            requirements: requirements
        )
        for keyword in contextKeywords {
            if output.lowercased().contains(keyword) {
                score += 3
            }
        }
        
        // Penalize vague words
        let vagueWords = ["improve", "better", "enhance", "optimize"]
        for word in vagueWords {
            if output.lowercased().contains(word) {
                score -= 3
            }
        }
        
        // Reward specific metrics
        if output.contains("%") { score += 5 }
        if output.contains("ms") || output.contains("sec") { score += 5 }
        if output.contains("macos-14") || output.contains("macos-13") { score += 10 }
        
        return score
    }
    
    // MARK: - Section-Specific Generation
    
    /// Generate Executive Summary + Requirements section
    public static func createExecutivePrompt(
        feature: String,
        context: String,
        requirements: [String],
        projectContext: ProjectContext?
    ) -> String {
        let scope = ProjectScope.detect(from: feature, context: context)
        let t = projectContext
        let team = "\(t?.teamSize ?? 1) devs, \(t?.sprintDuration ?? "2 weeks")"
        
        // Include actual context info
        var contextInfo = ""
        if let current = t?.currentVersion {
            contextInfo += "Current: \(current). "
        }
        if let target = t?.targetVersion {
            contextInfo += "Target: \(target). "
        }
        
        return """
        \(contextInfo)
        Generate executive section for \(scope):
        Feature: \(feature)
        Team: \(team)
        
        Format:
        **Scope:** \(scope) | \(team)
        ## Requirements (P0/P1/P2):
        P0: \(requirements.first ?? "Core requirement")
        [Add rest with proper priorities]
        
        Be specific. No placeholders.
        """
    }
    
    /// Generate Acceptance Criteria section
    public static func createAcceptancePrompt(
        feature: String,
        requirements: [String],
        projectContext: ProjectContext?
    ) -> String {
        let coverage = projectContext?.performanceBaselines["coverage"] ?? "85%"
        let warnings = projectContext?.performanceBaselines["warnings"] ?? "0"
        
        return """
        Generate acceptance criteria for \(feature):
        Baselines: Coverage \(coverage), Warnings \(warnings)
        
        ## Acceptance (GWT):
        • GIVEN: Code pushed, WHEN: CI runs, THEN: errors = 0, warnings ≤ \(warnings)
        • GIVEN: Tests run, WHEN: Complete, THEN: coverage ≥ \(coverage)
        [Add 2-3 more specific to requirements]
        
        Use exact numbers. No vague terms.
        """
    }
    
    /// Generate Risks + Rollback section  
    public static func createRisksPrompt(
        feature: String,
        projectContext: ProjectContext?
    ) -> String {
        let rollback = projectContext?.rollbackMechanism ?? "git revert"
        
        return """
        Generate risks for: \(feature)
        Rollback: \(rollback)
        
        ## Risks:
        [3 risks with mitigations]
        
        ## Rollback:
        [Steps using \(rollback)]
        """
    }
    
    /// Generate Tasks + CI section
    public static func createTasksPrompt(
        feature: String,
        projectContext: ProjectContext?
    ) -> String {
        let ci = projectContext?.ciPipeline ?? "CI"
        
        return """
        Generate tasks for: \(feature)
        CI: \(ci)
        
        ## Next 5 Tasks:
        [Concrete executable tasks]
        
        ## CI Config:
        [Brief \(ci) setup]
        """
    }
    
    /// Patch vague metrics with concrete values
    public static func patchMetrics(_ input: String) -> String {
        var patched = input
        
        // Replace vague success rates
        patched = patched.replacingOccurrences(
            of: "\"successRate\": \"high\"",
            with: "\"successRate\": \"99.9%\""
        )
        
        // Add missing baselines
        if patched.contains("\"baseline\": null") {
            patched = patched.replacingOccurrences(
                of: "\"baseline\": null",
                with: "\"baseline\": 0"
            )
        }
        
        // Normalize timeline references
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        patched = patched.replacingOccurrences(
            of: "\"next quarter\"",
            with: "\"\(formatter.string(from: today.addingTimeInterval(90*24*3600)))\""
        )
        
        return patched
    }
}
