import Foundation

/// PRD Validator - Analyzes and validates PRD output for production readiness
public struct PRDValidator {
    
    public struct ValidationResult {
        public let isProductionReady: Bool
        public let criticalGaps: [String]
        public let clarifyingQuestions: [String]
        public let specificIssues: [String]
        public let refinementSuggestions: [String]
        
        public var needsRefinement: Bool {
            !criticalGaps.isEmpty || !specificIssues.isEmpty
        }
        
        public var summary: String {
            if isProductionReady {
                return "✅ PRD is production-ready"
            }
            
            var parts: [String] = []
            if !criticalGaps.isEmpty {
                parts.append("Critical Gaps: \(criticalGaps.count)")
            }
            if !specificIssues.isEmpty {
                parts.append("Issues: \(specificIssues.count)")
            }
            if !clarifyingQuestions.isEmpty {
                parts.append("Questions: \(clarifyingQuestions.count)")
            }
            
            return "⚠️ PRD needs refinement - \(parts.joined(separator: ", "))"
        }
    }
    
    /// Validate PRD based on scope and content
    public static func validate(
        prd: String,
        feature: String,
        context: String,
        projectContext: ProjectContext?
    ) -> ValidationResult {
        let scope = StructuredPRDGenerator.ProjectScope.detect(from: feature, context: context)
        
        var gaps: [String] = []
        var questions: [String] = []
        var issues: [String] = []
        var suggestions: [String] = []
        
        // Migration-specific validation
        if scope == .migration {
            validateMigrationPRD(prd, &gaps, &questions, &issues, &suggestions, projectContext)
        }
        
        // Platform-specific validation
        validatePlatformSpecifics(prd, context, &gaps, &issues, &suggestions)
        
        // General quality checks
        validateGeneralQuality(prd, &gaps, &issues, &suggestions)
        
        // Acceptance criteria validation
        validateAcceptanceCriteria(prd, &gaps, &suggestions)
        
        // CI/CD validation
        validateCIPipeline(prd, projectContext, &gaps, &issues, &suggestions)
        
        let isReady = gaps.isEmpty && issues.isEmpty
        
        return ValidationResult(
            isProductionReady: isReady,
            criticalGaps: gaps,
            clarifyingQuestions: questions,
            specificIssues: issues,
            refinementSuggestions: suggestions
        )
    }
    
    private static func validateMigrationPRD(
        _ prd: String,
        _ gaps: inout [String],
        _ questions: inout [String],
        _ issues: inout [String],
        _ suggestions: inout [String],
        _ context: ProjectContext?
    ) {
        // Check for Swift migration specifics
        if prd.lowercased().contains("swift") {
            if !prd.contains("strict concurrency") && !prd.contains("Sendable") && !prd.contains("@MainActor") {
                gaps.append("Missing Swift 6 concurrency migration steps (Sendable, strict concurrency, actor isolation)")
                suggestions.append("Add section on handling Sendable conformance and @MainActor annotations")
            }
            
            if !prd.contains("async") && !prd.contains("await") {
                gaps.append("No mention of async/await compatibility checks")
            }
            
            if !prd.contains("deprecat") {
                gaps.append("Missing deprecation handling strategy")
                suggestions.append("Add step to identify and fix deprecated APIs")
            }
        }
        
        // Dependency management
        if !prd.contains("Package.resolved") && !prd.contains("Podfile.lock") {
            questions.append("How are dependencies locked? Using SPM (Package.resolved) or CocoaPods (Podfile.lock)?")
        }
        
        // Version validation
        if !prd.contains("baseline") && !prd.contains("current") {
            questions.append("What's the current baseline? (build time, warning count, coverage %)")
        }
        
        // Rollback triggers
        if prd.contains("Rollback") && !prd.contains("trigger") && !prd.contains("threshold") {
            gaps.append("Rollback missing specific triggers (e.g., 'if warnings > 50' or 'if coverage < 85%')")
            suggestions.append("Define rollback triggers: build failures, coverage drop, perf regression threshold")
        }
    }
    
    private static func validatePlatformSpecifics(
        _ prd: String,
        _ context: String,
        _ gaps: inout [String],
        _ issues: inout [String],
        _ suggestions: inout [String]
    ) {
        let isIOS = context.lowercased().contains("ios") || 
                    context.lowercased().contains("testflight") ||
                    prd.contains("TestFlight")
        
        if isIOS {
            // Check for wrong CI platform
            if prd.contains("ubuntu-latest") || prd.contains("runs-on: ubuntu") {
                issues.append("iOS build using Linux runner - must use macos-14 or macos-latest")
                suggestions.append("Replace 'ubuntu-latest' with 'macos-14' for iOS builds")
            }
            
            // Check for deprecated commands
            if prd.contains("swift package generate-xcodeproj") {
                issues.append("Using deprecated 'generate-xcodeproj' command")
                suggestions.append("Use xcodebuild directly with -workspace or -project flag")
            }
            
            // Check for proper build commands
            if !prd.contains("xcodebuild") && prd.contains("TestFlight") {
                gaps.append("Missing xcodebuild commands for iOS app compilation and archiving")
                suggestions.append("Add xcodebuild clean build test archive commands")
            }
            
            // Check for simulator specification
            if prd.contains("xcodebuild") && !prd.contains("destination") {
                gaps.append("xcodebuild missing -destination flag for simulator/device")
                suggestions.append("Add: -destination 'platform=iOS Simulator,name=iPhone 15'")
            }
        }
    }
    
