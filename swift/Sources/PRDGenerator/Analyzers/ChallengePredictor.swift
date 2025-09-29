import Foundation
import CommonModels
import DomainCore

/// Predicts technical challenges from requirements
/// Single Responsibility: Only predicts potential technical issues
public final class ChallengePredictor {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public func predictChallenges(from requirements: String) async throws -> [TechnicalChallenge] {
        // Extract individual requirements first
        let individualRequirements = extractRequirementsFromText(requirements)

        // Group requirements into small batches (2-3 at a time)
        let batchSize = 2
        var batches: [[String]] = []

        for i in stride(from: 0, to: individualRequirements.count, by: batchSize) {
            let endIndex = min(i + batchSize, individualRequirements.count)
            let batch = Array(individualRequirements[i..<endIndex])
            batches.append(batch)
        }

        // Analyze each batch in parallel
        let challengeTasks = batches.map { batch in
            Task { () -> [TechnicalChallenge] in
                // Create compact chunk from batch
                let chunk = batch.map { String($0.prefix(200)) }.joined(separator: "\n")
                return await self.analyzeChallengesForChunk(chunk)
            }
        }

        // Wait for all chunks to complete
        var allChallenges: [TechnicalChallenge] = []
        for task in challengeTasks {
            let chunkChallenges = await task.value
            allChallenges.append(contentsOf: chunkChallenges)
        }

        // Deduplicate and prioritize challenges
        return deduplicateChallenges(allChallenges)
    }

    private func analyzeChallengesForChunk(_ chunk: String) async -> [TechnicalChallenge] {
        let prompt = PRDPrompts.technicalChallengesPredictionPrompt
            .replacingOccurrences(of: "%@", with: chunk)

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.challengeAnalysisSystemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        // Use lower temperature for strict analysis to avoid hallucination
        let result = await provider.sendMessages(messages, temperature: 0.3)
        switch result {
        case .success(let response):
            return parseChallenges(from: response)
        case .failure(let error):
            print("[ChallengePredictor] Chunk analysis failed: \(error)")
            return []
        }
    }

    private func extractRequirementsFromText(_ text: String) -> [String] {
        // Smart extraction of individual requirements
        var requirements: [String] = []
        let lines = text.components(separatedBy: "\n")
        var currentRequirement = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip section headers and metadata
            if trimmed.hasPrefix("##") || trimmed.hasPrefix("===") || trimmed.isEmpty {
                if !currentRequirement.isEmpty {
                    requirements.append(currentRequirement)
                    currentRequirement = ""
                }
                continue
            }

            // Detect requirement markers
            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") ||
               (trimmed.first?.isNumber ?? false && trimmed.contains(".")) {
                if !currentRequirement.isEmpty {
                    requirements.append(currentRequirement)
                }
                // Remove bullet point or number
                let cleanReq = trimmed.replacingOccurrences(of: "^[\\-•\\*\\d\\.\\s]+", with: "",
                                                           options: .regularExpression)
                currentRequirement = cleanReq
            } else {
                // Continue current requirement
                if !currentRequirement.isEmpty {
                    currentRequirement += " " + trimmed
                } else {
                    currentRequirement = trimmed
                }
            }
        }

        if !currentRequirement.isEmpty {
            requirements.append(currentRequirement)
        }

