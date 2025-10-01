import Foundation
import CommonModels

public struct AIProviderConfig {
    public let apiKey: String
    public let endpoint: String?
    public let model: String
    public let maxTokens: Int
    public let temperature: Double

    public init(
        apiKey: String,
        endpoint: String? = nil,
        model: String,
        maxTokens: Int = 4096,
        temperature: Double = 0.7
    ) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
