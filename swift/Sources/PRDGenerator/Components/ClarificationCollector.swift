import Foundation
import DomainCore

/// Handles collection of clarifications from users
public final class ClarificationCollector {
    private let interactionHandler: UserInteractionHandler

    public init(interactionHandler: UserInteractionHandler) {
        self.interactionHandler = interactionHandler
    }

    /// Collects clarifications for a list of questions
    public func collectClarifications(
        for questions: [String],
        category: String? = nil
    ) async -> [String: String] {
        var responses: [String: String] = [:]

        if let category = category {
            print(category)
        }

        for question in questions {
            print("\n❓ \(question)")
            let response = await interactionHandler.askQuestion("Your answer")
            if !response.isEmpty {
                responses[question] = response
            }
        }

        return responses
    }

    /// Collects essential clarifications when confidence is too low
    public func collectEssentialClarifications() async -> [String: String] {
        interactionHandler.showInfo(
            String(format: PRDConstants.AnalysisMessages.confidenceTooLow, PRDConstants.Confidence.minimumViable)
        )

        print(PRDConstants.AnalysisMessages.essentialInfoRequired)
        for (index, question) in PRDConstants.EssentialQuestions.all.enumerated() {
            print("  \(index + 1). \(question)")
        }

        print(PRDConstants.AnalysisMessages.cannotProceedWithoutInfo)

        var essentialResponses: [String: String] = [:]

        for question in PRDConstants.EssentialQuestions.all {
            essentialResponses[question] = await collectRequiredAnswer(for: question)
        }

        return essentialResponses
    }

    /// Presents clarifications to user and asks if they want to provide answers
    public func presentClarificationsForApproval(
        requirementsClarifications: [String],
        stackClarifications: [String],
        requirementsConfidence: Int,
        stackConfidence: Int
    ) async -> Bool {
        interactionHandler.showInfo(PRDConstants.AnalysisMessages.clarificationIdentified)

        // Show confidence levels
        print(PRDConstants.AnalysisMessages.confidenceLevels)
        print(String(format: PRDConstants.AnalysisMessages.requirementsConfidence, requirementsConfidence))
        print(String(format: PRDConstants.AnalysisMessages.stackConfidence, stackConfidence))

        // Deduplicate for display
        let (deduplicatedRequirements, deduplicatedStack) = deduplicateClarifications(
            requirementsClarifications: requirementsClarifications,
            stackClarifications: stackClarifications
        )

        if !deduplicatedRequirements.isEmpty {
            print(PRDConstants.AnalysisMessages.requirementsClarificationsHeader)
            for (index, clarification) in deduplicatedRequirements.enumerated() {
                print("  \(index + 1). \(clarification)")
            }
        }

        if !deduplicatedStack.isEmpty {
            print(PRDConstants.AnalysisMessages.stackClarificationsHeader)
            for (index, clarification) in deduplicatedStack.enumerated() {
                print("  \(index + 1). \(clarification)")
            }
        }

        return await interactionHandler.askYesNo(
            "\nWould you like to provide clarifications now for a more accurate PRD?"
        )
    }

    /// Deduplicates clarification questions across categories
    private func deduplicateClarifications(
        requirementsClarifications: [String],
        stackClarifications: [String]
    ) -> (requirements: [String], stack: [String]) {
        var deduplicatedRequirements: [String] = []
        var deduplicatedStack: [String] = []

        // Add all requirements clarifications first (they have priority)
        deduplicatedRequirements = requirementsClarifications

        // For stack clarifications, only add if they're not similar to any requirements clarification
        for stackClarification in stackClarifications {
            var isDuplicate = false

            for reqClarification in requirementsClarifications {
                if areClarificationsSimilar(stackClarification, reqClarification) ||
                   areQuestionsAboutSameTopic(stackClarification, reqClarification) {
                    isDuplicate = true
                    break
                }
            }

            if !isDuplicate {
                deduplicatedStack.append(stackClarification)
            }
        }

        return (deduplicatedRequirements, deduplicatedStack)
    }

    /// Checks if two questions are asking about the same topic using word overlap
    private func areQuestionsAboutSameTopic(_ first: String, _ second: String) -> Bool {
        // Extract significant words (longer than 3 characters) from both questions
        let firstWords = extractSignificantWords(from: first)
        let secondWords = extractSignificantWords(from: second)

        // If either set is empty, they're not similar
        guard !firstWords.isEmpty && !secondWords.isEmpty else { return false }

        // Calculate Jaccard similarity (intersection over union)
        let intersection = firstWords.intersection(secondWords)
        let union = firstWords.union(secondWords)

        guard !union.isEmpty else { return false }

        let jaccardSimilarity = Double(intersection.count) / Double(union.count)

        // If more than 60% of the words overlap, consider them about the same topic
        return jaccardSimilarity > 0.6
    }

