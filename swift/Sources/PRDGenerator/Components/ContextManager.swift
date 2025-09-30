import Foundation
import CommonModels
import DomainCore

/// Manages context extraction and token budget for section generation
/// Ensures each section stays within provider-specific token limits
public final class ContextManager {
    // Token limits per provider type
    private static let appleIntelligenceTokenLimit = 3500 // Leave buffer for response
    private static let defaultTokenLimit = 8000

    // Estimated tokens per character (rough approximation)
    private static let tokensPerChar: Double = 0.25

    /// Extract minimal context needed for a specific section
    /// This prevents context overflow by providing only relevant information
    public func extractContextForSection(
        sectionName: String,
        fullInput: String,
        enrichedRequirements: EnrichedRequirements?,
        stackContext: StackContext?,
        providerName: String = "default"
    ) -> String {
        let tokenLimit = getTokenLimit(for: providerName)
        let maxChars = Int(Double(tokenLimit) / Self.tokensPerChar)

        var contextParts: [String] = []

        // 1. Always include core request (truncated if needed)
        let coreRequest = truncateIfNeeded(fullInput, maxLength: maxChars / 3)
        contextParts.append("### Core Request\n\(coreRequest)")

        // 2. Include relevant clarifications (not all)
        if let enriched = enrichedRequirements, !enriched.clarifications.isEmpty {
            let relevantClarifications = selectRelevantClarifications(
                for: sectionName,
                from: enriched,
                maxLength: maxChars / 4
            )
            if !relevantClarifications.isEmpty {
                contextParts.append("### Clarifications\n\(relevantClarifications)")
            }
        }

        // 3. Include minimal stack info if relevant for this section
        if let stack = stackContext, isStackRelevantForSection(sectionName) {
            let stackSummary = summarizeStack(stack, maxLength: maxChars / 6)
            contextParts.append("### Tech Stack\n\(stackSummary)")
        }

        // 4. Join and ensure we're under limit
        let combined = contextParts.joined(separator: "\n\n")
        return truncateIfNeeded(combined, maxLength: maxChars)
    }

    /// Get token limit based on provider
    private func getTokenLimit(for providerName: String) -> Int {
        if providerName.lowercased().contains("apple") {
            return Self.appleIntelligenceTokenLimit
        }
        return Self.defaultTokenLimit
    }

    /// Determine if tech stack context is relevant for this section
    private func isStackRelevantForSection(_ sectionName: String) -> Bool {
        let stackRelevantSections = [
            "API Specification",
            "Test Requirements",
            "Performance & Security Constraints",
            "Technical Stack Context",
            "Data Model"
        ]
        return stackRelevantSections.contains { sectionName.contains($0) }
    }

    /// Select only clarifications relevant to the section being generated
    private func selectRelevantClarifications(
        for sectionName: String,
        from enriched: EnrichedRequirements,
        maxLength: Int
    ) -> String {
        // Map sections to relevant clarification keywords
        let sectionKeywords = getSectionKeywords(sectionName)

        var selectedClarifications: [(String, String)] = []
        var totalLength = 0

        for (question, answer) in enriched.clarifications {
            // Check if clarification is relevant to this section
            let isRelevant = sectionKeywords.contains { keyword in
                question.lowercased().contains(keyword.lowercased()) ||
                answer.lowercased().contains(keyword.lowercased())
            }

            if isRelevant {
                let entry = "Q: \(question)\nA: \(answer)"
                if totalLength + entry.count <= maxLength {
                    selectedClarifications.append((question, answer))
                    totalLength += entry.count
                } else {
                    break // Stop if we exceed max length
                }
            }
        }

        if selectedClarifications.isEmpty {
            // If no specific matches, include first few clarifications
            let firstFew = Array(enriched.clarifications.prefix(2))
            return firstFew.map { "Q: \($0.key)\nA: \($0.value)" }.joined(separator: "\n")
        }

        return selectedClarifications.map { "Q: \($0.0)\nA: \($0.1)" }.joined(separator: "\n")
    }

    /// Get keywords relevant to a section
    private func getSectionKeywords(_ sectionName: String) -> [String] {
        switch sectionName {
        case let s where s.contains("Overview"):
            return ["purpose", "goal", "problem", "overview"]
        case let s where s.contains("User Stories"):
            return ["user", "persona", "role", "actor"]
        case let s where s.contains("Feature"):
            return ["feature", "functionality", "capability"]
        case let s where s.contains("Data Model"):
            return ["data", "model", "schema", "entity", "table"]
        case let s where s.contains("API"):
            return ["api", "endpoint", "request", "response", "rest"]
        case let s where s.contains("Test"):
            return ["test", "testing", "validation", "quality"]
        case let s where s.contains("Constraint"):
            return ["performance", "security", "constraint", "limit"]
        case let s where s.contains("Validation"):
            return ["success", "criteria", "acceptance", "validation"]
        default:
            return ["feature", "requirement"]
        }
    }

    /// Summarize stack context to minimal essentials
    private func summarizeStack(_ stack: StackContext, maxLength: Int) -> String {
        var summary = "- Language: \(stack.language)"

        if let db = stack.database {
            summary += "\n- Database: \(db)"
        }

        if let test = stack.testFramework {
            summary += "\n- Testing: \(test)"
        }

        if let deploy = stack.deployment {
            summary += "\n- Deployment: \(deploy)"
        }

        return truncateIfNeeded(summary, maxLength: maxLength)
    }

    /// Truncate text if it exceeds max length
    private func truncateIfNeeded(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }

        let truncated = String(text.prefix(maxLength - 20))
        return truncated + "\n...(truncated)"
    }

    /// Estimate token count for text
    public func estimateTokenCount(_ text: String) -> Int {
        return Int(Double(text.count) * Self.tokensPerChar)
    }

    /// Check if text is within token limit for provider
    public func isWithinLimit(_ text: String, providerName: String) -> Bool {
        let limit = getTokenLimit(for: providerName)
        let estimated = estimateTokenCount(text)
        return estimated <= limit
    }
}