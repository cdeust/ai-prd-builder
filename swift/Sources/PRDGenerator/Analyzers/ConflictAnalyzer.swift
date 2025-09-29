import Foundation
import CommonModels
import DomainCore

/// Analyzes requirements for architectural conflicts
/// Single Responsibility: Only detects conflicts between requirements
public final class ConflictAnalyzer {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    public func analyze(_ input: String) async throws -> [ArchitecturalConflict] {
        // Split input into individual requirements
        let requirements = extractRequirements(from: input)

        // If too few requirements, analyze as whole
        if requirements.count < 2 {
            return try await analyzeChunk(input)
        }

        // Create pairs of requirements to check for conflicts
        var allConflicts: [ArchitecturalConflict] = []

        // Analyze requirements in small batches for better token management
        let chunkSize = 3 // Analyze 3 requirements at a time

        // Create tasks for parallel processing
        var analysisTasks: [Task<[ArchitecturalConflict], Never>] = []

        for i in stride(from: 0, to: requirements.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, requirements.count)
            let chunk = Array(requirements[i..<endIndex])

            let task = Task {
                // Ensure chunk is small enough
                let compactChunk = chunk.map { req in
                    // Limit each requirement to 150 characters
                    String(req.prefix(150))
                }.joined(separator: "\n")

                return await self.analyzeChunkSafely(compactChunk)
            }
            analysisTasks.append(task)
        }

        // Wait for all parallel analyses
        for task in analysisTasks {
            let chunkConflicts = await task.value
            allConflicts.append(contentsOf: chunkConflicts)
        }

        // Also check cross-chunk conflicts for critical requirements
        if requirements.count > chunkSize {
            let criticalRequirements = extractCriticalRequirements(requirements)
            if !criticalRequirements.isEmpty {
                let crossConflicts = try await analyzeChunk(criticalRequirements.joined(separator: "\n"))
                allConflicts.append(contentsOf: crossConflicts)
            }
        }

