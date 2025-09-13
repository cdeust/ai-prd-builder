import Foundation

/// Use case for analyzing code (Single Responsibility)
public final class AnalyzeCodeUseCase {
    private let coordinator: AIProviderCoordinator
    
    public init(coordinator: AIProviderCoordinator) {
        self.coordinator = coordinator
    }
    
    public func execute(code: String, prompt: String? = nil) async -> Result<String, AIProviderError> {
        let analysisPrompt = prompt ?? "Analyze this code for potential improvements, bugs, and best practices."
        
        let messages = [
            ChatMessage(role: .system, content: "You are a code analysis expert."),
            ChatMessage(role: .user, content: "\(analysisPrompt)\n\nCode:\n```\n\(code)\n```")
        ]
        
        return await coordinator.sendMessages(messages)
    }
}
