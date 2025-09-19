import Foundation
import CommonModels

/// Tracks and validates assumptions made during reasoning
/// Helps prevent incorrect patterns by making assumptions explicit
public class AssumptionTracker {

    private let provider: AIProvider
    private var assumptionsList: [TrackedAssumption] = []
    private var validationHistory: [ValidationResult] = []

    /// Public read-only access to tracked assumptions
    public var assumptions: [TrackedAssumption] {
        return assumptionsList
    }

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Record a new assumption
    public func recordAssumption(
        statement: String,
        context: String,
        confidence: Float = AssumptionTrackerConstants.defaultConfidence,
        category: TrackedAssumption.Category = .technical,
        dependencies: [UUID] = []
    ) -> TrackedAssumption {

        let assumption = TrackedAssumption(
            statement: statement,
            context: context,
            confidence: confidence,
            category: category,
            dependencies: dependencies
        )

        assumptionsList.append(assumption)
        logAssumptionRecorded(assumption)

        return assumption
    }

    /// Batch record assumptions from reasoning
    public func extractAssumptions(from reasoning: String) async throws -> [TrackedAssumption] {
        let prompt = String(format: AssumptionTrackerConstants.extractAssumptionsPromptTemplate, reasoning)
        let response = try await queryProvider(prompt: prompt)

        let parsed = AssumptionParser.parseAssumptions(from: response, context: reasoning)
        assumptionsList.append(contentsOf: parsed)
        return parsed
    }

    /// Validate an assumption against evidence
    public func validateAssumption(
        _ assumption: TrackedAssumption,
        against evidence: String? = nil
    ) async throws -> ValidationResult {

        logValidationStart(assumption)

        let prompt = buildValidationPrompt(for: assumption, evidence: evidence)
        let response = try await queryProvider(prompt: prompt)
        let result = AssumptionParser.parseValidationResult(from: response, assumption: assumption)

        updateAssumptionStatus(assumption: assumption, result: result)
        validationHistory.append(result)
        logValidationResult(result)

        return result
    }

    /// Validate all unverified assumptions
    public func validateAll() async throws -> ValidationReport {
        print("\n\(ThinkingFrameworkDisplay.searchEmoji) \(AssumptionTrackerConstants.validatingAllMessage)")

        var results: [ValidationResult] = []

        for assumption in assumptions where assumption.status == .unverified {
            let result = try await validateAssumption(assumption)
            results.append(result)
        }

        return ValidationReport(
            timestamp: Date(),
            totalAssumptions: assumptionsList.count,
            validated: results.count,
            valid: results.filter { $0.isValid }.count,
            invalid: results.filter { !$0.isValid }.count,
            results: results
        )
    }

    /// Assess impact of an assumption being wrong
    public func assessImpact(of assumption: TrackedAssumption) async throws -> TrackedAssumption.ImpactAssessment {
        let prompt = String(format: AssumptionTrackerConstants.assessImpactPromptTemplate,
                          assumption.statement, assumption.context, "\(assumption.category)")
        let response = try await queryProvider(prompt: prompt)
        let impact = AssumptionParser.parseImpactAssessment(from: response)

        updateAssumptionImpact(assumption: assumption, impact: impact)
        return impact
    }

    /// Find contradicting assumptions
    public func findContradictions() async throws -> [Contradiction] {
        logContradictionCheck()

        let assumptionsList = formatAssumptionsForContradictionCheck()
        let prompt = String(format: AssumptionTrackerConstants.findContradictionsPromptTemplate, assumptionsList)
        let response = try await queryProvider(prompt: prompt)

        return AssumptionParser.parseContradictions(from: response)
    }

    /// Get dependency chain for an assumption
    public func getDependencyChain(for assumption: TrackedAssumption) -> [TrackedAssumption] {
        var chain: [TrackedAssumption] = [assumption]
        var visited: Set<UUID> = [assumption.id]
        var toVisit = assumption.dependencies

        while !toVisit.isEmpty {
            let nextId = toVisit.removeFirst()

            if !visited.contains(nextId),
               let nextAssumption = assumptionsList.first(where: { $0.id == nextId }) {
                chain.append(nextAssumption)
                visited.insert(nextId)
                toVisit.append(contentsOf: nextAssumption.dependencies)
            }
        }

        return chain
    }

