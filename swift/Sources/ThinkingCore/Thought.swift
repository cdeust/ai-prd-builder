import Foundation

/// Represents a single thought in the reasoning chain
public struct Thought {
    public let id: UUID
    public let content: String
    public let type: ThoughtType
    public let confidence: Float
    public let timestamp: Date
    public let parent: UUID?
    public let children: [UUID]

    public init(
        id: UUID = UUID(),
        content: String,
        type: ThoughtType,
        confidence: Float,
        timestamp: Date = Date(),
        parent: UUID? = nil,
        children: [UUID] = []
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.confidence = confidence
        self.timestamp = timestamp
        self.parent = parent
        self.children = children
    }

    public enum ThoughtType {
        case observation      // What I see
        case assumption      // What I assume
        case reasoning       // How I connect ideas
        case question       // What I need to know
        case conclusion     // What I decide
        case warning       // Potential issues
        case alternative   // Other possibilities
    }
}