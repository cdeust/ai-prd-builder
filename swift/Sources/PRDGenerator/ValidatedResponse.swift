import Foundation

/// Represents a PRD section response that has been validated and scored
public struct ValidatedResponse {
    /// The generated content for the PRD section
    public let content: String

    /// Confidence score (0-100) in how well the content matches requirements
    public let confidence: Int

    /// List of assumptions made during generation
    public let assumptions: [String]

    /// Areas that need clarification from the user
    public let clarificationsNeeded: [String]

    public init(
        content: String,
        confidence: Int,
        assumptions: [String] = [],
        clarificationsNeeded: [String] = []
    ) {
        self.content = content
        self.confidence = min(100, max(0, confidence)) // Ensure 0-100 range
        self.assumptions = assumptions
        self.clarificationsNeeded = clarificationsNeeded
    }

    /// Returns true if confidence is above the acceptable threshold
    public var isHighConfidence: Bool {
        return confidence >= 80
    }

    /// Returns true if confidence needs improvement
    public var needsImprovement: Bool {
        return confidence < 70
    }
}