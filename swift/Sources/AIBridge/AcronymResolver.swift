import Foundation

public enum AcronymResolver {
    // Build a concise policy for the system prompt
    public static func buildSystemPolicy(glossary: DomainGlossary) -> String {
        let domain = glossary.domain.rawValue.capitalized
        let pairs = glossary.list().map { "\($0.acronym): \($0.expansion)" }.joined(separator: "; ")
        return """
        Acronym Policy (Domain: \(domain)):
        - Use the following glossary when interpreting acronyms.
        - If an acronym is not in the glossary or is ambiguous, ask a brief clarification question instead of guessing.
        - On first use, expand the acronym in parentheses, e.g., "PRD (Product Requirements Document)".
        - Maintain consistency across the conversation.
        Glossary: \(pairs)
        """
    }
    
    // Optionally expand first-use acronyms in the user message to help the model
    public static func expandFirstUse(in text: String, glossary: DomainGlossary) -> String {
        // Simple heuristic: for every known acronym in glossary, if it appears as a standalone token,
        // expand the first occurrence with parenthetical.
        var updated = text
        var expanded: Set<String> = []
        let tokens = glossary.list().map { $0.acronym }.sorted { $0.count > $1.count } // longer first
        for acr in tokens {
            guard !expanded.contains(acr) else { continue }
            let pattern = "(?<![A-Za-z])\(NSRegularExpression.escapedPattern(for: acr))(?![A-Za-z])"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                if let match = regex.firstMatch(in: updated, range: NSRange(updated.startIndex..., in: updated)) {
                    if let range = Range(match.range, in: updated), let exp = glossary.resolve(acr) {
                        let replacement = "\(acr) (\(exp))"
                        updated.replaceSubrange(range, with: replacement)
                        expanded.insert(acr)
                    }
                }
            }
        }
        return updated
    }
    
    // Validate the response to ensure acronyms align with glossary; if not, suggest clarification.
    public static func validateAndAmend(response: String, glossary: DomainGlossary, history: [String] = []) -> (String, needsClarification: Bool) {
        // For now, we’ll detect presence of known acronyms and ensure at least one expansion is present on first use.
        // If we find a conflicting common expansion (e.g., "Public Relations Department" for PRD), we amend with a note.
        var amended = response
        var needsClarification = false
        
        // Dictionary of common conflicting expansions we want to guard against (lightweight)
        let conflictGuesses: [String: [String]] = [
            "PRD": ["Public Relations Department", "Product Requirement Details"]
        ]
        
        let glossaryMap = Dictionary(uniqueKeysWithValues: glossary.list().map { ($0.acronym, $0.expansion) })
        
        for (acr, expected) in glossaryMap {
            let acrPattern = "(?<![A-Za-z])\(NSRegularExpression.escapedPattern(for: acr))(?![A-Za-z])"
            guard let acrRegex = try? NSRegularExpression(pattern: acrPattern) else { continue }
            let hasAcr = acrRegex.firstMatch(in: amended, range: NSRange(amended.startIndex..., in: amended)) != nil
            if !hasAcr { continue }
            
            // If first-use not expanded anywhere, add expansion to the first occurrence.
            if amended.range(of: "\(acr) (") == nil {
                if let match = acrRegex.firstMatch(in: amended, range: NSRange(amended.startIndex..., in: amended)),
                   let r = Range(match.range, in: amended) {
                    amended.replaceSubrange(r, with: "\(acr) (\(expected))")
                }
            }
            
            // Guard against conflicting expansions
            if let conflicts = conflictGuesses[acr] {
                for wrong in conflicts {
                    if amended.localizedCaseInsensitiveContains("\(acr) (\(wrong))") {
                        // Replace wrong expansion with expected and add a short note at the end
                        amended = amended.replacingOccurrences(of: "\(acr) (\(wrong))", with: "\(acr) (\(expected))", options: .caseInsensitive)
                        needsClarification = true
                    }
                }
            }
        }
        
        if needsClarification {
            amended += "\n\nNote: Interpreted acronyms per session glossary. If you intended a different meaning, please clarify."
        }
        
        return (amended, needsClarification)
    }
}

