import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles generation of PRD sections
public final class SectionGenerator: SectionGeneratorProtocol {
    private let provider: AIProvider
    private let configuration: Configuration
    private let chainOfThought: ChainOfThought?

    public init(provider: AIProvider, configuration: Configuration = Configuration()) {
        self.provider = provider
        self.configuration = configuration
        self.chainOfThought = configuration.useChainOfThought ? ChainOfThought(provider: provider) : nil
    }

    /// Generates a section using the AI provider
    /// Optionally uses ChainOfThought reasoning for improved accuracy
    public func generateSection(input: String, prompt: String) async throws -> String {
        let formattedPrompt = prompt.replacingOccurrences(
            of: "%%@",
            with: input
        )

        // Use ChainOfThought reasoning if enabled for complex sections
        if let cot = chainOfThought, shouldUseDeepReasoning(prompt: formattedPrompt) {
            DebugLogger.debug("Using ChainOfThought reasoning for complex section")
            let thoughtChain = try await cot.thinkThrough(
                problem: formattedPrompt,
                context: input,
                useSelfConsistency: configuration.useSelfConsistency,
                numPaths: configuration.useSelfConsistency ? 3 : 1
            )
            return thoughtChain.conclusion
        }

        // Standard generation without deep reasoning
        // Don't use systemPrompt here - it encourages generating full PRDs
        // The section-specific prompts already have strict instructions
        let messages = [
            ChatMessage(role: .user, content: formattedPrompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            DebugLogger.debug(String(format: PRDDisplayConstants.ErrorMessages.generationError, error.localizedDescription), prefix: "SectionGenerator")
            throw error
        }
    }

    /// Determines if deep reasoning should be used based on prompt complexity
    private func shouldUseDeepReasoning(prompt: String) -> Bool {
        // Use deep reasoning for complex sections
        let complexityIndicators = [
            "constraint", "security", "performance", "architecture",
            "validation", "alternative", "trade-off", "compare"
        ]

        let lowercasedPrompt = prompt.lowercased()
        return complexityIndicators.contains { lowercasedPrompt.contains($0) }
    }
}