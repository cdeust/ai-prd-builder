import Foundation
import CommonModels

public struct Session: Identifiable, Codable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var messages: [ChatMessage]
    public var metadata: SessionMetadata

    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        messages: [ChatMessage] = [],
        metadata: SessionMetadata = SessionMetadata()
    ) {
        self.id = id
        self.startTime = startTime
        self.messages = messages
        self.metadata = metadata
    }

    public mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        metadata.messageCount = messages.count
        metadata.lastActivity = Date()
    }

    public mutating func end() {
        endTime = Date()
        metadata.isActive = false
    }
}

public struct SessionMetadata: Codable {
    public var title: String
    public var description: String
    public var tags: [String]
    public var messageCount: Int
    public var lastActivity: Date
    public var isActive: Bool

    public init(
        title: String = "New Session",
        description: String = "",
        tags: [String] = [],
        messageCount: Int = 0,
        lastActivity: Date = Date(),
        isActive: Bool = true
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.messageCount = messageCount
        self.lastActivity = lastActivity
        self.isActive = isActive
    }
}