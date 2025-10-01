import Foundation

/// Protocol for AI provider implementations
public protocol AIProvider {
    var name: String { get }
    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError>
    func sendMessages(_ messages: [ChatMessage], temperature: Double?) async -> Result<String, AIProviderError>
}

public extension AIProvider {
    // Default implementation that delegates to the simpler version
    func sendMessages(_ messages: [ChatMessage], temperature: Double?) async -> Result<String, AIProviderError> {
        // Default to using the basic implementation (providers can override)
        return await sendMessages(messages)
    }

    func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        let messages = [ChatMessage(role: .user, content: message)]
        return await sendMessages(messages)
    }
}