        // Deduplicate conflicts
        return deduplicateConflicts(allConflicts)
    }

    private func analyzeChunkSafely(_ chunk: String) async -> [ArchitecturalConflict] {
        do {
            return try await analyzeChunk(chunk)
        } catch {
            print("[ConflictAnalyzer] Chunk analysis failed: \(error)")
            return []
        }
    }

    private func analyzeChunk(_ chunk: String) async throws -> [ArchitecturalConflict] {
        let prompt = PRDPrompts.architecturalConflictDetectionPrompt
            .replacingOccurrences(of: "%@", with: chunk)

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.challengeAnalysisSystemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        // Use lower temperature for strict analysis to avoid hallucination
        let result = await provider.sendMessages(messages, temperature: 0.3)
        switch result {
        case .success(let response):
            return parseConflicts(from: response)
        case .failure(let error):
            // Don't fail entire analysis if one chunk fails
            print("[ConflictAnalyzer] Chunk analysis failed: \(error)")
            return []
        }
    }

    private func extractRequirements(from input: String) -> [String] {
        var requirements: [String] = []
        let lines = input.components(separatedBy: "\n")
        var currentRequirement = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect requirement markers
            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") ||
               trimmed.hasPrefix("1.") || trimmed.hasPrefix("2.") || trimmed.hasPrefix("3.") {
                if !currentRequirement.isEmpty {
                    requirements.append(currentRequirement)
                }
                currentRequirement = trimmed
            } else if !trimmed.isEmpty && !currentRequirement.isEmpty {
                // Continue current requirement
                currentRequirement += " " + trimmed
            } else if !trimmed.isEmpty && requirements.isEmpty {
                // First content without marker
                currentRequirement = trimmed
            }
        }

        if !currentRequirement.isEmpty {
            requirements.append(currentRequirement)
        }

        return requirements
    }

    private func extractCriticalRequirements(_ requirements: [String]) -> [String] {
        // Extract requirements that are likely to conflict
        let criticalKeywords = ["real-time", "offline", "encryption", "e2e", "scale",
                               "concurrent", "blockchain", "distributed", "sync", "latency",
                               "performance", "secure", "privacy"]

        return requirements.filter { req in
            let lower = req.lowercased()
            return criticalKeywords.contains { keyword in
                lower.contains(keyword)
            }
        }
    }

    private func deduplicateConflicts(_ conflicts: [ArchitecturalConflict]) -> [ArchitecturalConflict] {
        var seen = Set<String>()
        var unique: [ArchitecturalConflict] = []

        for conflict in conflicts {
            let key = "\(conflict.requirement1)|\(conflict.requirement2)"
            let reverseKey = "\(conflict.requirement2)|\(conflict.requirement1)"

            if !seen.contains(key) && !seen.contains(reverseKey) {
                seen.insert(key)
                unique.append(conflict)
            }
        }

        return unique
    }

    private func parseConflicts(from response: String) -> [ArchitecturalConflict] {
        // First check if it's a simple "no conflicts" response
        let responseLower = response.lowercased()
        if responseLower.contains("no architectural conflicts") ||
           responseLower.contains("no conflicts detected") ||
           responseLower.contains("no conflicts exist") ||
           responseLower.contains("no conflicts identified") {
            return []
        }

        // Try to extract JSON if present (for backward compatibility)
        if let jsonData = extractJSON(from: response),
           let conflictsArray = jsonData["conflicts"] as? [[String: Any]] {
            return parseConflictsFromJSON(conflictsArray)
        }

        // Parse natural language response
        return parseConflictsFromProse(response)
    }

    private func parseConflictsFromJSON(_ conflictsArray: [[String: Any]]) -> [ArchitecturalConflict] {
        return conflictsArray.compactMap { data in
            guard let req1 = data["requirement1"] as? String,
                  let req2 = data["requirement2"] as? String,
                  let reason = data["conflict_reason"] as? String,
                  let tradeoff = data["forced_tradeoff"] as? String else {
                return nil
            }

            let examples = (data["examples"] as? [String] ?? []).map { example in
                // Parse "Company chose solution" format
                let parts = example.components(separatedBy: " chose ")
                return ArchitecturalConflict.RealWorldExample(
                    company: parts.first ?? "",
                    product: "",
                    solution: parts.last ?? "",
                    outcome: ""
                )
            }

            return ArchitecturalConflict(
                requirement1: req1,
                requirement2: req2,
                conflictType: detectConflictType(reason),
                severity: .high,
                resolution: ArchitecturalConflict.ResolutionStrategy(
                    approach: tradeoff,
                    tradeoffs: [tradeoff],
                    recommendation: data["impact"] as? String ?? ""
                ),
                realWorldExamples: examples
            )
        }
    }

    private func parseConflictsFromProse(_ response: String) -> [ArchitecturalConflict] {
        // If the response describes conflicts in prose, parse them
        // Look for patterns like "conflicts with", "contradicts", etc.

        var conflicts: [ArchitecturalConflict] = []

        // Split by common conflict indicators
        let sections = response.components(separatedBy: .newlines)

        var currentConflict: (req1: String?, req2: String?, reason: String?) = (nil, nil, nil)

        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespaces)

            // Look for quoted requirements
            if trimmed.contains("\"") {
                let quotes = trimmed.components(separatedBy: "\"").enumerated().compactMap { index, text in
                    index % 2 == 1 ? text : nil
                }

                if quotes.count >= 2 {
                    currentConflict.req1 = quotes[0]
                    currentConflict.req2 = quotes[1]
                }
            }

            // Look for conflict reason
            if trimmed.lowercased().contains("conflict") || trimmed.lowercased().contains("contradict") {
                currentConflict.reason = trimmed
            }

            // If we have both requirements and a reason, create a conflict
            if let req1 = currentConflict.req1,
               let req2 = currentConflict.req2,
               let reason = currentConflict.reason {
                conflicts.append(ArchitecturalConflict(
                    requirement1: req1,
                    requirement2: req2,
                    conflictType: detectConflictType(reason),
                    severity: .high,
                    resolution: ArchitecturalConflict.ResolutionStrategy(
                        approach: "Choose one approach over the other",
                        tradeoffs: [],
                        recommendation: reason
                    )
                ))
                currentConflict = (nil, nil, nil)
            }
        }

        return conflicts
    }

    private func detectConflictType(_ reason: String) -> ArchitecturalConflict.ConflictType {
        let lowercased = reason.lowercased()
        if lowercased.contains("performance") { return .performanceVsFeature }
        if lowercased.contains("security") { return .securityVsUsability }
        if lowercased.contains("scale") { return .scaleVsSimplicity }
        if lowercased.contains("real-time") && lowercased.contains("offline") { return .realtimeVsOffline }
        if lowercased.contains("privacy") { return .privacyVsFunctionality }
        return .mutuallyExclusive
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