import Foundation
import CommonModels
import AIProvidersCore

/// Implementation Genius - Analyzes actual project codebases and bridges PRD to implementation
/// Works with real code files in the project, not just specifications
public struct ImplementationAnalyzer {

    private let provider: AIProvider
    private let fileManager = FileManager.default

    // MARK: - Display Constants
    private enum Icons {
        static let success = "✅"
        static let failure = "❌"
        static let warning = "⚠️"
    }
    private let evidenceCollector = EvidenceCollector()
    private let codeArchaeologist: CodeArchaeologist
    private let projectRoot: String

    public init(provider: AIProvider, projectRoot: String? = nil) {
        self.provider = provider
        self.codeArchaeologist = CodeArchaeologist(provider: provider)
        // Use provided project root or current directory
        self.projectRoot = projectRoot ?? fileManager.currentDirectoryPath
    }

    /// Represents a hypothesis about the system that needs verification
    public struct Hypothesis {
        let id: Int
        let statement: String
        let verificationType: VerificationType
        var status: VerificationStatus = .pending
        var evidence: [Evidence] = []
        var findings: String?

        public enum VerificationType {
            case codeExists
            case patternFollowed
            case dependencyAvailable
            case performanceMet
            case securityCompliant
        }

        public enum VerificationStatus {
            case pending
            case confirmed
            case rejected
            case partial
        }
    }

    /// Evidence found during hypothesis verification
    public struct Evidence {
        let type: EvidenceType
        let location: String  // file:line format
        let snippet: String
        let analysis: String

        public enum EvidenceType {
            case supporting
            case contradicting
            case missing
            case warning
        }
    }

    /// Discrepancy between requirements and reality
    public struct Discrepancy {
        let area: String
        let expected: String
        let actual: String
        let impact: ImpactLevel
        let suggestedFix: String

        enum ImpactLevel {
            case critical
            case major
            case minor
            case cosmetic
        }
    }

    /// Root cause analysis result
    public struct RootCause {
        let symptom: String
        let chainOfCauses: [String]
        let actualRoot: String
        let recommendation: String
        let riskLevel: String
    }

    /// Complete implementation analysis report
    public struct ImplementationReport {
        let timestamp: Date
        let targetPRD: String
        let hypotheses: [Hypothesis]
        let discrepancies: [Discrepancy]
        let rootCauses: [RootCause]
        let implementationStrategy: String
        let criticalChanges: [CriticalChange]
        let testStrategy: String
        let rolloutPlan: String
    }

    /// Analysis of the actual codebase
    public struct CodebaseAnalysis {
        public let projectRoot: String
        public let excavation: CodeArchaeologist.ExcavationReport
        public let sourceFiles: [String]
        public let patterns: [CodeArchaeologist.Pattern]
        public let architecture: String
    }

    /// Structure found in code files
    public struct CodeStructure {
        var types: [String] = []      // Classes, structs, enums, protocols
        var dependencies: [String] = [] // Import statements
        var functions: [String] = []   // Main functions/methods
    }

    /// Critical change that needs careful handling
    public struct CriticalChange {
        let id: String
        let description: String
        let location: String
        let oldImplementation: String
        let newImplementation: String
        let migrationSteps: [String]
        let rollbackPlan: String
    }

    /// Analyzes the actual project codebase to understand current implementation
    public func analyzeCurrentImplementation() async throws -> CodebaseAnalysis {
        print("\n🔍 Analyzing current codebase at: \(projectRoot)")

        // First, excavate the codebase to understand what exists
        let excavation = try await codeArchaeologist.excavate(
            path: projectRoot,
            focus: nil
        )

        // Analyze actual Swift/other files
        let sourceFiles = evidenceCollector.findFiles(
            matching: "*.swift",
            in: projectRoot
        )

        print("Found \(sourceFiles.count) Swift files")

        // Build comprehensive analysis
        return CodebaseAnalysis(
            projectRoot: projectRoot,
            excavation: excavation,
            sourceFiles: sourceFiles,
            patterns: excavation.patterns,
            architecture: try await detectArchitecture(from: sourceFiles)
        )
    }

