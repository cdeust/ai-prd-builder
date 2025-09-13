import Foundation

/// Timeline window
public struct TimelineWindow: Codable, Equatable {
    public var start: String      // ISO date string
    public var end: String        // ISO date string
    public var rationale: String?
    
    public init(start: String = "", end: String = "", rationale: String? = nil) {
        self.start = start
        self.end = end
        self.rationale = rationale
    }
}
