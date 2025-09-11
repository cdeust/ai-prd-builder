import Foundation

// MARK: - Core Protocol

/// Clean AI Provider protocol following Interface Segregation Principle
public protocol AIProvider {
    var name: String { get }
    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError>
}

/// Extension for convenience methods
public extension AIProvider {
    func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        let messages = [ChatMessage(role: .user, content: message)]
        return await sendMessages(messages)
    }
}

// MARK: - Models

public struct ChatMessage: Codable {
    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

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

// MARK: - Errors

public enum AIProviderError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case rateLimitExceeded
    case tokenLimitExceeded
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI provider is not configured. Please set API key."
        case .invalidAPIKey:
            return "Invalid API key provided."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .tokenLimitExceeded:
            return "Token limit exceeded. Please shorten your message."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}