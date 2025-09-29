import Foundation
import CommonModels

// MARK: - Requirements Analysis Models

/// Result of analyzing requirements for completeness
public struct RequirementsAnalysis: Equatable {
    public let confidence: Int
    public let clarificationsNeeded: [String]
    public let assumptions: [String]
    public let gaps: [String]

    public init(
        confidence: Int,
        clarificationsNeeded: [String],
        assumptions: [String],
        gaps: [String]
    ) {
        self.confidence = confidence
        self.clarificationsNeeded = clarificationsNeeded
        self.assumptions = assumptions
        self.gaps = gaps
    }
}

/// Enriched requirements after clarification and analysis
public struct EnrichedRequirements: Equatable {
    public let originalInput: String
    public let enrichedInput: String
    public let clarifications: [String: String]
    public let assumptions: [String]
    public let gaps: [String]
    public let initialConfidence: Int
    public let stackClarifications: [String: String]
    public let professionalAnalysis: CommonModels.ProfessionalAnalysisResult? // NEW field

    public init(
        originalInput: String,
        enrichedInput: String,
        clarifications: [String: String],
        assumptions: [String],
        gaps: [String],
        initialConfidence: Int,
        stackClarifications: [String: String],
        professionalAnalysis: CommonModels.ProfessionalAnalysisResult? = nil // NEW parameter
    ) {
        self.originalInput = originalInput
        self.enrichedInput = enrichedInput
        self.clarifications = clarifications
        self.assumptions = assumptions
        self.gaps = gaps
        self.initialConfidence = initialConfidence
        self.stackClarifications = stackClarifications
        self.professionalAnalysis = professionalAnalysis
    }

    /// Returns the input to use for generation - either enriched or original
    public var inputForGeneration: String {
        return enrichedInput.isEmpty ? originalInput : enrichedInput
    }

    /// Indicates whether clarifications were provided
    public var wasClarified: Bool {
        return !clarifications.isEmpty || !stackClarifications.isEmpty
    }

    /// Check if professional analysis found critical issues
    public var hasCriticalIssues: Bool {
        professionalAnalysis?.hasCriticalIssues ?? false
    }

    /// Get blocking issues from analysis
    public var blockingIssues: [String] {
        professionalAnalysis?.blockingIssues ?? []
    }
}
