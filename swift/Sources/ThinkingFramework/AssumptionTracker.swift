import Foundation
import AIBridge

/// Tracks and validates assumptions made during reasoning
/// Helps prevent incorrect patterns by making assumptions explicit
public class AssumptionTracker {

    private let orchestrator: Orchestrator
    private var assumptions: [TrackedAssumption] = []
    private var validationHistory: [ValidationResult] = []

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    /// A tracked assumption with validation status
    public struct TrackedAssumption {
        public let id: UUID
        public let statement: String
        public let madeAt: Date
        public let context: String
        public let confidence: Float
        public let category: Category
        public var status: ValidationStatus
        public var evidence: [String]
        public var dependencies: [UUID] // Other assumptions this depends on
        public var impact: ImpactAssessment?

        public enum Category {
            case technical      // About code/system behavior
            case business      // About requirements/domain
            case user         // About user behavior
            case performance  // About system performance
            case security    // About security aspects
            case data       // About data structure/flow
        }

        public enum ValidationStatus {
            case unverified
            case verified
            case invalidated
            case partial
            case needsReview
        }

        public struct ImpactAssessment {
            public let scope: ImpactScope
            public let severity: Severity
            public let affectedComponents: [String]
            public let mitigation: String?

            public enum ImpactScope {
                case local      // Affects single component
                case module     // Affects module/package
                case system     // Affects entire system
                case critical   // Core functionality affected
            }

            public enum Severity {
                case low
                case medium
                case high
                case critical
            }
        }
    }

    /// Record a new assumption
    public func recordAssumption(
        statement: String,
        context: String,
        confidence: Float = 0.5,
        category: TrackedAssumption.Category = .technical,
        dependencies: [UUID] = []
    ) -> TrackedAssumption {

        let assumption = TrackedAssumption(
            id: UUID(),
            statement: statement,
            madeAt: Date(),
            context: context,
            confidence: confidence,
            category: category,
            status: .unverified,
            evidence: [],
            dependencies: dependencies,
            impact: nil
        )

        assumptions.append(assumption)

        print("💭 Assumption recorded: \(statement)")
        print("   Category: \(category), Confidence: \(confidence)")

        return assumption
    }

    /// Batch record assumptions from reasoning
    public func extractAssumptions(from reasoning: String) async throws -> [TrackedAssumption] {
        let prompt = """
        Extract all assumptions from this reasoning:
        \(reasoning)

        For each assumption identify:
        ASSUMPTION: [the assumption being made]
        CATEGORY: [TECHNICAL/BUSINESS/USER/PERFORMANCE/SECURITY/DATA]
        CONFIDENCE: [0.0-1.0]
        DEPENDS_ON: [other assumptions it depends on, if any]
        IF_WRONG: [what happens if this is incorrect]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return parseAssumptions(from: response, context: reasoning)
    }

    /// Validate an assumption against evidence
    public func validateAssumption(
        _ assumption: TrackedAssumption,
        against evidence: String? = nil
    ) async throws -> ValidationResult {

        print("\n🔍 Validating assumption: \(assumption.statement)")

        let validationPrompt = """
        Validate this assumption:
        Assumption: \(assumption.statement)
        Context: \(assumption.context)
        Category: \(assumption.category)
        \(evidence.map { "Evidence: \($0)" } ?? "")

        Determine:
        1. Is this assumption valid? (YES/NO/PARTIAL)
        2. What evidence supports or contradicts it?
        3. What's the confidence level? (0.0-1.0)
        4. What are the implications if wrong?

        Format:
        VALID: [YES/NO/PARTIAL]
        EVIDENCE: [supporting or contradicting evidence]
        CONFIDENCE: [0.0-1.0]
        IMPLICATIONS: [what happens if wrong]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        let result = parseValidationResult(from: response, assumption: assumption)

        // Update assumption status
        if let index = assumptions.firstIndex(where: { $0.id == assumption.id }) {
            assumptions[index].status = result.isValid ? .verified :
                                       result.confidence > 0.3 ? .partial : .invalidated
            assumptions[index].evidence.append(contentsOf: result.evidence)
        }

        validationHistory.append(result)

        print("   Result: \(result.isValid ? "✅ Valid" : "❌ Invalid") (confidence: \(result.confidence))")

        return result
    }

