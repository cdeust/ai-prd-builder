import Foundation

/// Plan for validating assumptions in priority order
public struct ValidationPlan {
    public let priority1: [TrackedAssumption] // Critical assumptions
    public let priority2: [TrackedAssumption] // High impact
    public let priority3: [TrackedAssumption] // Has dependents
    public let priority4: [TrackedAssumption] // Others

    public init(
        priority1: [TrackedAssumption],
        priority2: [TrackedAssumption],
        priority3: [TrackedAssumption],
        priority4: [TrackedAssumption]
    ) {
        self.priority1 = priority1
        self.priority2 = priority2
        self.priority3 = priority3
        self.priority4 = priority4
    }
}