import Foundation

/// Represents a validation constraint for OpenAPI specifications
public struct ValidationConstraint {
    public let type: ConstraintType
    public let path: String
    public let message: String
    public let severity: ConstraintSeverity

    public init(
        type: ConstraintType,
        path: String = "",
        message: String,
        severity: ConstraintSeverity = .medium
    ) {
        self.type = type
        self.path = path
        self.message = message
        self.severity = severity
    }

    /// Convert to string representation
    public var description: String {
        return "\(type.rawValue): \(message)"
    }
}

/// Types of constraints
public enum ConstraintType: String {
    case required = "REQUIRED"
    case format = "FORMAT"
    case reference = "REFERENCE"
    case schema = "SCHEMA"
    case security = "SECURITY"
    case version = "VERSION"
    case operation = "OPERATION"
    case path = "PATH"
    case response = "RESPONSE"
    case parameter = "PARAMETER"
}