import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles generation of PRD sections
public final class SectionGenerator: SectionGeneratorProtocol {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Generates a section using the AI provider
    public func generateSection(input: String, prompt: String) async throws -> String {
        let formattedPrompt = prompt.replacingOccurrences(
            of: "%%@",
            with: input
        )

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: formattedPrompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            print(String(format: PRDDisplayConstants.ErrorMessages.generationError, error.localizedDescription))
            throw error
        }
    }
}