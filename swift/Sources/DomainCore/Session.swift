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


