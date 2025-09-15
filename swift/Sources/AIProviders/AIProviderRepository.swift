import Foundation

/// Repository protocol for managing AI providers (Repository Pattern)
public protocol AIProviderRepository {
    func register(_ provider: AIProvider, forKey key: String)
    func getProvider(forKey key: String) -> AIProvider?
    func getAllProviders() -> [String: AIProvider]
    func removeProvider(forKey key: String)
    func clearAll()
}

/// In-memory implementation of the repository
public final class InMemoryAIProviderRepository: AIProviderRepository {
    private var providers: [String: AIProvider] = [:]
    private let queue = DispatchQueue(label: AIProviderConstants.QueueLabels.repositoryQueue, attributes: .concurrent)
    
    public init() {}
    
    public func register(_ provider: AIProvider, forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.providers[key] = provider
        }
    }
    
    public func getProvider(forKey key: String) -> AIProvider? {
        queue.sync {
            providers[key]
        }
    }
    
    public func getAllProviders() -> [String: AIProvider] {
        queue.sync {
            providers
        }
    }
    
    public func removeProvider(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.providers.removeValue(forKey: key)
        }
    }
    
    public func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.providers.removeAll()
        }
    }
}

/// Configuration loader protocol (Single Responsibility)
public protocol ConfigurationLoader {
    func loadConfiguration() async -> Result<AIProviderConfiguration, AIProviderError>
}

/// Environment-based configuration loader
public struct EnvironmentConfigurationLoader: ConfigurationLoader {
    public init() {}
    
    public func loadConfiguration() async -> Result<AIProviderConfiguration, AIProviderError> {
        var configs: [String: AIProviderConfig] = [:]
        
        if let openaiKey = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.openAI] {
            configs[AIProviderConstants.ProviderKeys.openAI] = AIProviderConfig(
                apiKey: openaiKey,
                endpoint: AIProviderConstants.Endpoints.openAI,
                model: AIProviderConstants.Models.openAIDefault
            )
        }
        
        if let anthropicKey = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.anthropic] {
            configs[AIProviderConstants.ProviderKeys.anthropic] = AIProviderConfig(
                apiKey: anthropicKey,
                endpoint: AIProviderConstants.Endpoints.anthropic,
                model: AIProviderConstants.Models.anthropicDefault
            )
        }
        
        if let geminiKey = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.gemini] {
            configs[AIProviderConstants.ProviderKeys.gemini] = AIProviderConfig(
                apiKey: geminiKey,
                endpoint: nil,
                model: AIProviderConstants.Models.geminiDefault
            )
        }
        
        return .success(AIProviderConfiguration(providers: configs))
    }
}

/// File-based configuration loader
public struct FileConfigurationLoader: ConfigurationLoader {
    private let filePath: String
    
    public init(filePath: String) {
        self.filePath = filePath
    }
    
    public func loadConfiguration() async -> Result<AIProviderConfiguration, AIProviderError> {
        do {
            let url = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(AIProviderConfiguration.self, from: data)
            return .success(config)
        } catch {
            return .failure(.networkError(String(format: AIProviderConstants.ErrorMessages.failedToLoadConfiguration, error.localizedDescription)))
        }
    }
}

/// Configuration model
public struct AIProviderConfiguration: Codable {
    public let providers: [String: AIProviderConfig]
    public let defaultProvider: String?
    
    public init(providers: [String: AIProviderConfig], defaultProvider: String? = nil) {
        self.providers = providers
        self.defaultProvider = defaultProvider
    }
}