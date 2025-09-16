import Foundation
import AIBridge
import ThinkingFramework

/// Manages assumption tracking and validation for PRD generation
public struct PRDAssumptionManager {

    private let assumptionTracker: AssumptionTracker
    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.assumptionTracker = AssumptionTracker(orchestrator: orchestrator)
    }

    // MARK: - Public Interface

    /// Track initial product assumptions
    public func trackInitialAssumptions(for input: String) {
        _ = assumptionTracker.recordAssumption(
            statement: PRDConstants.ThinkingIntegration.marketAssumption,
            context: input,
            confidence: PRDConstants.ThinkingIntegration.defaultBusinessConfidence,
            category: .business
        )

        _ = assumptionTracker.recordAssumption(
            statement: PRDConstants.ThinkingIntegration.techAssumption,
            context: input,
            confidence: PRDConstants.ThinkingIntegration.defaultTechnicalConfidence,
            category: .technical
        )
    }

    /// Track feature-specific assumptions
    public func trackFeatureAssumption(_ feature: PrioritizedFeature, context: String) -> TrackedAssumption {
        return assumptionTracker.recordAssumption(
            statement: String(format: PRDConstants.ThinkingIntegration.featureValueTemplate, feature.name),
            context: context,
            confidence: feature.confidence,
            category: .business
        )
    }

    /// Track feature feasibility assumption
    public func trackFeatureFeasibility(_ feature: PrioritizedFeature) -> TrackedAssumption {
        let assumption = assumptionTracker.recordAssumption(
            statement: String(format: PRDConstants.ThinkingIntegration.featureFeasibilityTemplate, feature.name),
            context: feature.name,
            confidence: feature.confidence,
            category: .technical
        )

        // Assess impact asynchronously
        Task {
            _ = try? await assumptionTracker.assessImpact(of: assumption)
        }

        return assumption
    }

    /// Extract assumptions from text
    public func extractAssumptions(from text: String) async throws {
        _ = try await assumptionTracker.extractAssumptions(from: text)
    }

    /// Validate all tracked assumptions
    public func validateAll() async throws -> ValidationReport {
        return try await assumptionTracker.validateAll()
    }

    /// Generate YAML section for assumptions
    public func generateAssumptionsYAML() async throws -> String {
        var section = PRDConstants.ThinkingIntegration.assumptionsSection

        // List tracked assumptions
        let assumptions = getTrackedAssumptions()
        section += PRDConstants.ThinkingIntegration.trackedAssumptionsKey

        for assumption in assumptions.prefix(PRDConstants.ThinkingIntegration.maxAssumptionsToDisplay) {
            section += formatAssumptionYAML(assumption)
        }

        // Check for contradictions
        section += try await formatContradictionsYAML()

        // Add total count
        section += String(format: PRDConstants.ThinkingIntegration.totalAssumptionsKey, assumptions.count)

        return section
    }

    // MARK: - Internal Methods

    private func getTrackedAssumptions() -> [TrackedAssumption] {
        return assumptionTracker.assumptions
    }

    private func formatAssumptionYAML(_ assumption: TrackedAssumption) -> String {
        return String(format: PRDConstants.YAMLFormatting.assumptionItemTemplate,
                     assumption.statement,
                     "\(assumption.category)",
                     assumption.confidence,
                     "\(assumption.status)")
    }

    private func formatContradictionsYAML() async throws -> String {
        let contradictions = try await assumptionTracker.findContradictions()

        guard !contradictions.isEmpty else {
            return ""
        }

        var section = PRDConstants.ThinkingIntegration.contradictionsKey

        for contradiction in contradictions.prefix(PRDConstants.ThinkingIntegration.maxContradictionsToDisplay) {
            section += String(format: PRDConstants.YAMLFormatting.contradictionItemTemplate,
                            contradiction.conflict,
                            contradiction.resolution)
        }

        return section
    }
}