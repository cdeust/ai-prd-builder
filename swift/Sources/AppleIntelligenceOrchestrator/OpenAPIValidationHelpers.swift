import Foundation

/// Helper methods for OpenAPI validation operations
public class OpenAPIValidationHelpers {

    // MARK: - Issue Analysis

    /// Identify issues that persist across multiple iterations
    public static func identifyPersistentIssues(
        current: [String],
        previous: [String],
        fixed: [String]
    ) -> [String] {
        let currentSet = Set(current)
        let previousSet = Set(previous)
        let fixedSet = Set(fixed)

        // Issues that appear in both current and previous, and haven't been fixed
        let persistent = currentSet
            .intersection(previousSet)
            .subtracting(fixedSet)

        return Array(persistent)
    }

    /// Track newly fixed issues
    public static func trackNewlyFixed(
        previous: Set<String>,
        current: [String]
    ) -> Set<String> {
        return previous.subtracting(current)
    }

    // MARK: - Scoring

    /// Calculate specification quality score
    public static func calculateSpecScore(
        result: ValidationResult
    ) -> Float {
        var score = result.confidence

        if result.isValid {
            score += OpenAPIValidationConstants.Scoring.validityBonus
        }

        // Penalize for issues
        score -= Float(result.issues.count) * OpenAPIValidationConstants.Scoring.issuePenalty

        return max(OpenAPIValidationConstants.Scoring.minScore, score)
    }

    /// Select best specification from multiple candidates
    public static func selectBestSpec(
        specs: [String],
        results: [ValidationResult]
    ) -> Int {
        var bestIndex = 0
        var bestScore: Float = OpenAPIValidationConstants.Scoring.minScore

        for (index, result) in results.enumerated() {
            let score = calculateSpecScore(result: result)

            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }

    // MARK: - Validation Result Processing

    /// Combine structural and AI validation results
    public static func combineValidationResults(
        structural: [String],
        ai: ValidationResult
    ) -> ValidationResult {
        var allIssues = structural
        allIssues.append(contentsOf: ai.issues)

        // Remove duplicates while preserving order
        let uniqueIssues = removeDuplicateIssues(from: allIssues)

        // Calculate combined confidence
        let confidence = calculateCombinedConfidence(
            aiConfidence: ai.confidence,
            structuralIssueCount: structural.count,
            uniqueIssueCount: uniqueIssues.count
        )

        return ValidationResult(
            isValid: uniqueIssues.isEmpty,
            issues: uniqueIssues,
            confidence: confidence
        )
    }

    private static func removeDuplicateIssues(from issues: [String]) -> [String] {
        var seen = Set<String>()
        return issues.filter { seen.insert($0).inserted }
    }

    private static func calculateCombinedConfidence(
        aiConfidence: Float,
        structuralIssueCount: Int,
        uniqueIssueCount: Int
    ) -> Float {
        var confidence = aiConfidence

        if structuralIssueCount > 0 {
            // Reduce confidence if structural issues found
            confidence *= OpenAPIValidationConstants.Scoring.structuralIssueFactor
        }

        if uniqueIssueCount == 0 && confidence < OpenAPIValidationConstants.Scoring.minValidConfidence {
            // Boost confidence if no issues found
            confidence = OpenAPIValidationConstants.Scoring.minValidConfidence
        }

        return min(OpenAPIValidationConstants.Scoring.maxConfidence, confidence)
    }

    // MARK: - Issue Classification

    /// Check if an issue is critical
    public static func isCriticalIssue(_ issue: String) -> Bool {
        return issue.contains("❌")
    }

    /// Check if an issue is a warning
    public static func isWarningIssue(_ issue: String) -> Bool {
        return issue.contains("⚠️")
    }

    /// Check if an issue is informational
    public static func isInfoIssue(_ issue: String) -> Bool {
        return issue.contains("💡")
    }

    /// Categorize issues by severity
    public static func categorizeIssues(_ issues: [String]) -> (
        critical: [String],
        warnings: [String],
        info: [String]
    ) {
        var critical: [String] = []
        var warnings: [String] = []
        var info: [String] = []

        for issue in issues {
            if isCriticalIssue(issue) {
                critical.append(issue)
            } else if isWarningIssue(issue) {
                warnings.append(issue)
            } else if isInfoIssue(issue) {
                info.append(issue)
            } else {
                warnings.append(issue) // Default to warning
            }
        }

        return (critical, warnings, info)
    }
}

// MARK: - Validation Constants Extension

extension OpenAPIValidationConstants {

    public enum Scoring {
        public static let validityBonus: Float = 0.5
        public static let issuePenalty: Float = 0.1
        public static let minScore: Float = -1.0
        public static let maxConfidence: Float = 1.0
        public static let structuralIssueFactor: Float = 0.5
        public static let minValidConfidence: Float = 0.7
    }
}