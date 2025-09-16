import Foundation

/// Errors that can occur during PRD generation
public enum PRDError: Error, LocalizedError {
    case reasoningFailed(String)
    case openAPIValidationFailed(String)
    case featureExtractionFailed(String)
    case assumptionValidationFailed(String)
    case insufficientConfidence(String)

    public var errorDescription: String? {
        switch self {
        case .reasoningFailed(let message):
            return PRDConstants.ErrorMessages.reasoningFailedPrefix + message
        case .openAPIValidationFailed(let message):
            return PRDConstants.ErrorMessages.openAPIValidationFailedPrefix + message
        case .featureExtractionFailed(let message):
            return PRDConstants.ErrorMessages.featureExtractionFailedPrefix + message
        case .assumptionValidationFailed(let message):
            return PRDConstants.ErrorMessages.assumptionValidationFailedPrefix + message
        case .insufficientConfidence(let message):
            return PRDConstants.ErrorMessages.insufficientConfidencePrefix + message
        }
    }
}