    /// Generate assumption validation plan
    public func generateValidationPlan() async throws -> ValidationPlan {
        let critical = filterAssumptionsByImpact(.critical)
        let highImpact = filterAssumptionsByImpact(.high)
        let hasDependents = findAssumptionsWithDependents()
        let others = filterRemainingAssumptions(excluding: critical + highImpact + hasDependents)

        return ValidationPlan(
            priority1: critical,
            priority2: highImpact,
            priority3: hasDependents,
            priority4: others
        )
    }

    // MARK: - Private Helper Methods

    private func queryProvider(prompt: String) async throws -> String {
        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    private func buildValidationPrompt(for assumption: TrackedAssumption, evidence: String?) -> String {
        let evidenceText = evidence.map { "Evidence: \($0)" } ?? ""
        return String(format: AssumptionTrackerConstants.validateAssumptionPromptTemplate,
                     assumption.statement, assumption.context, "\(assumption.category)", evidenceText)
    }

    private func updateAssumptionStatus(assumption: TrackedAssumption, result: ValidationResult) {
        if let index = assumptionsList.firstIndex(where: { $0.id == assumption.id }) {
            assumptionsList[index].status = determineStatus(from: result)
            assumptionsList[index].evidence.append(contentsOf: result.evidence)
        }
    }

    private func determineStatus(from result: ValidationResult) -> TrackedAssumption.ValidationStatus {
        if result.isValid { return .verified }
        return result.confidence > AssumptionTrackerConstants.partialValidationThreshold ? .partial : .invalidated
    }

    private func updateAssumptionImpact(assumption: TrackedAssumption, impact: TrackedAssumption.ImpactAssessment) {
        if let index = assumptionsList.firstIndex(where: { $0.id == assumption.id }) {
            assumptionsList[index].impact = impact
        }
    }

    private func formatAssumptionsForContradictionCheck() -> String {
        return assumptionsList.map { "\($0.id.uuidString): \($0.statement)" }.joined(separator: "\n")
    }

    private func filterAssumptionsByImpact(_ severity: TrackedAssumption.ImpactAssessment.Severity) -> [TrackedAssumption] {
        return assumptionsList.filter { $0.impact?.severity == severity }
    }

    private func findAssumptionsWithDependents() -> [TrackedAssumption] {
        return assumptionsList.filter { assumption in
            assumptionsList.contains { $0.dependencies.contains(assumption.id) }
        }
    }

    private func filterRemainingAssumptions(excluding: [TrackedAssumption]) -> [TrackedAssumption] {
        let excludedIds = Set(excluding.map { $0.id })
        return assumptionsList.filter { !excludedIds.contains($0.id) }
    }

    // MARK: - Logging Methods

    private func logAssumptionRecorded(_ assumption: TrackedAssumption) {
        print("\(ThinkingFrameworkDisplay.assumptionEmoji) \(AssumptionTrackerConstants.assumptionRecordedMessage) \(assumption.statement)")
        print(String(format: AssumptionTrackerConstants.categoryConfidenceFormat, "\(assumption.category)", assumption.confidence))
    }

    private func logValidationStart(_ assumption: TrackedAssumption) {
        print("\n\(ThinkingFrameworkDisplay.validationEmoji) \(AssumptionTrackerConstants.validatingAssumptionMessage) \(assumption.statement)")
    }

    private func logValidationResult(_ result: ValidationResult) {
        let emoji = result.isValid ? ThinkingFrameworkDisplay.validEmoji : ThinkingFrameworkDisplay.invalidEmoji
        let label = result.isValid ? AssumptionTrackerConstants.validLabel : AssumptionTrackerConstants.invalidLabel
        print(String(format: AssumptionTrackerConstants.validationResultFormat, emoji, label, result.confidence))
    }

    private func logContradictionCheck() {
        print("\n\(ThinkingFrameworkDisplay.warningEmoji) \(AssumptionTrackerConstants.checkingContradictionsMessage)")
    }

    // MARK: - Parsing Methods

    // Parsing is now handled by AssumptionParser
}