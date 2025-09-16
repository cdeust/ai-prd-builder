import Foundation

/// Decision tree for systematic OpenAPI issue resolution
/// Based on 2025 best practices for automated debugging
public class OpenAPIDecisionTree {

    // MARK: - Properties

    private let root: OpenAPIDecisionNode
    private let searcher: DecisionTreeSearcher
    private let analyzer: DecisionTreeAnalyzer

    // MARK: - Initialization

    public init() {
        self.root = DecisionTreeBuilder.buildTree()
        self.searcher = DecisionTreeSearcher()
        self.analyzer = DecisionTreeAnalyzer()
    }

    // MARK: - Public Interface

    public func findSolution(for issue: String) -> (solution: String, confidence: Double)? {
        return searcher.search(issue: issue, in: root)
    }

    public func getAllSolutions(for issues: [String]) -> [(issue: String, solution: String, confidence: Double)] {
        return issues.compactMap { issue in
            guard let result = findSolution(for: issue) else { return nil }
            return (issue, result.solution, result.confidence)
        }
    }

    public func analyzeIssues(_ issues: [String]) -> IssueAnalysis {
        return analyzer.analyze(issues: issues, using: self)
    }
}

/// Analyzes issues using decision trees
public class DecisionTreeAnalyzer {

    public func analyze(issues: [String], using tree: OpenAPIDecisionTree) -> IssueAnalysis {
        let solutions = findSolutions(for: issues, using: tree)
        let categories = categorizeIssues(issues)
        let averageConfidence = calculateAverageConfidence(from: solutions)

        let resolutionRate = issues.isEmpty ? 0.0 : Double(solutions.count) / Double(issues.count)
        let topCategory = categories.max(by: { $0.value < $1.value })?.key

        return IssueAnalysis(
            totalIssues: issues.count,
            resolvedIssues: solutions.count,
            categories: categories,
            confidence: averageConfidence,
            recommendations: generateRecommendations(from: solutions),
            resolutionRate: resolutionRate,
            topCategory: topCategory,
            solutions: solutions
        )
    }

    private func findSolutions(
        for issues: [String],
        using tree: OpenAPIDecisionTree
    ) -> [(issue: String, solution: String, confidence: Double)] {
        var solutions: [(issue: String, solution: String, confidence: Double)] = []

        for issue in issues {
            if let result = tree.findSolution(for: issue) {
                solutions.append((issue, result.solution, result.confidence))
            }
        }

        return solutions
    }

    private func categorizeIssues(_ issues: [String]) -> [String: Int] {
        var categories: [String: Int] = [:]

        for issue in issues {
            let category = determineCategory(for: issue)
            categories[category, default: 0] += 1
        }

        return categories
    }

    private func determineCategory(for issue: String) -> String {
        let lowercased = issue.lowercased()

        if matchesStructuralPatterns(lowercased) {
            return DecisionTreeConstants.Categories.structural
        }

        if matchesSecurityPatterns(lowercased) {
            return DecisionTreeConstants.Categories.security
        }

        if matchesSchemaPatterns(lowercased) {
            return DecisionTreeConstants.Categories.schema
        }

        return DecisionTreeConstants.Categories.constraint
    }

    private func matchesStructuralPatterns(_ issue: String) -> Bool {
        return OpenAPIValidationConstants.DecisionTree.pathIssuePatterns
            .contains { issue.contains($0) }
    }

    private func matchesSecurityPatterns(_ issue: String) -> Bool {
        return OpenAPIValidationConstants.DecisionTree.securityIssuePatterns
            .contains { issue.contains($0) }
    }

    private func matchesSchemaPatterns(_ issue: String) -> Bool {
        return OpenAPIValidationConstants.DecisionTree.schemaIssuePatterns
            .contains { issue.contains($0) }
    }

    private func calculateAverageConfidence(
        from solutions: [(issue: String, solution: String, confidence: Double)]
    ) -> Double {
        guard !solutions.isEmpty else { return 0 }
        let total = solutions.reduce(0.0) { $0 + $1.confidence }
        return total / Double(solutions.count)
    }

    private func generateRecommendations(
        from solutions: [(issue: String, solution: String, confidence: Double)]
    ) -> [String] {
        var recommendations: [String] = []

        // Add high-confidence solutions as recommendations
        let highConfidenceSolutions = solutions.filter { $0.confidence > 0.8 }
        for solution in highConfidenceSolutions.prefix(5) {
            recommendations.append(solution.solution)
        }

        // Add general recommendations if needed
        if recommendations.isEmpty {
            recommendations.append("Review OpenAPI specification for structural integrity")
            recommendations.append("Ensure all required fields are present")
            recommendations.append("Validate schema definitions")
        }

        return recommendations
    }
}
