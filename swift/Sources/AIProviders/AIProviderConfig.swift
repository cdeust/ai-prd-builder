import Foundation

// MARK: - Models

public struct AIProviderConfig: Codable {
    public let apiKey: String
    public let endpoint: String?
    public let model: String
    public let maxTokens: Int
    public let temperature: Double
    
    private enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case endpoint
        case model
        case maxTokens = "max_tokens"
        case temperature
    }

    public init(
        apiKey: String,
        endpoint: String? = nil,
        model: String,
        maxTokens: Int = AIProviderConstants.Defaults.maxTokens,
        temperature: Double = AIProviderConstants.Defaults.temperature
    ) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