    private static func validateGeneralQuality(
        _ prd: String,
        _ gaps: inout [String],
        _ issues: inout [String],
        _ suggestions: inout [String]
    ) {
        // Check for placeholder content
        if prd.contains("feature1") || prd.contains("feature2") || 
           prd.contains("TODO") || prd.contains("// Swift 6.2 code") {
            issues.append("Contains placeholder/template code instead of real implementation")
            suggestions.append("Replace placeholder code with actual migration steps")
        }
        
        // Check for vague language
        let vagueTerms = ["improve", "better", "enhance", "optimize", "various"]
        var foundVague = false
        for term in vagueTerms {
            if prd.lowercased().contains(term) && !prd.contains("%") && !prd.contains("ms") {
                foundVague = true
                break
            }
        }
        if foundVague {
            gaps.append("Contains vague terms without specific metrics")
            suggestions.append("Replace vague terms with measurable targets (e.g., 'reduce by 20%', 'under 100ms')")
        }
        
        // Check for non-existent GitHub Actions
        let fakeActions = ["swift-tools-cache@v1", "actions/run-sh@v2", "swift-setup@v1"]
        for action in fakeActions {
            if prd.contains(action) {
                issues.append("Uses non-existent GitHub Action: \(action)")
                suggestions.append("Use official actions: actions/checkout@v4, actions/cache@v4")
            }
        }
    }
    
    private static func validateAcceptanceCriteria(
        _ prd: String,
        _ gaps: inout [String],
        _ suggestions: inout [String]
    ) {
        // Check for numeric thresholds
        let hasNumericGates = prd.contains("= 0") || prd.contains("≤") || prd.contains("≥") || 
                              prd.contains("100%") || prd.contains("85%") || prd.contains("< ") || prd.contains("> ")
        
        if !hasNumericGates {
            gaps.append("Acceptance criteria lack numeric thresholds")
            suggestions.append("Add specific numbers: 'errors = 0', 'warnings ≤ 20', 'coverage ≥ 85%'")
        }
        
        // Check for GWT format
        if prd.contains("Acceptance") && !prd.contains("GIVEN") && !prd.contains("WHEN") && !prd.contains("THEN") {
            gaps.append("Acceptance criteria not in GIVEN-WHEN-THEN format")
            suggestions.append("Format as: GIVEN [context], WHEN [action], THEN [measurable outcome]")
        }
    }
    
    private static func validateCIPipeline(
        _ prd: String,
        _ context: ProjectContext?,
        _ gaps: inout [String],
        _ issues: inout [String],
        _ suggestions: inout [String]
    ) {
        guard let pipeline = context?.ciPipeline else { return }
        
        if pipeline.lowercased().contains("github") {
            // Validate GitHub Actions syntax
            if prd.contains("on:") && !prd.contains("branches:") {
                gaps.append("CI workflow missing branch specification")
                suggestions.append("Add 'branches: [main, develop]' to workflow triggers")
            }
            
            if prd.contains("xcodebuild") && !prd.contains("xcpretty") && !prd.contains("xcbeautify") {
                suggestions.append("Consider adding xcpretty or xcbeautify for readable output")
            }
        }
        
        // Check for test coverage export
        if prd.contains("test") && !prd.contains("coverage") && !prd.contains("xccov") {
            gaps.append("No test coverage measurement/export defined")
            suggestions.append("Add: xcrun xccov view --report to export coverage")
        }
    }
    
    /// Generate questions to ask user for missing information
    public static func generateClarifyingQuestions(
        for result: ValidationResult,
        scope: StructuredPRDGenerator.ProjectScope
    ) -> [String] {
        var questions = result.clarifyingQuestions
        
        // Add scope-specific questions if needed
        if scope == .migration && questions.isEmpty {
            questions.append("What's your current Swift version and target version?")
            questions.append("Current warning count and test coverage percentage?")
            questions.append("Using SPM or CocoaPods for dependencies?")
        }
        
        return questions
    }
    
    /// Create refinement prompt based on validation results
    public static func createRefinementPrompt(
        originalPRD: String,
        validation: ValidationResult
    ) -> String {
        var prompt = "Refine this PRD to fix the following issues:\n\n"
        
        if !validation.criticalGaps.isEmpty {
            prompt += "CRITICAL GAPS TO ADDRESS:\n"
            for gap in validation.criticalGaps {
                prompt += "- \(gap)\n"
            }
            prompt += "\n"
        }
        
        if !validation.specificIssues.isEmpty {
            prompt += "SPECIFIC ISSUES TO FIX:\n"
            for issue in validation.specificIssues {
                prompt += "- \(issue)\n"
            }
            prompt += "\n"
        }
        
        if !validation.refinementSuggestions.isEmpty {
            prompt += "IMPROVEMENTS:\n"
            for suggestion in validation.refinementSuggestions {
                prompt += "- \(suggestion)\n"
            }
            prompt += "\n"
        }
        
        prompt += """
        Original PRD to refine:
        \(originalPRD)
        
        Generate the corrected sections only. Be specific with numbers and real commands.
        """
        
        return prompt
    }
}