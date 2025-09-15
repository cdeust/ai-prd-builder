import Foundation

/// Use case for analyzing code (Single Responsibility)
public final class AnalyzeCodeUseCase {
    private let coordinator: AIProviderCoordinator
    
    public init(coordinator: AIProviderCoordinator) {
        self.coordinator = coordinator
    }
    
    public func execute(code: String, prompt: String? = nil) async -> Result<String, AIProviderError> {
        let analysisPrompt = prompt ?? AIProviderConstants.CodeAnalysis.defaultPrompt

        let messages = [
            ChatMessage(role: .system, content: AIProviderConstants.CodeAnalysis.systemRole),
            ChatMessage(role: .user, content: buildUserPrompt(analysisPrompt: analysisPrompt, code: code))
        ]

        return await coordinator.sendMessages(messages)
    }

    private func buildUserPrompt(analysisPrompt: String, code: String) -> String {
        return analysisPrompt +
               AIProviderConstants.CodeAnalysis.codeBlockPrefix +
               code +
               AIProviderConstants.CodeAnalysis.codeBlockSuffix
    }
}
