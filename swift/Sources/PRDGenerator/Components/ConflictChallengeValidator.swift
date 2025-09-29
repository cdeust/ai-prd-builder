import Foundation
import CommonModels

/// Validates that detected conflicts and challenges are actually relevant to the requirements
public final class ConflictChallengeValidator {

    /// Validates conflicts against actual requirements text
    public func validateConflicts(
        _ conflicts: [ArchitecturalConflict],
        against requirements: String
    ) -> [ArchitecturalConflict] {
        let requirementsLower = requirements.lowercased()

        // Filter out any conflicts that mention generic examples or unrelated content
        let invalidPatterns = [
            "think different",
            "crazy ones",
            "misfits",
            "rebels",
            "apple.com",
            "round pegs",
            "square holes"
        ]

        return conflicts.filter { conflict in
            let conflictText = "\(conflict.requirement1) \(conflict.requirement2)".lowercased()

            // Reject if it contains any invalid patterns
            for pattern in invalidPatterns {
                if conflictText.contains(pattern) {
                    return false
                }
            }

            // Strict validation: The conflict requirements must be nearly verbatim in the input
            // Check for exact or near-exact substring matches
            let req1Lower = conflict.requirement1.lowercased()
            let req2Lower = conflict.requirement2.lowercased()

            // First check: Are these exact substrings?
            let req1ExactMatch = requirementsLower.contains(req1Lower)
            let req2ExactMatch = requirementsLower.contains(req2Lower)

            if req1ExactMatch && req2ExactMatch {
                return true
            }

            // Second check: Do most key terms appear?
            let req1Terms = extractKeyTerms(from: conflict.requirement1)
            let req2Terms = extractKeyTerms(from: conflict.requirement2)

            // Require at least 75% of key terms to be present
            let req1MatchCount = req1Terms.filter { requirementsLower.contains($0.lowercased()) }.count
            let req2MatchCount = req2Terms.filter { requirementsLower.contains($0.lowercased()) }.count

            let req1MatchRatio = req1Terms.isEmpty ? 0.0 : Double(req1MatchCount) / Double(req1Terms.count)
            let req2MatchRatio = req2Terms.isEmpty ? 0.0 : Double(req2MatchCount) / Double(req2Terms.count)

            return req1MatchRatio >= 0.75 && req2MatchRatio >= 0.75
        }
    }

    /// Validates challenges against actual requirements text
    public func validateChallenges(
        _ challenges: [TechnicalChallenge],
        against requirements: String
    ) -> [TechnicalChallenge] {
        let requirementsLower = requirements.lowercased()

        return challenges.filter { challenge in
            // Strict validation: The challenge must reference specific requirements

            // Check if the challenge has a related_requirement field (if it exists)
            // This would be the quoted text from the requirement
            if let relatedReq = challenge.relatedRequirement {
                // Check if this requirement text actually appears in the input
                return requirementsLower.contains(relatedReq.lowercased())
            }

            // Otherwise, validate based on description terms
            let challengeTerms = extractKeyTerms(from: challenge.description)

            // Require multiple key terms to match, not just one
            let matchingTerms = challengeTerms.filter { requirementsLower.contains($0.lowercased()) }

            // At least 50% of challenge terms should be in requirements
            let matchRatio = challengeTerms.isEmpty ? 0.0 : Double(matchingTerms.count) / Double(challengeTerms.count)
            return matchRatio >= 0.5
        }
    }

    /// Checks if conflicts/challenges are generic templates vs specific to requirements
    public func detectGenericIssues(
        conflicts: [ArchitecturalConflict],
        challenges: [TechnicalChallenge],
        requirements: String
    ) -> (genericConflicts: [String], genericChallenges: [String]) {
        var genericConflicts: [String] = []
        var genericChallenges: [String] = []

        // Common generic conflict patterns that appear regardless of requirements
        let genericConflictPatterns = [
            "real-time collaboration",
            "offline-first",
            "end-to-end encryption",
            "microservices",
            "acid transactions",
            "eventually consistent",
            "multi-tenant",
            "custom schemas",
            "blockchain",
            "distributed",
            "synchronization",
            "consistency",
            "performance vs security",
            "scalability",
            "latency",
            "privacy"
        ]

        // Common generic challenge patterns
        let genericChallengePatterns = [
            "oauth setup",
            "payment processor",
            "csv export",
            "1m rows",
            "n+1 queries",
            "memory leaks",
            "30 seconds",
            "ios background",
            "rate limiting",
            "caching",
            "database optimization",
            "connection pooling",
            "authentication",
            "authorization",
            "data migration",
            "backwards compatibility"
        ]

        let requirementsLower = requirements.lowercased()

        // Check conflicts for generic patterns not in requirements
        for conflict in conflicts {
            let conflictText = "\(conflict.requirement1) \(conflict.requirement2)".lowercased()
            for pattern in genericConflictPatterns {
                if conflictText.contains(pattern) && !requirementsLower.contains(pattern) {
                    genericConflicts.append("\(conflict.requirement1) vs \(conflict.requirement2)")
                    break
                }
            }
        }

        // Check challenges for generic patterns not in requirements
        for challenge in challenges {
            let challengeText = challenge.description.lowercased()
            for pattern in genericChallengePatterns {
                if challengeText.contains(pattern) && !requirementsLower.contains(pattern) {
                    genericChallenges.append(challenge.title)
                    break
                }
            }
        }

        return (genericConflicts, genericChallenges)
    }

    /// Generates a relevance score for how well the analysis matches the requirements
    public func calculateRelevanceScore(
        conflicts: [ArchitecturalConflict],
        challenges: [TechnicalChallenge],
        requirements: String
    ) -> Double {
        guard !conflicts.isEmpty || !challenges.isEmpty else { return 1.0 }

        let validatedConflicts = validateConflicts(conflicts, against: requirements)
        let validatedChallenges = validateChallenges(challenges, against: requirements)

        let totalIssues = Double(conflicts.count + challenges.count)
        let relevantIssues = Double(validatedConflicts.count + validatedChallenges.count)

        return relevantIssues / totalIssues
    }

    // MARK: - Private Helpers

    private func extractKeyTerms(from text: String) -> [String] {
        // Extract meaningful terms (nouns, technical terms, etc.)
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
            .filter { !commonWords.contains($0.lowercased()) }

        return words
    }

    private let commonWords = Set([
        "with", "from", "that", "this", "have", "will", "should", "could",
        "would", "when", "where", "what", "which", "while", "about", "after",
        "before", "between", "during", "through", "under", "over", "into"
    ])
}