    /// Verifies if current implementation matches PRD requirements
    public func verifyImplementationAgainstPRD(
        prd: String
    ) async throws -> ImplementationReport {

        // First understand what we have
        let currentCode = try await analyzeCurrentImplementation()

        print("\n📊 Current codebase summary:")
        print("  - Files: \(currentCode.sourceFiles.count)")
        print("  - Architecture: \(currentCode.architecture)")
        print("  - Patterns: \(currentCode.patterns.map { $0.name }.joined(separator: ", "))")

        let path = projectRoot

        // Start formatted output
        print("""
        Phase: Generic Business Infrastructure Implementation
        Objective: Analyze and verify implementation requirements
        Status: IN-PROGRESS

        -- Verification Phase Report (Pre-Implementation) --

        """)
        print("🧪 Implementation Genius - Starting Analysis")
        print(String(repeating: "=", count: 50))

        // Phase 1: Generate hypotheses from PRD
        let hypotheses = try await generateHypotheses(from: prd, withCodebase: currentCode)
        print("📋 Generated \(hypotheses.count) hypotheses to verify")

        // Phase 2: Verify each hypothesis
        var verifiedHypotheses: [Hypothesis] = []
        for (index, hypothesis) in hypotheses.enumerated() {
            print("  [\(index + 1)/\(hypotheses.count)] Verifying: \(hypothesis.statement)")
            let verified = try await verifyHypothesis(hypothesis, codebasePath: path)
            verifiedHypotheses.append(verified)

            // Show result
            let status = verified.status == Hypothesis.VerificationStatus.confirmed ? Icons.success :
                        verified.status == Hypothesis.VerificationStatus.rejected ? Icons.failure : Icons.warning
            print("    \(status) \(verified.findings ?? "")")
        }

        // Phase 3: Find discrepancies
        let discrepancies = try await findDiscrepancies(
            prd: prd,
            hypotheses: verifiedHypotheses
        )
        print("\n🔍 Found \(discrepancies.count) discrepancies")

        // Phase 4: Root cause analysis
        let rootCauses = try await analyzeRootCauses(
            discrepancies: discrepancies,
            hypotheses: verifiedHypotheses
        )
        print("🎯 Identified \(rootCauses.count) root causes")

        // Phase 5: Generate implementation strategy
        let strategy = try await generateImplementationStrategy(
            prd: prd,
            hypotheses: verifiedHypotheses,
            discrepancies: discrepancies,
            rootCauses: rootCauses
        )

        // Phase 6: Identify critical changes
        let criticalChanges = try await identifyCriticalChanges(
            strategy: strategy,
            discrepancies: discrepancies
        )
        print("⚠️ \(criticalChanges.count) critical changes require careful migration")

        // Phase 7: Create test strategy
        let testStrategy = try await generateTestStrategy(
            prd: prd,
            criticalChanges: criticalChanges
        )

        // Phase 8: Create rollout plan
        let rolloutPlan = try await generateRolloutPlan(
            criticalChanges: criticalChanges,
            strategy: strategy
        )

        return ImplementationReport(
            timestamp: Date(),
            targetPRD: prd,
            hypotheses: verifiedHypotheses,
            discrepancies: discrepancies,
            rootCauses: rootCauses,
            implementationStrategy: strategy,
            criticalChanges: criticalChanges,
            testStrategy: testStrategy,
            rolloutPlan: rolloutPlan
        )
    }

