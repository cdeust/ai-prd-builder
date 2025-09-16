import Foundation

/// Node in the decision tree for OpenAPI issue resolution
public class OpenAPIDecisionNode {

    // MARK: - Properties

    /// The category of issues this node represents
    public let category: String

    /// The specific issue pattern this node addresses
    public let issue: String

    /// The solution for the issue
    public let solution: String

    /// Confidence score for this solution (0.0 to 1.0)
    public let confidence: Double

    /// Child nodes in the decision tree
    public var children: [OpenAPIDecisionNode] = []

    // MARK: - Initialization

    public init(
        category: String,
        issue: String,
        solution: String,
        confidence: Double,
        children: [OpenAPIDecisionNode] = []
    ) {
        self.category = category
        self.issue = issue
        self.solution = solution
        self.confidence = confidence
        self.children = children
    }

    // MARK: - Helper Methods

    /// Checks if this node is a leaf node (has no children)
    public var isLeaf: Bool {
        return children.isEmpty
    }

    /// Returns all descendant nodes recursively
    public var allDescendants: [OpenAPIDecisionNode] {
        var descendants: [OpenAPIDecisionNode] = []
        for child in children {
            descendants.append(child)
            descendants.append(contentsOf: child.allDescendants)
        }
        return descendants
    }

    /// Finds a node with a specific issue pattern
    public func findNode(withIssue issue: String) -> OpenAPIDecisionNode? {
        if self.issue == issue {
            return self
        }

        for child in children {
            if let found = child.findNode(withIssue: issue) {
                return found
            }
        }

        return nil
    }

    /// Returns the depth of the tree from this node
    public var depth: Int {
        if isLeaf {
            return 0
        }

        let childDepths = children.map { $0.depth }
        return 1 + (childDepths.max() ?? 0)
    }
}

// MARK: - CustomStringConvertible

extension OpenAPIDecisionNode: CustomStringConvertible {
    public var description: String {
        return "OpenAPIDecisionNode(category: \(category), issue: \(issue), confidence: \(confidence), children: \(children.count))"
    }
}