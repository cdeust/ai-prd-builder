import Foundation

/// Navigation strategies for traversing the decision tree
public enum NavigationStrategy: CustomStringConvertible {
    case highestProbability
    case lowestRisk
    case balanced
    case aiRecommended
    case interactive

    public var description: String {
        switch self {
        case .highestProbability: return ThinkingFrameworkDisplay.highestProbabilityDesc
        case .lowestRisk: return ThinkingFrameworkDisplay.lowestRiskDesc
        case .balanced: return ThinkingFrameworkDisplay.balancedDesc
        case .aiRecommended: return ThinkingFrameworkDisplay.aiRecommendedDesc
        case .interactive: return ThinkingFrameworkDisplay.interactiveDesc
        }
    }
}