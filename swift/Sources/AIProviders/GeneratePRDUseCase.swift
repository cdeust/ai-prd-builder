import Foundation

/// Use case for generating PRDs (Single Responsibility)
public final class GeneratePRDUseCase {
    private let coordinator: AIProviderCoordinator
    
    public init(coordinator: AIProviderCoordinator) {
        self.coordinator = coordinator
    }
    
    public func execute(description: String) async -> Result<String, AIProviderError> {
        let systemPrompt = """
        You are a Product Requirements Document (PRD) generator.
        Create a comprehensive PRD based on the given description.
        Include sections for: Overview, User Stories, Functional Requirements,
        Non-Functional Requirements, Success Metrics, and Technical Considerations.
        """
        
        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: description)
        ]
        
        return await coordinator.sendMessages(messages)
    }
}
