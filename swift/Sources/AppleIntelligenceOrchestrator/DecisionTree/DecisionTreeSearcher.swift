import Foundation

/// Searches decision trees for solutions
public class DecisionTreeSearcher {

    // MARK: - Properties

    private let patternMatcher: DecisionTreePatternMatcher

    // MARK: - Initialization

    public init() {
        self.patternMatcher = DecisionTreePatternMatcher()
    }

    // MARK: - Public Interface

    public func search(issue: String, in tree: OpenAPIDecisionNode) -> (solution: String, confidence: Double)? {
        let normalizedIssue = normalizeIssue(issue)
        return searchNode(normalizedIssue, node: tree)
    }

    // MARK: - Private Methods

    private func normalizeIssue(_ issue: String) -> String {
        return issue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func searchNode(_ issue: String, node: OpenAPIDecisionNode) -> (solution: String, confidence: Double)? {
        // Check current node
        if nodeMatches(node: node, issue: issue) {
            return (node.solution, node.confidence)
        }

        // Check if category matches
        if categoryMatches(node: node, issue: issue) {
            // Search children for specific match
            if let childMatch = searchChildren(issue: issue, children: node.children) {
                return childMatch
            }
            // Return category solution if no child matches
            if !node.solution.isEmpty {
                return (node.solution, node.confidence)
            }
        }

        // Recursively search all children
        return searchChildren(issue: issue, children: node.children)
    }

    private func nodeMatches(node: OpenAPIDecisionNode, issue: String) -> Bool {
        return !node.issue.isEmpty && issue.contains(node.issue)
    }

    private func categoryMatches(node: OpenAPIDecisionNode, issue: String) -> Bool {
        return patternMatcher.matchesCategory(category: node.category, issue: issue)
    }

    private func searchChildren(issue: String, children: [OpenAPIDecisionNode]) -> (solution: String, confidence: Double)? {
        for child in children {
            if let result = searchNode(issue, node: child) {
                return result
            }
        }
        return nil
    }
}

/// Handles pattern matching for decision tree categories
public class DecisionTreePatternMatcher {

    public func matchesCategory(category: String, issue: String) -> Bool {
        let patterns = getPatterns(for: category)
        return patterns.contains { issue.contains($0) }
    }

    private func getPatterns(for category: String) -> [String] {
        switch category {
        case DecisionTreeConstants.Categories.structural:
            return OpenAPIValidationConstants.DecisionTree.pathIssuePatterns
        case DecisionTreeConstants.Categories.security:
            return OpenAPIValidationConstants.DecisionTree.securityIssuePatterns
        case DecisionTreeConstants.Categories.schema:
            return OpenAPIValidationConstants.DecisionTree.schemaIssuePatterns
        default:
            return []
        }
    }
}