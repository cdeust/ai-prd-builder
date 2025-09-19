import Foundation
import CommonModels
import AIProvidersCore

/// Anthropic provider implementation
public final class AnthropicProvider: AIProvider {
    public let name = "Anthropic"
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        guard !apiKey.isEmpty else {
            return .failure(.notConfigured)
        }

        // This would implement actual Anthropic API calls
        // For now, return a placeholder
        return .success("Anthropic response placeholder")
    }
}