    /// Validate all unverified assumptions
    public func validateAll() async throws -> ValidationReport {
        print("\n🔎 Validating all unverified assumptions...")

        var results: [ValidationResult] = []

        for assumption in assumptions where assumption.status == .unverified {
            let result = try await validateAssumption(assumption)
            results.append(result)
        }

        return ValidationReport(
            timestamp: Date(),
            totalAssumptions: assumptions.count,
            validated: results.count,
            valid: results.filter { $0.isValid }.count,
            invalid: results.filter { !$0.isValid }.count,
            results: results
        )
    }

    /// Assess impact of an assumption being wrong
    public func assessImpact(of assumption: TrackedAssumption) async throws -> TrackedAssumption.ImpactAssessment {
        let prompt = """
        Assess the impact if this assumption is wrong:
        Assumption: \(assumption.statement)
        Context: \(assumption.context)
        Category: \(assumption.category)

        Determine:
        1. SCOPE: [LOCAL/MODULE/SYSTEM/CRITICAL]
        2. SEVERITY: [LOW/MEDIUM/HIGH/CRITICAL]
        3. AFFECTED: [list of affected components]
        4. MITIGATION: [how to handle if wrong]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        let impact = parseImpactAssessment(from: response)

        // Update assumption with impact
        if let index = assumptions.firstIndex(where: { $0.id == assumption.id }) {
            assumptions[index].impact = impact
        }

        return impact
    }

    /// Find contradicting assumptions
    public func findContradictions() async throws -> [Contradiction] {
        print("\n⚠️ Checking for contradicting assumptions...")

        let assumptionsList = assumptions.map { "\($0.id.uuidString): \($0.statement)" }.joined(separator: "\n")

        let prompt = """
        Find any contradictions in these assumptions:
        \(assumptionsList)

        For each contradiction:
        ASSUMPTION1: [ID of first assumption]
        ASSUMPTION2: [ID of second assumption]
        CONFLICT: [why they contradict]
        RESOLUTION: [how to resolve]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return parseContradictions(from: response)
    }

    /// Get dependency chain for an assumption
    public func getDependencyChain(for assumption: TrackedAssumption) -> [TrackedAssumption] {
        var chain: [TrackedAssumption] = [assumption]
        var visited: Set<UUID> = [assumption.id]
        var toVisit = assumption.dependencies

        while !toVisit.isEmpty {
            let nextId = toVisit.removeFirst()

            if !visited.contains(nextId),
               let nextAssumption = assumptions.first(where: { $0.id == nextId }) {
                chain.append(nextAssumption)
                visited.insert(nextId)
                toVisit.append(contentsOf: nextAssumption.dependencies)
            }
        }

        return chain
    }

    /// Generate assumption validation plan
    public func generateValidationPlan() async throws -> ValidationPlan {
        // Prioritize assumptions by impact and dependencies
        let critical = assumptions.filter { $0.impact?.severity == .critical }
        let highImpact = assumptions.filter { $0.impact?.severity == .high }
        let hasD dependents = assumptions.filter { assumption in
            assumptions.contains { $0.dependencies.contains(assumption.id) }
        }

        return ValidationPlan(
            priority1: critical,
            priority2: highImpact,
            priority3: hasDependents,
            priority4: assumptions.filter { assumption in
                !critical.contains { $0.id == assumption.id } &&
                !highImpact.contains { $0.id == assumption.id } &&
                !hasDependents.contains { $0.id == assumption.id }
            }
        )
    }

    // MARK: - Helper Types

    public struct ValidationResult {
        public let assumptionId: UUID
        public let isValid: Bool
        public let confidence: Float
        public let evidence: [String]
        public let implications: String
        public let timestamp: Date
    }

    public struct ValidationReport {
        public let timestamp: Date
        public let totalAssumptions: Int
        public let validated: Int
        public let valid: Int
        public let invalid: Int
        public let results: [ValidationResult]

        public var summary: String {
            """
            Validation Report:
            - Total Assumptions: \(totalAssumptions)
            - Validated: \(validated)
            - Valid: \(valid) (\(String(format: "%.1f%%", Float(valid) / Float(max(validated, 1)) * 100)))
            - Invalid: \(invalid)
            - Unverified: \(totalAssumptions - validated)
            """
        }
    }

    public struct Contradiction {
        public let assumption1: UUID
        public let assumption2: UUID
        public let conflict: String
        public let resolution: String
    }

    public struct ValidationPlan {
        public let priority1: [TrackedAssumption] // Critical assumptions
        public let priority2: [TrackedAssumption] // High impact
        public let priority3: [TrackedAssumption] // Has dependents
        public let priority4: [TrackedAssumption] // Others
    }

    // MARK: - Parsing Methods

