import Foundation

/// An assumption made during reasoning
public struct Assumption {
    public let id: UUID
    public let statement: String
    public let confidence: Float
    public let verified: Bool
    public let impact: ImpactLevel
    public let context: String

    public init(
        id: UUID = UUID(),
        statement: String,
        confidence: Float,
        verified: Bool = false,
        impact: ImpactLevel,
        context: String
    ) {
        self.id = id
        self.statement = statement
        self.confidence = confidence
        self.verified = verified
        self.impact = impact
        self.context = context
    }

    public enum ImpactLevel {
        case critical   // Wrong assumption breaks everything
        case high      // Significant impact on outcome
        case medium    // Some impact
        case low       // Minor impact
    }
}