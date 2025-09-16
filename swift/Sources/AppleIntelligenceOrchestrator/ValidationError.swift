import Foundation

/// Errors that can occur during validation
public enum ValidationError: Error, LocalizedError {
    case noValidPathFound
    case initializationFailed
    case invalidSpecification(String)
    case missingRequiredField(String)
    case invalidFormat(String)
    case constraintViolation(String)
    case parsingError(String)
    case schemaValidationFailed(String)
    case securityValidationFailed(String)
    case operationValidationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noValidPathFound:
            return "No valid path found during validation"
        case .initializationFailed:
            return "Failed to initialize validation process"
        case .invalidSpecification(let reason):
            return "Invalid specification: \(reason)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidFormat(let format):
            return "Invalid format: \(format)"
        case .constraintViolation(let constraint):
            return "Constraint violation: \(constraint)"
        case .parsingError(let error):
            return "Parsing error: \(error)"
        case .schemaValidationFailed(let reason):
            return "Schema validation failed: \(reason)"
        case .securityValidationFailed(let reason):
            return "Security validation failed: \(reason)"
        case .operationValidationFailed(let reason):
            return "Operation validation failed: \(reason)"
        }
    }
}