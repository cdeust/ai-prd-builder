import Foundation
import AIProvidersCore

// MARK: - Provider Configuration

public struct ProviderConfiguration {
    public let isConfigured: Bool
    public let apiKey: String?
    public let endpoint: String?
    public let model: String
    public let maxTokens: Int
    public let temperature: Double

    public init(
        isConfigured: Bool,
        apiKey: String?,
        endpoint: String? = nil,
        model: String,
        maxTokens: Int = AIProviderConstants.Defaults.maxTokens,
        temperature: Double = AIProviderConstants.Defaults.temperature
    ) {
        self.isConfigured = isConfigured
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

// MARK: - Factory

public extension ProviderConfiguration {
    static func fromEnvironment(for provider: Orchestrator.AIProvider) -> ProviderConfiguration? {
        switch provider {
        case .foundationModels:
            // No API key needed; availability is handled by AppleIntelligenceClient / Apple providers.
            return ProviderConfiguration(
                isConfigured: true,
                apiKey: nil,
                endpoint: nil,
                model: "on-device"
            )
        case .privateCloudCompute:
            // No API key needed; availability is handled by AppleIntelligenceClient / Apple providers.
            return ProviderConfiguration(
                isConfigured: true,
                apiKey: nil,
                endpoint: nil,
                model: "privateCloudCompute"
            )
        case .anthropic:
            let key = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.anthropicKey]
            let configured = (key?.isEmpty == false)
            return ProviderConfiguration(
                isConfigured: configured,
                apiKey: key,
                endpoint: AIProviderConstants.Endpoints.anthropicBase,
                model: AIProviderConstants.Models.claudeOpus41  // Use Claude Opus 4.1 (2025)
            )

        case .openai:
            let key = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.openAIKey]
            let configured = (key?.isEmpty == false)
            return ProviderConfiguration(
                isConfigured: configured,
                apiKey: key,
                endpoint: AIProviderConstants.Endpoints.openAIBase,
                model: AIProviderConstants.Models.gpt5  // Use GPT-5 (2025)
            )

        case .gemini:
            let key = ProcessInfo.processInfo.environment[AIProviderConstants.EnvironmentKeys.geminiKey]
            let configured = (key?.isEmpty == false)
            return ProviderConfiguration(
                isConfigured: configured,
                apiKey: key,
                endpoint: AIProviderConstants.Endpoints.geminiBase,
                model: AIProviderConstants.Models.gemini25Pro  // Use Gemini 2.5 Pro (2025)
            )
        }
    }
}
