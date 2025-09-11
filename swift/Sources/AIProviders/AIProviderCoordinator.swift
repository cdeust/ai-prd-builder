import Foundation

/// Coordinator for managing AI providers without singleton pattern
/// Uses dependency injection and follows SOLID principles
public final class AIProviderCoordinator {
    private let repository: AIProviderRepository
    private let factory: AIProviderFactory
    private let configurationLoader: ConfigurationLoader
    private var activeProviderKey: String?
    
    public init(
        repository: AIProviderRepository? = nil,
        factory: AIProviderFactory? = nil,
        configurationLoader: ConfigurationLoader? = nil
    ) {
        self.repository = repository ?? InMemoryAIProviderRepository()
        self.factory = factory ?? DefaultAIProviderFactory()
        self.configurationLoader = configurationLoader ?? EnvironmentConfigurationLoader()
    }
    
    /// Load configuration and initialize providers
    public func initialize() async -> Result<Void, AIProviderError> {
        let configResult = await configurationLoader.loadConfiguration()
        
        switch configResult {
        case .failure(let error):
            return .failure(error)
        case .success(let configuration):
            // Register providers from configuration
            for (key, config) in configuration.providers {
                let providerType: AIProviderType
                switch key {
                case AIProviderConstants.ProviderKeys.openAI:
                    providerType = .openAI
                case AIProviderConstants.ProviderKeys.anthropic:
                    providerType = .anthropic
                case AIProviderConstants.ProviderKeys.gemini:
                    providerType = .gemini
                default:
                    continue
                }
                
                let provider = factory.createProvider(type: providerType, config: config)
                repository.register(provider, forKey: key)
            }
            
            // Set default provider if specified
            if let defaultKey = configuration.defaultProvider {
                activeProviderKey = defaultKey
            } else {
                // Use first available provider as default
                activeProviderKey = configuration.providers.keys.first
            }
            
            return .success(())
        }
    }
    
    /// Register a custom provider
    public func registerProvider(_ provider: AIProvider, forKey key: String) {
        repository.register(provider, forKey: key)
        
        // Set as active if it's the first provider
        if activeProviderKey == nil {
            activeProviderKey = key
        }
    }
    
    /// Set the active provider
    public func setActiveProvider(_ key: String) -> Result<Void, AIProviderError> {
        guard repository.getProvider(forKey: key) != nil else {
            return .failure(.notConfigured)
        }
        activeProviderKey = key
        return .success(())
    }
    
    /// Get the current active provider
    public func getActiveProvider() -> Result<AIProvider, AIProviderError> {
        guard let key = activeProviderKey,
              let provider = repository.getProvider(forKey: key) else {
            return .failure(.notConfigured)
        }
        return .success(provider)
    }
    
    /// Send message using active provider
    public func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        switch getActiveProvider() {
        case .failure(let error):
            return .failure(error)
        case .success(let provider):
            return await provider.sendMessage(message)
        }
    }
    
    /// Send messages using active provider
    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        switch getActiveProvider() {
        case .failure(let error):
            return .failure(error)
        case .success(let provider):
            return await provider.sendMessages(messages)
        }
    }
    
    /// Get all registered providers
    public func getAllProviders() -> [String: AIProvider] {
        repository.getAllProviders()
    }
}

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