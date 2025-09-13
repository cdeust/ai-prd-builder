import Foundation

// MARK: - Domain-level errors for AppleIntelligenceService and orchestration.
// Keep this separate from low-level client errors (AIError).
public enum IntelligenceError: Error, LocalizedError {
    case capabilityNotAvailable(AppleIntelligenceService.IntelligenceCapability)
    case processingFailed(String)
    case invalidInput
}

// MARK: - LocalizedError
public extension IntelligenceError {
    var errorDescription: String? {
        switch self {
        case .capabilityNotAvailable(let capability):
            return "Capability not available: \(capability)"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}