        return requirements
    }

    private func splitIntoChunks(_ text: String, maxChunkSize: Int) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var chunks: [String] = []
        var currentChunk = ""
        var currentSize = 0

        for line in lines {
            if currentSize + line.count > maxChunkSize && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = line
                currentSize = line.count
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += "\n"
                }
                currentChunk += line
                currentSize += line.count
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        // If no lines, just split by character count
        if chunks.isEmpty && !text.isEmpty {
            var index = text.startIndex
            while index < text.endIndex {
                let endIndex = text.index(index, offsetBy: maxChunkSize, limitedBy: text.endIndex) ?? text.endIndex
                chunks.append(String(text[index..<endIndex]))
                index = endIndex
            }
        }

        return chunks
    }

    private func deduplicateChallenges(_ challenges: [TechnicalChallenge]) -> [TechnicalChallenge] {
        var seen = Set<String>()
        var unique: [TechnicalChallenge] = []

        for challenge in challenges {
            let key = "\(challenge.category)|\(challenge.title)"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(challenge)
            }
        }

        // Sort by priority
        return unique.sorted { c1, c2 in
            // Sort critical first, then high, then medium
            if c1.priority == c2.priority {
                return c1.title < c2.title
            }
            if c1.priority == .critical { return true }
            if c2.priority == .critical { return false }
            if c1.priority == .high { return true }
            if c2.priority == .high { return false }
            return c1.title < c2.title
        }
    }

    private func parseChallenges(from response: String) -> [TechnicalChallenge] {
        // First check if it's a simple "no challenges" response
        let responseLower = response.lowercased()
        if responseLower.contains("no technical challenges") ||
           responseLower.contains("no significant technical challenges") ||
           responseLower.contains("no challenges identified") ||
           responseLower.contains("no challenges detected") {
            return []
        }

        // Try to extract JSON if present (for backward compatibility)
        if let jsonData = extractJSON(from: response),
           let challengesArray = jsonData["technical_challenges"] as? [[String: Any]] {
            return parseChallengesFromJSON(challengesArray)
        }

        // Parse natural language response
        return parseChallengesFromProse(response)
    }

    private func parseChallengesFromJSON(_ challengesArray: [[String: Any]]) -> [TechnicalChallenge] {
        return challengesArray.compactMap { data in
            guard let categoryStr = data["category"] as? String,
                  let description = data["description"] as? String,
                  let severityStr = data["severity"] as? String else {
                return nil
            }

            // Extract the related requirement if provided
            let relatedRequirement = data["related_requirement"] as? String
            let questions = data["critical_questions"] as? [String] ?? []
            let mitigation = data["mitigation"] as? String ?? ""

            let preventiveMeasures = [
                TechnicalChallenge.PreventiveMeasure(
                    action: mitigation,
                    complexity: 5,
                    effectiveness: .high
                )
            ]

            return TechnicalChallenge(
                category: mapCategory(categoryStr),
                title: extractTitle(from: description),
                description: description,
                relatedRequirement: relatedRequirement,  // Include the quoted requirement text
                probability: mapProbability(severityStr),
                impact: mapImpact(data),
                detectionPoint: mapDetectionPoint(data["when_surfaced"] as? String),
                preventiveMeasures: preventiveMeasures
            )
        }
    }

    private func parseChallengesFromProse(_ response: String) -> [TechnicalChallenge] {
        // Parse challenges from natural language response
        var challenges: [TechnicalChallenge] = []

        let sections = response.components(separatedBy: .newlines)
        var currentChallenge: (requirement: String?, description: String?, mitigation: String?) = (nil, nil, nil)

        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespaces)

            // Look for quoted requirements
            if trimmed.contains("\"") {
                let quotes = trimmed.components(separatedBy: "\"").enumerated().compactMap { index, text in
                    index % 2 == 1 ? text : nil
                }
                if !quotes.isEmpty {
                    currentChallenge.requirement = quotes[0]
                }
            }

            // Look for challenge description
            if trimmed.lowercased().contains("challenge:") ||
               trimmed.lowercased().contains("issue:") ||
               trimmed.lowercased().contains("problem:") {
                currentChallenge.description = trimmed
            }

            // Look for mitigation
            if trimmed.lowercased().contains("mitigation:") ||
               trimmed.lowercased().contains("solution:") ||
               trimmed.lowercased().contains("approach:") {
                currentChallenge.mitigation = trimmed
            }

            // If we have enough info, create a challenge
            if let desc = currentChallenge.description {
                challenges.append(TechnicalChallenge(
                    category: detectCategoryFromText(desc),
                    title: extractTitle(from: desc),
                    description: desc,
                    relatedRequirement: currentChallenge.requirement,
                    probability: TechnicalChallenge.Probability(value: 0.5),
                    impact: TechnicalChallenge.Impact(
                        severity: .moderate,
                        scope: .limited,
                        duration: .mediumTerm,
                        description: desc
                    ),
                    detectionPoint: .development,
                    preventiveMeasures: currentChallenge.mitigation != nil ? [
                        TechnicalChallenge.PreventiveMeasure(
                            action: currentChallenge.mitigation ?? "",
                            complexity: 5,
                            effectiveness: .moderate
                        )
                    ] : []
                ))
                currentChallenge = (nil, nil, nil)
            }
        }

        return challenges
    }

    private func detectCategoryFromText(_ text: String) -> TechnicalChallenge.Category {
        let lower = text.lowercased()
        if lower.contains("performance") { return .performance }
        if lower.contains("security") { return .security }
        if lower.contains("scale") || lower.contains("scaling") { return .scalability }
        if lower.contains("integration") { return .integration }
        if lower.contains("compatibility") { return .compatibility }
        return .complexity
    }

    private func mapCategory(_ str: String) -> TechnicalChallenge.Category {
        switch str.lowercased() {
        case "platform_limitation": return .compatibility
        case "performance": return .performance
        case "security": return .security
        case "integration": return .integration
        case "scaling": return .scalability
        default: return .complexity
        }
    }

    private func extractTitle(from description: String) -> String {
        // Take first 50 chars or until first period
        let endIndex = description.firstIndex(of: ".") ?? description.index(description.startIndex, offsetBy: min(50, description.count))
        return String(description[..<endIndex])
    }

    private func mapProbability(_ severity: String) -> TechnicalChallenge.Probability {
        switch severity.lowercased() {
        case "critical": return TechnicalChallenge.Probability(value: 0.9)
        case "high": return TechnicalChallenge.Probability(value: 0.7)
        case "medium": return TechnicalChallenge.Probability(value: 0.5)
        default: return TechnicalChallenge.Probability(value: 0.3)
        }
    }

    private func mapImpact(_ data: [String: Any]) -> TechnicalChallenge.Impact {
        let severityStr = data["severity"] as? String ?? "moderate"
        let costStr = data["cost_to_fix_late"] as? String ?? ""

        let severity: TechnicalChallenge.Impact.Severity
        if costStr.contains("10x") || severityStr == "critical" {
            severity = .critical
        } else if costStr.contains("5x") || severityStr == "high" {
            severity = .high
        } else {
            severity = .moderate
        }

        return TechnicalChallenge.Impact(
            severity: severity,
            scope: .moderate,
            duration: .mediumTerm,
            description: costStr
        )
    }

    private func mapDetectionPoint(_ str: String?) -> TechnicalChallenge.DetectionPoint {
        switch str?.lowercased() {
        case "development": return .development
        case "testing": return .testing
        case "production": return .production
        case "scale": return .scale
        default: return .planning
        }
    }

    private func extractJSON(from response: String) -> [String: Any]? {
        guard let jsonStart = response.range(of: "```json\n"),
              let jsonEnd = response.range(of: "\n```", range: jsonStart.upperBound..<response.endIndex) else {
            return nil
        }

        let jsonContent = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])
        guard let data = jsonContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }
}