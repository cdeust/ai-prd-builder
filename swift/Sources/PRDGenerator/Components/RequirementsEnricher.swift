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

        // CRITICAL: Start with emphasis on the original request
        var enriched = "## Primary Request\n\n"
        enriched += "The following PRD is for this specific requirement:\n\n"
        enriched += "**\(original)**\n\n"
        enriched += "---\n\n"
        enriched += "All clarifications and assumptions below are supplementary details that support the above primary request.\n\n"

        // Add the original request again to maintain context
        enriched += "## Original Requirements\n\n"
        enriched += original

        // Add requirements clarifications as supplementary information
        if !requirementsClarifications.isEmpty {
            enriched += "\n\n## Supplementary Requirements Clarifications\n"
            enriched += "The following clarifications provide additional context for the primary request:\n"
            for (question, answer) in requirementsClarifications {
                enriched += formatQA(question: question, answer: answer)
            }
        }

        // Add stack clarifications as supplementary information
        if !stackClarifications.isEmpty {
            enriched += "\n\n## Supplementary Technical Stack Clarifications\n"
            enriched += "The following technical details support the primary request implementation:\n"
            for (question, answer) in stackClarifications {
                enriched += formatQA(question: question, answer: answer)
            }
        }

        // Add validated assumptions as supplementary information
        let allAssumptions = assumptions + stackAssumptions
        if !allAssumptions.isEmpty {
            enriched += "\n\n## Supplementary Validated Assumptions\n"
            enriched += "The following assumptions apply to the primary request:\n"
            for assumption in allAssumptions {
                enriched += "- \(assumption)\n"
            }
        }

        // Final reminder about the primary context
        enriched += "\n\n---\n"
        enriched += "**Remember:** This PRD is specifically about: \(original)\n"

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
        // CRITICAL: Start with emphasis on the original request
        var enriched = "## Primary Request\n\n"
        enriched += "The following PRD is for this specific requirement:\n\n"
        enriched += "**\(original)**\n\n"
        enriched += "---\n\n"

        // Add the original request again to maintain context
        enriched += "## Original Requirements\n\n"
        enriched += original

        enriched += "\n\n## Essential Information Provided\n"
        enriched += "The following essential details support the primary request:\n"
        for (question, answer) in essentialResponses {
            enriched += formatQA(question: question, answer: answer)
        }

        // Final reminder about the primary context
        enriched += "\n\n---\n"
        enriched += "**Remember:** This PRD is specifically about: \(original)\n"

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