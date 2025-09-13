import Foundation

// MARK: - Core Protocol

/// Clean AI Provider protocol following Interface Segregation Principle
public protocol AIProvider {
    var name: String { get }
    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError>
}

/// Extension for convenience methods
public extension AIProvider {
    func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        let messages = [ChatMessage(role: .user, content: message)]
        return await sendMessages(messages)
    }
}
