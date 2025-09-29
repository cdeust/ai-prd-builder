import Foundation

// MARK: - Professional Analysis Types for CommonModels

/// Simplified professional analysis result for use in PRDocument
public struct ProfessionalAnalysisResult: Equatable {
    public let hasCriticalIssues: Bool
    public let executiveSummary: String
    public let conflictCount: Int
    public let challengeCount: Int
    public let complexityScore: Int?
    public let blockingIssues: [String]

    public init(
        hasCriticalIssues: Bool = false,
        executiveSummary: String = "",
        conflictCount: Int = 0,
        challengeCount: Int = 0,
        complexityScore: Int? = nil,
        blockingIssues: [String] = []
    ) {
        self.hasCriticalIssues = hasCriticalIssues
        self.executiveSummary = executiveSummary
        self.conflictCount = conflictCount
        self.challengeCount = challengeCount
        self.complexityScore = complexityScore
        self.blockingIssues = blockingIssues
    }

    /// Create from detailed analysis (for use by PRDGenerator module)
    public static func fromDetailedAnalysis(
        conflicts: [Any],
        challenges: [Any],
        complexityScore: Int?,
        criticalIssues: [String]
    ) -> ProfessionalAnalysisResult {
        let hasCritical = !criticalIssues.isEmpty || (complexityScore ?? 0) > 21

        var summary = "## Professional Analysis Summary\n\n"

        if hasCritical {
            summary += "⚠️ **Critical Issues Detected**\n\n"
            criticalIssues.forEach { issue in
                summary += "- \(issue)\n"
            }
            summary += "\n"
        }

        if let complexity = complexityScore {
            summary += "**Complexity**: \(complexity) points "
            summary += complexity > 13 ? "(Needs breakdown)\n" : "(Manageable)\n"
        }

        summary += "**Conflicts**: \(conflicts.count) detected\n"
        summary += "**Challenges**: \(challenges.count) predicted\n"

        return ProfessionalAnalysisResult(
            hasCriticalIssues: hasCritical,
            executiveSummary: summary,
            conflictCount: conflicts.count,
            challengeCount: challenges.count,
            complexityScore: complexityScore,
            blockingIssues: criticalIssues
        )
    }
}