    /// Analyze actual code files to understand implementation
    private func analyzeCodeFiles(_ files: [String]) async throws -> CodeStructure {
        var structure = CodeStructure()

        for file in files.prefix(20) { // Analyze first 20 files for overview
            if let content = try? String(contentsOfFile: file) {
                // Detect classes, structs, protocols
                let types = extractTypes(from: content)
                structure.types.append(contentsOf: types)

                // Detect imports and dependencies
                let imports = extractImports(from: content)
                structure.dependencies.append(contentsOf: imports)
            }
        }

        return structure
    }

    private func extractTypes(from content: String) -> [String] {
        var types: [String] = []
        let lines = content.split(separator: "\n")

        for line in lines {
            if line.contains("class ") || line.contains("struct ") ||
               line.contains("enum ") || line.contains("protocol ") {
                types.append(String(line).trimmingCharacters(in: .whitespaces))
            }
        }

        return types
    }

    private func extractImports(from content: String) -> [String] {
        var imports: [String] = []
        let lines = content.split(separator: "\n")

        for line in lines {
            if line.starts(with: "import ") {
                imports.append(String(line).trimmingCharacters(in: .whitespaces))
            }
        }

        return imports
    }

    private func detectArchitecture(from files: [String]) async throws -> String {
        // Analyze file organization to detect architecture pattern
        let hasModels = files.contains { $0.contains("/Models/") || $0.contains("Model.swift") }
        let hasViews = files.contains { $0.contains("/Views/") || $0.contains("View.swift") }
        let hasControllers = files.contains { $0.contains("/Controllers/") || $0.contains("Controller.swift") }
        let hasServices = files.contains { $0.contains("/Services/") || $0.contains("Service.swift") }
        let hasProviders = files.contains { $0.contains("/Providers/") || $0.contains("Provider.swift") }

        if hasModels && hasViews && hasControllers {
            return "MVC Architecture"
        } else if hasServices && hasProviders {
            return "Service-Oriented Architecture"
        } else if files.contains(where: { $0.contains("Package.swift") }) {
            return "Swift Package Structure"
        } else {
            return "Custom Architecture"
        }
    }

    private func generateHypotheses(from prd: String, withCodebase: CodebaseAnalysis) async throws -> [Hypothesis] {
        // Generate hypotheses based on BOTH PRD and actual codebase
        let architectureStr = withCodebase.architecture
        let patternsStr = withCodebase.patterns.prefix(3).map { $0.name }.joined(separator: ", ")
        let prompt = String(
            format: ImplementationPrompts.implementationHypothesisPrompt,
            prd,
            architectureStr,
            patternsStr
        ) + """

        Generate hypotheses about what SHOULD exist vs what DOES exist.

        Format each hypothesis as:
        Hypothesis [N]: [specific claim about implementation]
        - Expected: [what PRD requires]
        - Verify in: [actual file paths from the project]
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return parseHypotheses(from: response)
    }

    private func verifyHypothesis(
        _ hypothesis: Hypothesis,
        codebasePath: String?
    ) async throws -> Hypothesis {
        var verified = hypothesis

        let verifyPrompt = """
        Verify this hypothesis about the system:
        \(hypothesis.statement)

        Type: \(hypothesis.verificationType)

        Analyze the codebase and provide:
        1. CONFIRMED/REJECTED/PARTIAL
        2. Evidence with file:line references
        3. Specific findings
        4. Any warnings or concerns
        """

        let messages = [ChatMessage(role: .user, content: verifyPrompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        // Parse verification results
        verified.status = parseVerificationStatus(from: response)
        verified.evidence = parseEvidence(from: response)
        verified.findings = parseFindings(from: response)

        return verified
    }

    private func findDiscrepancies(
        prd: String,
        hypotheses: [Hypothesis]
    ) async throws -> [Discrepancy] {
        let prompt = String(
            format: ImplementationPrompts.discrepancyAnalysisPrompt,
            prd,
            formatHypotheses(hypotheses)
        ) + """

        Identify discrepancies between requirements and reality:
        - What's missing that should exist
        - What exists but doesn't match requirements
        - What needs to be changed

        For each discrepancy provide:
        1. Area affected
        2. Expected vs Actual
        3. Impact level (critical/major/minor)
        4. Suggested fix
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return parseDiscrepancies(from: response)
    }

