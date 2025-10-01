import Foundation

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
