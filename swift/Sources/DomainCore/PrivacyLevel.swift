import Foundation

public enum PrivacyLevel: Int, Comparable, Codable {
    case onDevice = 1
    case privateCloud = 2
    case external = 3

    public var description: String {
        switch self {
        case .onDevice:
            return "On-Device (Maximum Privacy)"
        case .privateCloud:
            return "Private Cloud Compute"
        case .external:
            return "External API"
        }
    }

    public static func < (lhs: PrivacyLevel, rhs: PrivacyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}