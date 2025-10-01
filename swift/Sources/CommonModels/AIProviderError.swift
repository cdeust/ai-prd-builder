import Foundation

public enum AIProviderError: LocalizedError, Equatable {
    case invalidAPIKey
    case networkError(String)
    case rateLimitExceeded
    case invalidResponse
    case serverError(Int, String)
    case unsupportedFeature(String)
    case configurationError(String)
    case timeout
    case cancelled
    case notConfigured

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Invalid response from provider"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .unsupportedFeature(let feature):
            return "Unsupported feature: \(feature)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .notConfigured:
            return "Provider not configured"
        }
    }
}


