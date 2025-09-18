import Foundation
import CommonModels

public protocol AIProvider {
    var name: String { get }
    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError>
}

public extension AIProvider {
    func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        let messages = [ChatMessage(role: .user, content: message)]
        return await sendMessages(messages)
    }
}
