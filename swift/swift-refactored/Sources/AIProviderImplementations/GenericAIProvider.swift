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
        let requestResult = requestBuilder.buildRequest(for: messages, config: config)
        
        switch requestResult {
        case .failure(let error):
            return .failure(error)
        case .success(let request):
            // Perform network request
            let networkResult = await networkClient.performRequest(request)
            
            switch networkResult {
            case .failure(let error):
                return .failure(error)
            case .success(let data):
                // Parse response
                return responseParser.parseResponse(data)
            }
        }
    }
}