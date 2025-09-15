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
        // Always register Apple providers first (no API key needed)
        registerAppleProviders()

        let configResult = await configurationLoader.loadConfiguration()

        switch configResult {
        case .failure(let error):
            // Log the configuration error for debugging
            print("⚠️ Configuration loading failed: \(error.localizedDescription)")
            print("ℹ️ Falling back to Apple providers only")

            // Even if configuration fails, Apple providers are available
            setDefaultAppleProvider()

            // Return success since Apple providers are registered
            // But include context about the configuration failure
            return .success(())
        case .success(let configuration):
            registerProvidersFromConfiguration(configuration)
            // Set Apple as default unless explicitly configured otherwise
            if configuration.defaultProvider == nil {
                setDefaultAppleProvider()
            } else {
                setDefaultProvider(from: configuration)
            }
            return .success(())
        }
    }

    // MARK: - Private Helper Methods

    private func registerAppleProviders() {
        // Register Apple on-device provider
        let onDeviceProvider = factory.createProvider(
            type: .appleOnDevice,
            config: AIProviderConfig(apiKey: "", endpoint: nil, model: "")
        )
        repository.register(onDeviceProvider, forKey: AIProviderConstants.ProviderKeys.appleOnDevice)

        // Register Apple PCC provider
        let pccProvider = factory.createProvider(
            type: .applePCC,
            config: AIProviderConfig(apiKey: "", endpoint: nil, model: "")
        )
        repository.register(pccProvider, forKey: AIProviderConstants.ProviderKeys.applePCC)
    }

    private func setDefaultAppleProvider() {
        activeProviderKey = AIProviderConstants.ProviderKeys.appleOnDevice
    }

    private func registerProvidersFromConfiguration(_ configuration: AIProviderConfiguration) {
        for (key, config) in configuration.providers {
            if let providerType = mapKeyToProviderType(key) {
                let provider = factory.createProvider(type: providerType, config: config)
                repository.register(provider, forKey: key)
            }
        }
    }

    private func mapKeyToProviderType(_ key: String) -> AIProviderType? {
        switch key {
        case AIProviderConstants.ProviderKeys.appleOnDevice:
            return .appleOnDevice
        case AIProviderConstants.ProviderKeys.applePCC:
            return .applePCC
        case AIProviderConstants.ProviderKeys.openAI:
            return .openAI
        case AIProviderConstants.ProviderKeys.anthropic:
            return .anthropic
        case AIProviderConstants.ProviderKeys.gemini:
            return .gemini
        default:
            return nil
        }
    }

    private func setDefaultProvider(from configuration: AIProviderConfiguration) {
        activeProviderKey = configuration.defaultProvider ?? configuration.providers.keys.first
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

    /// Switch to a specific provider by key
    public func switchProvider(to key: String) async -> Result<Void, AIProviderError> {
        return setActiveProvider(key)
    }

}
