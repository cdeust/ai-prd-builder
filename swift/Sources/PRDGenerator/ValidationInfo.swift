import Foundation

/// Contains validation results from analyzing a generated response
public struct ValidationInfo {
    /// Overall confidence score (0-100)
    public let confidence: Int

    /// List of assumptions that weren't explicit in the input
    public let assumptions: [String]

    /// Identified gaps or missing information
    public let gaps: [String]

    /// Recommendations for improvement
    public let recommendations: [String]

    /// Areas that need clarification or could be misinterpreted
    public let clarificationsNeeded: [String]

    public init(
        confidence: Int,
        assumptions: [String] = [],
        gaps: [String] = [],
        recommendations: [String] = [],
        clarificationsNeeded: [String] = []
    ) {
        self.confidence = min(100, max(0, confidence))
        self.assumptions = assumptions
        self.gaps = gaps
        self.recommendations = recommendations
        self.clarificationsNeeded = clarificationsNeeded
    }

    /// Returns true if validation passed minimum quality threshold
    public var isValid: Bool {
        return confidence >= 60 && gaps.count <= 2
    }

    /// Returns a summary of issues found
    public var issuesSummary: String {
        var issues: [String] = []
        if !assumptions.isEmpty {
            issues.append("\(assumptions.count) assumptions made")
        }
        if !gaps.isEmpty {
            issues.append("\(gaps.count) gaps identified")
        }
        if !recommendations.isEmpty {
            issues.append("\(recommendations.count) improvements suggested")
        }
        return issues.joined(separator: ", ")
    }
}