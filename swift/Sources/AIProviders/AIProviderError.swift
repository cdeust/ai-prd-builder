import Foundation

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
