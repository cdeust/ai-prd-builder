import Foundation

/// Represents a contradiction between two assumptions
public struct Contradiction {
    public let assumption1: UUID
    public let assumption2: UUID
    public let conflict: String
    public let resolution: String

    public init(
        assumption1: UUID,
        assumption2: UUID,
        conflict: String,
        resolution: String
    ) {
        self.assumption1 = assumption1
        self.assumption2 = assumption2
        self.conflict = conflict
        self.resolution = resolution
    }
}