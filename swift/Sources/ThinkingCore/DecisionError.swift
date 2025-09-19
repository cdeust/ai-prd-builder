import Foundation

/// Errors that can occur in decision tree operations
public enum DecisionError: Error, LocalizedError {
    case noOptions
    case invalidNode
    case maxDepthReached
    case invalidSelection

    public var errorDescription: String? {
        switch self {
        case .noOptions:
            return ThinkingFrameworkDisplay.noOptionsError
        case .invalidNode:
            return ThinkingFrameworkDisplay.invalidNodeError
        case .maxDepthReached:
            return ThinkingFrameworkDisplay.maxDepthReachedError
        case .invalidSelection:
            return ThinkingFrameworkDisplay.invalidSelectionError
        }
    }
}