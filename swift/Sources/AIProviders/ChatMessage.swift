import Foundation

public struct ChatMessage: Codable {
    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