    /// Extracts significant words from a question
    private func extractSignificantWords(from text: String) -> Set<String> {
        let normalized = text.lowercased()
        let punctuationSet = CharacterSet.punctuationCharacters.union(.symbols)

        // Split by whitespace and punctuation, filter short words
        let words = normalized.components(separatedBy: punctuationSet.union(CharacterSet.whitespacesAndNewlines))
            .filter { $0.count > 3 }  // Only keep words longer than 3 characters
            .filter { !commonWords.contains($0) }  // Filter common words

        return Set(words)
    }

    /// Common English words to ignore when comparing questions
    private let commonWords: Set<String> = [
        "what", "which", "when", "where", "should", "could", "would",
        "will", "with", "have", "that", "this", "from", "been", "being",
        "about", "into", "through", "during", "before", "after", "above",
        "below", "between", "under", "again", "further", "then", "once",
        "here", "there", "when", "where", "why", "how", "all", "both",
        "each", "few", "more", "most", "other", "some", "such", "only",
        "own", "same", "than", "too", "very", "can", "just", "should",
        "used", "using", "specific", "need", "needs", "needed", "method"
    ]

    /// Calculates similarity between two clarifications using Levenshtein distance
    private func areClarificationsSimilar(_ first: String, _ second: String) -> Bool {
        // Normalize for comparison (just lowercase and trim)
        let normalizedFirst = first.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSecond = second.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check exact match
        if normalizedFirst == normalizedSecond {
            return true
        }

        // Remove punctuation for better comparison
        let punctuationSet = CharacterSet.punctuationCharacters.union(.symbols)
        let cleanFirst = normalizedFirst.components(separatedBy: punctuationSet).joined(separator: " ")
        let cleanSecond = normalizedSecond.components(separatedBy: punctuationSet).joined(separator: " ")

        // Calculate normalized Levenshtein distance
        let distance = levenshteinDistance(cleanFirst, cleanSecond)
        let maxLength = max(cleanFirst.count, cleanSecond.count)

        // Avoid division by zero
        guard maxLength > 0 else { return true }

        // Calculate similarity as 1 - (distance / maxLength)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))

        // Two questions are considered similar if they're 70% similar
        // This threshold is based on empirical testing of question variations
        return similarity > 0.7
    }

    /// Calculates Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        // Handle edge cases
        if m == 0 { return n }
        if n == 0 { return m }

        // Create matrix
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        // Initialize first row and column
        for i in 0...m {
            matrix[i][0] = i
        }
        for j in 0...n {
            matrix[0][j] = j
        }

        // Fill the matrix
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[m][n]
    }


    /// Collects clarifications in batches by category
    public func collectBatchedClarifications(
        requirementsClarifications: [String],
        stackClarifications: [String]
    ) async -> (requirements: [String: String], stack: [String: String]) {
        // Deduplicate questions first
        let (deduplicatedRequirements, deduplicatedStack) = deduplicateClarifications(
            requirementsClarifications: requirementsClarifications,
            stackClarifications: stackClarifications
        )
        var requirementsResponses: [String: String] = [:]
        var stackResponses: [String: String] = [:]

        // Collect requirements clarifications
        if !deduplicatedRequirements.isEmpty {
            requirementsResponses = await collectClarifications(
                for: deduplicatedRequirements,
                category: PRDConstants.AnalysisMessages.requirementsClarificationsHeader
            )
        }

        // Collect stack clarifications (only non-duplicates)
        if !deduplicatedStack.isEmpty {
            stackResponses = await collectClarifications(
                for: deduplicatedStack,
                category: PRDConstants.AnalysisMessages.stackClarificationsHeader
            )
        }

        return (requirementsResponses, stackResponses)
    }

    // MARK: - Private Methods

    private func collectRequiredAnswer(for question: String) async -> String {
        print("\n❓ \(question)")
        let response = await interactionHandler.askQuestion("Your answer (required)")

        if response.isEmpty {
            print(PRDConstants.AnalysisMessages.answerRequired)
            let secondTry = await interactionHandler.askQuestion("Your answer")
            return secondTry.isEmpty ? "Not specified" : secondTry
        }

        return response
    }
}