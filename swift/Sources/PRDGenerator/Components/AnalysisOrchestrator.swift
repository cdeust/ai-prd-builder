import Foundation
import CommonModels
import DomainCore

/// Orchestrates AI-based analysis of requirements and technical stack
public final class AnalysisOrchestrator {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Access to the AI provider for other components
    public var aiProvider: AIProvider {
        return provider
    }

    /// Performs initial requirements analysis
    public func analyzeRequirements(input: String) async throws -> RequirementsAnalysis {
        let analysisPrompt = String(format: PRDPrompts.requirementsAnalysisPrompt, input)
        return try await performAnalysis(prompt: analysisPrompt)
    }

    /// Analyzes technical stack requirements
    public func analyzeTechnicalStack(input: String) async throws -> RequirementsAnalysis {
        let stackPrompt = String(format: PRDPrompts.technicalStackAnalysisPrompt, input)
        return try await performAnalysis(prompt: stackPrompt)
    }

    /// Re-analyzes requirements with enriched context
    public func reanalyzeWithContext(enrichedInput: String) async throws -> RequirementsAnalysis {
        let reanalysisPrompt = String(format: PRDPrompts.reanalysisWithContextPrompt, enrichedInput)
        return try await performAnalysis(prompt: reanalysisPrompt)
    }

    // MARK: - Private Methods

    private func performAnalysis(prompt: String) async throws -> RequirementsAnalysis {
        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        // Use lower temperature for analysis tasks to reduce hallucination
        let result = await provider.sendMessages(messages, temperature: 0.4)
        switch result {
        case .success(let response):
            return parseAnalysisResponse(response)
        case .failure(let error):
            throw error
        }
    }

    private func parseAnalysisResponse(_ response: String) -> RequirementsAnalysis {
        // Extract JSON from response
        guard let jsonStart = response.range(of: "```json\n"),
              let jsonEnd = response.range(of: "\n```", range: jsonStart.upperBound..<response.endIndex) else {
            // Fallback if no JSON found
            return RequirementsAnalysis(
                confidence: 50,
                clarificationsNeeded: [],
                assumptions: [],
                gaps: []
            )
        }

        let jsonContent = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])

        guard let data = jsonContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return RequirementsAnalysis(
                confidence: 50,
                clarificationsNeeded: [],
                assumptions: [],
                gaps: []
            )
        }

        return RequirementsAnalysis(
            confidence: json["confidence"] as? Int ?? 50,
            clarificationsNeeded: json["clarifications_needed"] as? [String] ?? [],
            assumptions: json["assumptions"] as? [String] ?? [],
            gaps: json["gaps"] as? [String] ?? []
        )
    }
}