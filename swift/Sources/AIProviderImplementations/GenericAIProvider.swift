import Foundation
import CommonModels
import AIProvidersCore

/// Generic AI Provider implementation using dependency injection
public final class GenericAIProvider: AIProvider {
    public let name: String
    private let config: AIProviderConfig
    private let networkClient: NetworkClient
    private let requestBuilder: RequestBuilder
    private let responseParser: ResponseParser
    
    public init(
        name: String,
        config: AIProviderConfig,
        networkClient: NetworkClient,
        requestBuilder: RequestBuilder,
        responseParser: ResponseParser
    ) {
        self.name = name
        self.config = config
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
        self.responseParser = responseParser
    }
    
    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        // Validate configuration
        guard !config.apiKey.isEmpty else {
            return .failure(.notConfigured)
        }

        // Build request
        let request = requestBuilder.buildRequest(config: config, messages: messages)

        do {
            // Perform network request
            let (data, _) = try await networkClient.send(request)

            // Parse response
            let response = try responseParser.parseResponse(data)
            return .success(response)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}