import Foundation

/// Factory for creating AI providers (Factory Pattern + Dependency Injection)
public protocol AIProviderFactory {
    func createProvider(type: AIProviderType, config: AIProviderConfig) -> AIProvider
}

public enum AIProviderType {
    case appleOnDevice
    case applePCC
    case openAI
    case anthropic
    case gemini
}

/// Default implementation of the factory
public final class DefaultAIProviderFactory: AIProviderFactory {
    private let networkClient: NetworkClient
    
    public init(networkClient: NetworkClient? = nil) {
        self.networkClient = networkClient ?? URLSessionNetworkClient()
    }
    
    public func createProvider(type: AIProviderType, config: AIProviderConfig) -> AIProvider {
        switch type {
        case .appleOnDevice:
            return AppleOnDeviceAIProvider()

        case .applePCC:
            return ApplePCCAIProvider()

        case .openAI:
            return GenericAIProvider(
                name: "OpenAI",
                config: config,
                networkClient: networkClient,
                requestBuilder: OpenAIRequestBuilder(),
                responseParser: OpenAIResponseParser()
            )

        case .anthropic:
            return GenericAIProvider(
                name: "Anthropic",
                config: config,
                networkClient: networkClient,
                requestBuilder: AnthropicRequestBuilder(),
                responseParser: AnthropicResponseParser()
            )

        case .gemini:
            return GenericAIProvider(
                name: "Gemini",
                config: config,
                networkClient: networkClient,
                requestBuilder: GeminiRequestBuilder(),
                responseParser: GeminiResponseParser()
            )
        }
    }
    
    /// Convenience method to create provider with just API key
    public func createProvider(type: AIProviderType, apiKey: String) -> AIProvider {
        let model: String
        let endpoint: String?

        switch type {
        case .appleOnDevice, .applePCC:
            // Apple providers don't need API keys
            let config = AIProviderConfig(
                apiKey: "",
                endpoint: nil,
                model: ""
            )
            return createProvider(type: type, config: config)

        case .openAI:
            model = AIProviderConstants.Models.openAIDefault
            endpoint = AIProviderConstants.Endpoints.openAI
        case .anthropic:
            model = AIProviderConstants.Models.anthropicDefault
            endpoint = AIProviderConstants.Endpoints.anthropic
        case .gemini:
            model = AIProviderConstants.Models.geminiDefault
            endpoint = nil
        }

        let config = AIProviderConfig(
            apiKey: apiKey,
            endpoint: endpoint,
            model: model
        )

        return createProvider(type: type, config: config)
    }
}