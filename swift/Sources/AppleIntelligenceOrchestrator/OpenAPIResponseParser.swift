import Foundation

/// Parses AI responses for OpenAPI validation results
/// Extracts validation status, confidence scores, and issues
public class OpenAPIResponseParser {

    // MARK: - Properties

    private let patterns: ParsingPatterns
    private let keywords: ParsingKeywords

    // MARK: - Initialization

    public init() {
        self.patterns = ParsingPatterns()
        self.keywords = ParsingKeywords()
    }

    // MARK: - Public Interface

    public func parseValidationResponse(_ response: String) -> ValidationResult {
        var isValid = false
        var confidence: Float = OpenAPIPromptConstants.Confidence.minValue
        var issues: [String] = []
        var parsingState = ParsingState()

        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let upperLine = trimmedLine.uppercased()

            // Parse validation status
            if let status = extractValidationStatus(from: upperLine) {
                isValid = status
            }

            // Parse confidence score
            if let newConfidence = extractConfidence(from: line, upperLine: upperLine, state: &parsingState) {
                confidence = newConfidence
            }

            // Parse issues section
            processIssueSection(
                line: trimmedLine,
                upperLine: upperLine,
                state: &parsingState,
                issues: &issues
            )
        }

        // Apply defaults if needed
        if !parsingState.foundConfidence && isValid {
            confidence = ValidationConstants.defaultValidConfidence
        }

        return ValidationResult(
            isValid: isValid,
            issues: issues,
            confidence: confidence
        )
    }

    // MARK: - Validation Status Extraction

    private func extractValidationStatus(from upperLine: String) -> Bool? {
        let validPatterns = keywords.validStatusPatterns
        let invalidPatterns = keywords.invalidStatusPatterns

        for pattern in validPatterns {
            if upperLine.contains(pattern) {
                for indicator in keywords.positiveIndicators {
                    if upperLine.contains(indicator) {
                        return true
                    }
                }
                for indicator in keywords.negativeIndicators {
                    if upperLine.contains(indicator) {
                        return false
                    }
                }
            }
        }

        for pattern in invalidPatterns {
            if upperLine.contains(pattern) {
                return false
            }
        }

        return nil
    }

    // MARK: - Confidence Score Extraction

    private func extractConfidence(
        from line: String,
        upperLine: String,
        state: inout ParsingState
    ) -> Float? {
        guard !state.foundConfidence else { return nil }

        let confidencePatterns = keywords.confidencePatterns

        for pattern in confidencePatterns {
            if upperLine.contains(pattern) {
                if let value = extractNumericValue(from: line) {
                    state.foundConfidence = true
                    return normalizeConfidence(value)
                }
            }
        }

        return nil
    }

    private func extractNumericValue(from line: String) -> Float? {
        for pattern in patterns.numericPatterns {
            if let range = line.range(of: pattern, options: .regularExpression) {
                let match = String(line[range])

                if let numRange = match.range(of: patterns.numericOnly, options: .regularExpression) {
                    let valueStr = String(match[numRange])
                    return Float(valueStr)
                }
            }
        }
        return nil
    }

    private func normalizeConfidence(_ value: Float) -> Float {
        // Convert percentage to 0-1 range if needed
        return value > OpenAPIPromptConstants.Parsing.percentageConversionThreshold ? value / OpenAPIPromptConstants.Parsing.percentageDivisor : value
    }

    // MARK: - Issues Section Processing

    private func processIssueSection(
        line: String,
        upperLine: String,
        state: inout ParsingState,
        issues: inout [String]
    ) {
        // Check if entering issues section
        if isIssuesSectionStart(upperLine) {
            state.inIssuesSection = true
            return
        }

        // Process issues if in section
        if state.inIssuesSection {
            if isNewSection(line, upperLine: upperLine) {
                state.inIssuesSection = false
                return
            }

            if let issue = extractIssue(from: line) {
                issues.append(issue)
            }
        }
    }

    private func isIssuesSectionStart(_ upperLine: String) -> Bool {
        for marker in keywords.issueSectionMarkers {
            if upperLine.contains(marker) {
                return true
            }
        }
        return false
    }

    private func isNewSection(_ line: String, upperLine: String) -> Bool {
        guard line.contains(":") else { return false }

        for marker in keywords.sectionEndMarkers {
            if upperLine.contains(marker) {
                return true
            }
        }
        return false
    }

    private func extractIssue(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var cleanedIssue = removeListPrefixes(from: trimmed)
        cleanedIssue = removeNumberedPrefixes(from: cleanedIssue)

        return isValidIssue(cleanedIssue) ? cleanedIssue : nil
    }

    private func removeListPrefixes(from text: String) -> String {
        let prefixes = patterns.listPrefixes

        for prefix in prefixes {
            if text.hasPrefix(prefix) {
                return String(text.dropFirst(prefix.count))
            }
        }
        return text
    }

    private func removeNumberedPrefixes(from text: String) -> String {
        if let range = text.range(of: patterns.numberedListPattern, options: .regularExpression) {
            return String(text[range.upperBound...])
        }
        return text
    }

    private func isValidIssue(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Check exclusion patterns
        for excluded in keywords.excludedIssueTerms {
            if lowercased.contains(excluded) {
                return false
            }
        }

        // Check minimum length
        return text.count > ValidationConstants.minimumIssueLength
    }

}

// MARK: - Supporting Types

private struct ParsingState {
    var foundConfidence = false
    var inIssuesSection = false
}

// MARK: - Parsing Patterns

private struct ParsingPatterns {
    let numericPatterns = [
        "([0-9]+\\.?[0-9]*)",           // 0.85 or 85
        "([0-9]+)%",                    // 85%
        ":\\s*([0-9]+\\.?[0-9]*)"       // : 0.85
    ]

    let numericOnly = "[0-9]+\\.?[0-9]*"
    let numberedListPattern = "^[0-9]+[\\.\\)\\:]\\s*"

    let listPrefixes = [
        "- ",
        "• ",
        "* ",
        "→ ",
        "> ",
        "+ "
    ]
}

// MARK: - Parsing Keywords

private struct ParsingKeywords {
    let validStatusPatterns = [
        "VALID:",
        "IS VALID:",
        "VALIDATION:",
        "VALIDATED:"
    ]

    let invalidStatusPatterns = [
        "INVALID:",
        "NOT VALID:",
        "VALIDATION FAILED:"
    ]

    let positiveIndicators = [
        "YES",
        "TRUE",
        "PASSED",
        "SUCCESS",
        "VALID"
    ]

    let negativeIndicators = [
        "NO",
        "FALSE",
        "FAILED",
        "INVALID"
    ]

    let confidencePatterns = [
        "CONFIDENCE:",
        "CONFIDENCE SCORE:",
        "SCORE:",
        "CONFIDENCE LEVEL:"
    ]

    let issueSectionMarkers = [
        "ISSUES:",
        "PROBLEMS:",
        "ERRORS:",
        "FAILURES:",
        "WARNINGS:",
        "VIOLATIONS:"
    ]

    let sectionEndMarkers = [
        "VALID",
        "CONFIDENCE",
        "RECOMMENDATION",
        "SUGGESTION",
        "NOTE"
    ]

    let excludedIssueTerms = [
        "none",
        "n/a",
        "not applicable",
        "no issues",
        "all good"
    ]
}

// MARK: - Validation Constants

private enum ValidationConstants {
    static let minimumIssueLength = OpenAPIPromptConstants.Parsing.minimumIssueLength
    static let defaultValidConfidence: Float = OpenAPIPromptConstants.Parsing.defaultValidConfidence
}