    private func parseAssumptions(from response: String, context: String) -> [TrackedAssumption] {
        var parsedAssumptions: [TrackedAssumption] = []
        let sections = response.split(separator: "ASSUMPTION:")

        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")
            var statement = ""
            var category: TrackedAssumption.Category = .technical
            var confidence: Float = 0.5

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: "CATEGORY:") {
                    let catStr = lineStr.replacingOccurrences(of: "CATEGORY:", with: "").trimmingCharacters(in: .whitespaces)
                    category = parseCategory(catStr)
                } else if lineStr.starts(with: "CONFIDENCE:") {
                    let confStr = lineStr.replacingOccurrences(of: "CONFIDENCE:", with: "").trimmingCharacters(in: .whitespaces)
                    confidence = Float(confStr) ?? 0.5
                } else if statement.isEmpty && !lineStr.isEmpty {
                    statement = lineStr
                }
            }

            if !statement.isEmpty {
                let assumption = recordAssumption(
                    statement: statement,
                    context: context,
                    confidence: confidence,
                    category: category
                )
                parsedAssumptions.append(assumption)
            }
        }

        return parsedAssumptions
    }

    private func parseCategory(_ str: String) -> TrackedAssumption.Category {
        let upper = str.uppercased()
        if upper.contains("BUSINESS") { return .business }
        if upper.contains("USER") { return .user }
        if upper.contains("PERFORMANCE") { return .performance }
        if upper.contains("SECURITY") { return .security }
        if upper.contains("DATA") { return .data }
        return .technical
    }

    private func parseValidationResult(from response: String, assumption: TrackedAssumption) -> ValidationResult {
        let lines = response.split(separator: "\n")
        var isValid = false
        var confidence: Float = 0.5
        var evidence: [String] = []
        var implications = ""

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: "VALID:") {
                let validStr = lineStr.replacingOccurrences(of: "VALID:", with: "").trimmingCharacters(in: .whitespaces)
                isValid = validStr.contains("YES")
            } else if lineStr.starts(with: "EVIDENCE:") {
                let evidenceStr = lineStr.replacingOccurrences(of: "EVIDENCE:", with: "").trimmingCharacters(in: .whitespaces)
                evidence = [evidenceStr]
            } else if lineStr.starts(with: "CONFIDENCE:") {
                let confStr = lineStr.replacingOccurrences(of: "CONFIDENCE:", with: "").trimmingCharacters(in: .whitespaces)
                confidence = Float(confStr) ?? 0.5
            } else if lineStr.starts(with: "IMPLICATIONS:") {
                implications = lineStr.replacingOccurrences(of: "IMPLICATIONS:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        return ValidationResult(
            assumptionId: assumption.id,
            isValid: isValid,
            confidence: confidence,
            evidence: evidence,
            implications: implications,
            timestamp: Date()
        )
    }

    private func parseImpactAssessment(from response: String) -> TrackedAssumption.ImpactAssessment {
        let lines = response.split(separator: "\n")
        var scope: TrackedAssumption.ImpactAssessment.ImpactScope = .local
        var severity: TrackedAssumption.ImpactAssessment.Severity = .low
        var affected: [String] = []
        var mitigation: String?

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: "SCOPE:") {
                let scopeStr = lineStr.replacingOccurrences(of: "SCOPE:", with: "").trimmingCharacters(in: .whitespaces)
                scope = scopeStr.contains("CRITICAL") ? .critical :
                       scopeStr.contains("SYSTEM") ? .system :
                       scopeStr.contains("MODULE") ? .module : .local
            } else if lineStr.starts(with: "SEVERITY:") {
                let sevStr = lineStr.replacingOccurrences(of: "SEVERITY:", with: "").trimmingCharacters(in: .whitespaces)
                severity = sevStr.contains("CRITICAL") ? .critical :
                          sevStr.contains("HIGH") ? .high :
                          sevStr.contains("MEDIUM") ? .medium : .low
            } else if lineStr.starts(with: "AFFECTED:") {
                let affStr = lineStr.replacingOccurrences(of: "AFFECTED:", with: "").trimmingCharacters(in: .whitespaces)
                affected = affStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            } else if lineStr.starts(with: "MITIGATION:") {
                mitigation = lineStr.replacingOccurrences(of: "MITIGATION:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        return TrackedAssumption.ImpactAssessment(
            scope: scope,
            severity: severity,
            affectedComponents: affected,
            mitigation: mitigation
        )
    }

    private func parseContradictions(from response: String) -> [Contradiction] {
        // Simplified parsing - would be more robust in production
        []
    }
}