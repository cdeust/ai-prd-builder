import Foundation

/// Generic metric structure
public struct Metric: Codable, Equatable {
    public var name: String
    public var unit: String        // e.g., "percent", "seconds", "count", "currency"
    public var baseline: String    // String for flexibility
    public var target: String
    public var timeframe: String   // e.g., "by GA", "90 days", "Q3 2026"
    
    public init(name: String, unit: String = "count", baseline: String = "0", target: String = "1", timeframe: String = "by launch") {
        self.name = name
        self.unit = unit
        self.baseline = baseline
        self.target = target
        self.timeframe = timeframe
    }
}
