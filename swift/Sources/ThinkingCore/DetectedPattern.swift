import Foundation

/// A pattern detected in thinking or code
public struct DetectedPattern {
    public let name: String
    public let description: String
    public let isAntiPattern: Bool
    public let occurrences: Int
    public let recommendation: String
    public let examples: [String]

    public init(
        name: String,
        description: String,
        isAntiPattern: Bool,
        occurrences: Int,
        recommendation: String,
        examples: [String]
    ) {
        self.name = name
        self.description = description
        self.isAntiPattern = isAntiPattern
        self.occurrences = occurrences
        self.recommendation = recommendation
        self.examples = examples
    }
}