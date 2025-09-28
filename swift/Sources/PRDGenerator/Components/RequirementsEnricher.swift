import Foundation
import CommonModels

/// Enriches input with clarifications and additional context
public final class RequirementsEnricher {

    public init() {}

    /// Builds enriched input from original input and collected clarifications
    public func enrichInput(
        original: String,
        requirementsClarifications: [String: String],
        stackClarifications: [String: String],
        assumptions: [String],
        stackAssumptions: [String]
    ) -> String {
        DebugLogger.debug("=== ENRICHER DEBUG ===")
        DebugLogger.debug("Original input length: \(original.count)")
        DebugLogger.debug("Original input preview: \(String(original.prefix(200)))")
        DebugLogger.debug("Requirements clarifications: \(requirementsClarifications.count)")
        for (q, a) in requirementsClarifications {
            DebugLogger.debug("  Q: \(q)")
            DebugLogger.debug("  A: \(a)")
        }
        DebugLogger.debug("Stack clarifications: \(stackClarifications.count)")
        for (q, a) in stackClarifications {
            DebugLogger.debug("  Q: \(q)")
            DebugLogger.debug("  A: \(a)")
        }

        var enriched = original

        // Add requirements clarifications
        if !requirementsClarifications.isEmpty {
            enriched += "\n\n## Requirements Clarifications\n"
            for (question, answer) in requirementsClarifications {
                enriched += formatQA(question: question, answer: answer)
            }
        }

        // Add stack clarifications
        if !stackClarifications.isEmpty {
            enriched += "\n\n## Technical Stack Clarifications\n"
            for (question, answer) in stackClarifications {
                enriched += formatQA(question: question, answer: answer)
            }
        }

        // Add validated assumptions
        let allAssumptions = assumptions + stackAssumptions
        if !allAssumptions.isEmpty {
            enriched += "\n\n## Validated Assumptions\n"
            for assumption in allAssumptions {
                enriched += "- \(assumption)\n"
            }
        }

        DebugLogger.debug("Enriched input length: \(enriched.count)")
        DebugLogger.debug("Enriched input preview: \(String(enriched.prefix(500)))")
        DebugLogger.debug("=== END ENRICHER DEBUG ===")

        return enriched
    }

    /// Builds enriched input specifically for essential clarifications
    public func enrichWithEssentials(
        original: String,
        essentialResponses: [String: String]
    ) -> String {
        var enriched = original

        enriched += "\n\n## Essential Information Provided\n"
        for (question, answer) in essentialResponses {
            enriched += formatQA(question: question, answer: answer)
        }

        return enriched
    }

    /// Creates a context summary for the AI to better understand the enriched requirements
    public func createContextSummary(
        clarificationsCount: Int,
        assumptionsCount: Int,
        confidenceImprovement: Int?
    ) -> String {
        var summary = "\n## Context Enhancement Summary\n"

        if clarificationsCount > 0 {
            summary += "- \(clarificationsCount) clarifications provided\n"
        }

        if assumptionsCount > 0 {
            summary += "- \(assumptionsCount) assumptions validated\n"
        }

        if let improvement = confidenceImprovement, improvement > 0 {
            summary += "- Confidence improved by \(improvement)%\n"
        }

        return summary
    }

    /// Merges multiple clarification sets into a single dictionary
    public func mergeClarifications(
        _ clarificationSets: [[String: String]]
    ) -> [String: String] {
        var merged: [String: String] = [:]

        for clarifications in clarificationSets {
            for (key, value) in clarifications {
                merged[key] = value
            }
        }

        return merged
    }

    /// Formats gaps and missing information for inclusion in enriched input
    public func formatGapsAsContext(_ gaps: [String]) -> String {
        guard !gaps.isEmpty else { return "" }

        var formatted = "\n\n## Known Gaps to Address\n"
        formatted += "The following areas need consideration during implementation:\n"

        for gap in gaps {
            formatted += "- \(gap)\n"
        }

        return formatted
    }

    // MARK: - Private Methods

    private func formatQA(question: String, answer: String) -> String {
        return "\n**Q:** \(question)\n**A:** \(answer)\n"
    }
}