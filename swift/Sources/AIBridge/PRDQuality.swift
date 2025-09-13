import Foundation

public struct PRDQuality: Sendable {
    public let score: Double
    public let completeness: Double
    public let specificity: Double
    public let technicalDepth: Double
    public let clarity: Double
    public let actionability: Double
    public let iterations: Int
    
    public init(
        score: Double,
        completeness: Double,
        specificity: Double,
        technicalDepth: Double,
        clarity: Double,
        actionability: Double,
        iterations: Int
    ) {
        self.score = score
        self.completeness = completeness
        self.specificity = specificity
        self.technicalDepth = technicalDepth
        self.clarity = clarity
        self.actionability = actionability
        self.iterations = iterations
    }
    
    public var isProductionReady: Bool {
        return score >= 85.0
    }
    
    public var summary: String {
        """
        PRD Quality Assessment:
        Overall Score: \(String(format: "%.1f", score))% \(isProductionReady ? "✅" : "⚠️")
        - Completeness: \(String(format: "%.1f", completeness))%
        - Specificity: \(String(format: "%.1f", specificity))%
        - Technical Depth: \(String(format: "%.1f", technicalDepth))%
        - Clarity: \(String(format: "%.1f", clarity))%
        - Actionability: \(String(format: "%.1f", actionability))%
        Iterations: \(iterations)
        Status: \(isProductionReady ? "Production Ready" : "Needs Improvement")
        """
    }
}
