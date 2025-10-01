import Foundation

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
