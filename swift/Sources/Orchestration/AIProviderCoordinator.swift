import Foundation
import AIProvidersCore
import AIProviderImplementations
import CommonModels
import MLXIntegration

/// Coordinates between multiple AI providers based on privacy settings and availability
public class AIProviderCoordinator {

    private var providers: [String: AIProvider] = [:]
    private var currentProvider: AIProvider?

    public init() {
        setupProviders()
    }

    private func setupProviders() {
        // Initialize Apple/MLX provider first (always available)
        providers["apple"] = AppleProvider()
        providers["mlx"] = MLXProvider()

        // Initialize external providers (only if API keys are present)
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty {
            providers["openai"] = OpenAIProvider(apiKey: apiKey)
        }
        if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
            providers["anthropic"] = AnthropicProvider(apiKey: apiKey)
        }
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty {
            providers["gemini"] = GeminiProvider(apiKey: apiKey)
        }

        // Set default provider to Apple (privacy-first)
        currentProvider = providers["apple"] ?? providers["mlx"]
    }

    /// Select provider based on requirements
    public func selectProvider(for requirement: ProviderRequirement) -> AIProvider? {
        switch requirement {
        case .privacy:
            // For privacy, prefer local/on-device providers
            return providers["apple"] ?? providers["mlx"] ?? currentProvider
        case .speed:
            // For speed, use fastest available
            return providers["openai"] ?? currentProvider
        case .quality:
            // For quality, try external first, then fall back to Apple
            return providers["anthropic"] ?? providers["apple"] ?? currentProvider
        case .cost:
            // For cost, use cheapest
            return providers["gemini"] ?? currentProvider
        default:
            return currentProvider
        }
    }

    /// Get the current active provider
    public func getCurrentProvider() -> AIProvider? {
        return currentProvider
    }

    /// Switch to a specific provider
    public func switchProvider(to providerName: String) -> Bool {
        if let provider = providers[providerName] {
            currentProvider = provider
            return true
        }
        return false
    }

    /// List available providers
    public func availableProviders() -> [String] {
        return Array(providers.keys)
    }

    /// Send messages using the current provider
    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        guard let provider = currentProvider else {
            return .failure(.notConfigured)
        }
        return await provider.sendMessages(messages)
    }

    /// Initialize the coordinator
    public func initialize() async throws {
        // Setup providers if needed
        // This is a placeholder for any async initialization
        setupProviders()
    }
}

/// Requirements for provider selection
public enum ProviderRequirement {
    case privacy
    case speed
    case quality
    case cost
    case general
}