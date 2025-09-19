import Foundation

// MARK: - AST Node Types

/// Type of AST node in OpenAPI specification
public enum ASTNodeType: String {
    case version
    case info
    case paths
    case components
    case servers
    case operation
    case schema
    case property
    case security
    case responses
    case parameters
    case requestBody
}

/// Represents a node in the OpenAPI AST
public struct ASTNode {
    public let type: ASTNodeType
    public let key: String
    public let value: String?
    public let path: [String]
    public let line: Int
    public var children: [ASTNode] = []

    public init(
        type: ASTNodeType,
        key: String,
        value: String? = nil,
        path: [String] = [],
        line: Int = 0,
        children: [ASTNode] = []
    ) {
        self.type = type
        self.key = key
        self.value = value
        self.path = path
        self.line = line
        self.children = children
    }
}

// MARK: - OpenAPI AST

/// Abstract Syntax Tree for OpenAPI specifications
public class OpenAPIAST {
    private var nodes: [ASTNode] = []
    private var nodesByType: [ASTNodeType: [ASTNode]] = [:]

    public init() {}

    /// Add a node to the AST
    public func addNode(_ node: ASTNode) {
        nodes.append(node)

        if nodesByType[node.type] != nil {
            nodesByType[node.type]?.append(node)
        } else {
            nodesByType[node.type] = [node]
        }
    }

    /// Get all nodes
    public var allNodes: [ASTNode] {
        return nodes
    }

    /// Get nodes by type
    public func nodes(ofType type: ASTNodeType) -> [ASTNode] {
        return nodesByType[type] ?? []
    }

    /// Find node by path
    public func findNode(atPath path: [String]) -> ASTNode? {
        return nodes.first { $0.path == path }
    }

    /// Find nodes by key
    public func findNodes(withKey key: String) -> [ASTNode] {
        return nodes.filter { $0.key == key }
    }
}

// MARK: - Parsing Context

/// Context maintained during parsing
public struct ParsingContext {
    public var path: [String] = []
    public var indentStack: [Int] = [0]
    public var currentSection: String?

    public init() {}
}

// MARK: - Constraint Types

/// Result of constraint solving
public struct ConstraintSolutionResult {
    public let isValid: Bool
    public let fixes: [ConstraintFix]
    public let confidence: Double
    public let violations: [ConstraintViolation]
    public let satisfactionRate: Double

    public init(
        isValid: Bool,
        fixes: [ConstraintFix] = [],
        confidence: Double = 0.0,
        violations: [ConstraintViolation] = [],
        satisfactionRate: Double = 1.0
    ) {
        self.isValid = isValid
        self.fixes = fixes
        self.confidence = confidence
        self.violations = violations
        self.satisfactionRate = satisfactionRate
    }
}

/// Represents a constraint violation
public struct ConstraintViolation {
    public let constraint: String
    public let message: String
    public let severity: ConstraintSeverity

    public init(constraint: String, message: String, severity: ConstraintSeverity = .medium) {
        self.constraint = constraint
        self.message = message
        self.severity = severity
    }
}

/// A fix for a constraint violation
public struct ConstraintFix {
    public let path: String
    public let issue: String
    public let fix: String
    public let severity: ConstraintSeverity

    public init(path: String, issue: String, fix: String, severity: ConstraintSeverity = .medium) {
        self.path = path
        self.issue = issue
        self.fix = fix
        self.severity = severity
    }
}

/// Severity of constraint violation
public enum ConstraintSeverity: String {
    case low
    case minor
    case medium
    case major
    case high
    case critical
}

/// Evaluation of a constraint
public struct ConstraintEvaluation {
    public let constraint: String
    public let isSatisfied: Bool
    public let message: String?
    public let fixes: [ConstraintFix]

    public init(
        constraint: String,
        isSatisfied: Bool,
        message: String? = nil,
        fixes: [ConstraintFix] = []
    ) {
        self.constraint = constraint
        self.isSatisfied = isSatisfied
        self.message = message
        self.fixes = fixes
    }
}

// MARK: - Issue Analysis

/// Analysis result for issues
public struct IssueAnalysis {
    public let totalIssues: Int
    public let resolvedIssues: Int
    public let categories: [String: Int]
    public let confidence: Double
    public let recommendations: [String]
    public let resolutionRate: Double
    public let topCategory: String?
    public let solutions: [(issue: String, solution: String, confidence: Double)]

    public init(
        totalIssues: Int,
        resolvedIssues: Int,
        categories: [String: Int] = [:],
        confidence: Double = 0.0,
        recommendations: [String] = [],
        resolutionRate: Double = 0.0,
        topCategory: String? = nil,
        solutions: [(issue: String, solution: String, confidence: Double)] = []
    ) {
        self.totalIssues = totalIssues
        self.resolvedIssues = resolvedIssues
        self.categories = categories
        self.confidence = confidence
        self.recommendations = recommendations
        self.resolutionRate = resolutionRate
        self.topCategory = topCategory
        self.solutions = solutions
    }
}

// MARK: - Validation Result

/// Result of OpenAPI validation
public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationErrorDetail]
    public let warnings: [ValidationWarning]
    public let fixes: [ValidationFix]
    public let issues: [String]
    public let confidence: Int

    public init(
        isValid: Bool = true,
        errors: [ValidationErrorDetail] = [],
        warnings: [ValidationWarning] = [],
        fixes: [ValidationFix] = [],
        issues: [String] = [],
        confidence: Int = 100
    ) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.fixes = fixes
        self.issues = issues
        self.confidence = confidence
    }
}

/// Validation error detail
public struct ValidationErrorDetail {
    public let path: String
    public let message: String
    public let line: Int?

    public init(path: String, message: String, line: Int? = nil) {
        self.path = path
        self.message = message
        self.line = line
    }
}

/// Validation warning
public struct ValidationWarning {
    public let path: String
    public let message: String
    public let line: Int?

    public init(path: String, message: String, line: Int? = nil) {
        self.path = path
        self.message = message
        self.line = line
    }
}

/// Validation fix
public struct ValidationFix {
    public let path: String
    public let issue: String
    public let solution: String
    public let confidence: Double

    public init(path: String, issue: String, solution: String, confidence: Double = 0.8) {
        self.path = path
        self.issue = issue
        self.solution = solution
        self.confidence = confidence
    }
}