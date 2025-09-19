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

public enum ValidationError: LocalizedError {
    case missingRequired(field: String)
    case invalidFormat(field: String, expected: String)
    case outOfRange(field: String, min: Any?, max: Any?)
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequired(let field):
            return "Missing required field: \(field)"
        case .invalidFormat(let field, let expected):
            return "Invalid format for \(field), expected: \(expected)"
        case .outOfRange(let field, let min, let max):
            var msg = "Value for \(field) out of range"
            if let min = min, let max = max {
                msg += " (\(min) - \(max))"
            }
            return msg
        case .custom(let message):
            return message
        }
    }
}