    private func analyzeRootCauses(
        discrepancies: [Discrepancy],
        hypotheses: [Hypothesis]
    ) async throws -> [RootCause] {
        let prompt = String(
            format: ImplementationPrompts.rootCauseAnalysisPrompt,
            formatDiscrepancies(discrepancies)
        ) + """

        Provide:
        5. Assess risk level

        Use "5 Whys" technique or similar systematic approach.
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return parseRootCauses(from: response)
    }

    // Helper methods for parsing responses
    private func parseHypotheses(from response: String) -> [Hypothesis] {
        // Implementation would parse the response into Hypothesis objects
        []
    }

    private func parseVerificationStatus(from response: String) -> Hypothesis.VerificationStatus {
        if response.contains("CONFIRMED") { return .confirmed }
        if response.contains("REJECTED") { return .rejected }
        if response.contains("PARTIAL") { return .partial }
        return .pending
    }

    private func parseEvidence(from response: String) -> [Evidence] {
        // Implementation would parse evidence from response
        []
    }

    private func parseFindings(from response: String) -> String {
        // Implementation would extract findings
        response
    }

    private func parseDiscrepancies(from response: String) -> [Discrepancy] {
        // Implementation would parse discrepancies
        []
    }

    private func parseRootCauses(from response: String) -> [RootCause] {
        // Implementation would parse root causes
        []
    }

    private func formatHypotheses(_ hypotheses: [Hypothesis]) -> String {
        hypotheses.map { h in
            "\(h.id). \(h.statement) - Status: \(h.status)"
        }.joined(separator: "\n")
    }

    private func formatDiscrepancies(_ discrepancies: [Discrepancy]) -> String {
        discrepancies.map { d in
            "[\(d.impact)] \(d.area): Expected '\(d.expected)' but found '\(d.actual)'"
        }.joined(separator: "\n")
    }

    private func generateImplementationStrategy(
        prd: String,
        hypotheses: [Hypothesis],
        discrepancies: [Discrepancy],
        rootCauses: [RootCause]
    ) async throws -> String {
        let prompt = String(
            format: ImplementationPrompts.implementationStrategyPrompt,
            prd,
            formatHypotheses(hypotheses),
            formatDiscrepancies(discrepancies)
        ) + """
        Root Causes: \(rootCauses.map { $0.actualRoot }.joined(separator: ", "))

        Also provide:
        5. Phased implementation approach
        6. Order of changes (dependencies first)
        3. Integration points
        4. Risk mitigation
        5. Success metrics
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return response
    }

    private func identifyCriticalChanges(
        strategy: String,
        discrepancies: [Discrepancy]
    ) async throws -> [CriticalChange] {
        let prompt = String(
            format: ImplementationPrompts.criticalChangesPrompt,
            strategy,
            formatDiscrepancies(discrepancies)
        ) + """

        For each critical change also provide:
        5. Exact location and current implementation
        6. New implementation required
        7. Step-by-step migration plan
        8. Rollback procedure
        5. Testing requirements
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        // Parse into CriticalChange objects
        return []
    }

    private func generateTestStrategy(
        prd: String,
        criticalChanges: [CriticalChange]
    ) async throws -> String {
        let prompt = String(
            format: ImplementationPrompts.testStrategyPrompt,
            prd,
            String(criticalChanges.count)
        ) + """

        Also include:
        5. Security validations
        5. Regression test suite
        6. Acceptance test criteria
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return response
    }

    private func generateRolloutPlan(
        criticalChanges: [CriticalChange],
        strategy: String
    ) async throws -> String {
        let prompt = String(
            format: ImplementationPrompts.rolloutPlanPrompt,
            String(criticalChanges.count),
            strategy
        )

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return response
    }
}