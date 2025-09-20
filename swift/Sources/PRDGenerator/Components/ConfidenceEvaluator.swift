import Foundation

/// Evaluates and filters analysis results based on confidence thresholds
public final class ConfidenceEvaluator {

    public init() {}

    /// Determines if the confidence level is too low to proceed
    public func isBelowMinimumViability(_ confidence: Int) -> Bool {
        return confidence < PRDConstants.Confidence.minimumViable
    }

    /// Determines if refinement is needed
    public func needsRefinement(_ confidence: Int) -> Bool {
        return confidence < PRDConstants.Confidence.refinementNeeded
    }

    /// Determines if clarifications should be collected
    public func needsClarification(_ confidence: Int) -> Bool {
        return confidence < PRDConstants.Confidence.lowThreshold
    }

    /// Determines if we have high confidence
    public func hasHighConfidence(_ confidence: Int) -> Bool {
        return confidence >= PRDConstants.Confidence.highThreshold
    }

    /// Filters analysis items based on confidence level
    public func filterByConfidence(_ analysis: RequirementsAnalysis) -> RequirementsAnalysis {
        // Don't include assumptions or clarifications if confidence is too low
        if isBelowMinimumViability(analysis.confidence) {
            return RequirementsAnalysis(
                confidence: analysis.confidence,
                clarificationsNeeded: [],  // Don't trust any clarifications at this confidence
                assumptions: [],            // Don't trust any assumptions at this confidence
                gaps: analysis.gaps        // Keep gaps to show what's missing
            )
        }

        // For medium confidence, keep only the most critical items
        if needsRefinement(analysis.confidence) {
            return filterMediumConfidenceItems(analysis)
        }

        // High confidence - keep everything
        return analysis
    }

    /// Filters out weak assumptions and non-critical clarifications
    public func filterWeakAssumptions(_ assumptions: [String]) -> [String] {
        return assumptions.filter { assumption in
            let lowercased = assumption.lowercased()
            // Filter out assumptions that contain weak language
            return !PRDConstants.WeakLanguage.indicators.contains { indicator in
                lowercased.contains(indicator)
            }
        }
    }

    /// Determines if clarifications should be forced based on combined confidence
    public func shouldForceClarifications(
        requirementsConfidence: Int,
        stackConfidence: Int
    ) -> Bool {
        // Force if either is below minimum or both are below refinement threshold
        return isBelowMinimumViability(requirementsConfidence) ||
               isBelowMinimumViability(stackConfidence) ||
               (needsRefinement(requirementsConfidence) && needsRefinement(stackConfidence))
    }

    /// Calculates overall confidence from multiple sources
    public func calculateOverallConfidence(
        requirementsConfidence: Int,
        stackConfidence: Int,
        clarificationsProvided: Bool
    ) -> Int {
        let baseConfidence = (requirementsConfidence + stackConfidence) / 2

        // Boost confidence if clarifications were provided
        if clarificationsProvided {
            return min(100, baseConfidence + PRDConstants.Confidence.confidenceBoostFromClarifications)
        }

        return baseConfidence
    }

    // MARK: - Private Methods

    private func filterMediumConfidenceItems(_ analysis: RequirementsAnalysis) -> RequirementsAnalysis {
        // Take only the most important clarifications
        let topClarifications = Array(analysis.clarificationsNeeded.prefix(PRDConstants.Confidence.maxClarificationsToShow))

        // Filter out weak assumptions
        let strongAssumptions = filterWeakAssumptions(analysis.assumptions)

        return RequirementsAnalysis(
            confidence: analysis.confidence,
            clarificationsNeeded: topClarifications,
            assumptions: strongAssumptions,
            gaps: analysis.gaps
        )
    }
}