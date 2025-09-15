import Foundation

public enum AIProviderError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case rateLimitExceeded
    case tokenLimitExceeded
    case serverError(String)
    case invalidInput
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return AIProviderConstants.ErrorMessages.notConfigured
        case .invalidAPIKey:
            return AIProviderConstants.ErrorMessages.invalidAPIKey
        case .networkError(let message):
            return String(format: AIProviderConstants.ErrorMessages.networkErrorFormat, message)
        case .invalidResponse:
            return AIProviderConstants.ErrorMessages.invalidResponse
        case .rateLimitExceeded:
            return AIProviderConstants.ErrorMessages.rateLimitExceeded
        case .tokenLimitExceeded:
            return AIProviderConstants.ErrorMessages.tokenLimitExceeded
        case .serverError(let message):
            return String(format: AIProviderConstants.ErrorMessages.serverErrorFormat, message)
        case .invalidInput:
            return AIProviderConstants.ErrorMessages.invalidInput
        case .executionFailed(let message):
            return message
        }
    }
}
