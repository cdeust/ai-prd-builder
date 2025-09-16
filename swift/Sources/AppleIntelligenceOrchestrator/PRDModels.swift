import Foundation

// MARK: - PRD Data Models

/// Represents a prioritized feature in the PRD
public struct PrioritizedFeature {
    public let name: String
    public let priority: Float
    public let confidence: Float

    public init(name: String, priority: Float, confidence: Float) {
        self.name = name
        self.priority = priority
        self.confidence = confidence
    }
}

/// Output format options for PRD generation
public enum PRDOutputFormat {
    case json
    case yaml
}