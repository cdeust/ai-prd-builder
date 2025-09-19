import Foundation

public struct ChatMessage: Codable, Equatable {
    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }

    public let role: Role
    public let content: String
    public let timestamp: Date?

    public init(role: Role, content: String, timestamp: Date? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

extension ChatMessage: CustomStringConvertible {
    public var description: String {
        "[\(role.rawValue)]: \(content.prefix(100))..."
    }
}