import Foundation

public protocol HardwareProfile {
    var cpuTier: String { get }                // e.g., "M2 Pro", "M1", "Intel"
    var expectedP95LatencyMs: Int { get }      // indicative p95 latency budget
    var throughputGuidance: Int { get }        // indicative req/sec or ops/sec
    var availabilityFloor: Double { get }      // infra/platform availability expectation
}

public struct DefaultHardwareProfile: HardwareProfile {
    public let cpuTier: String
    public let expectedP95LatencyMs: Int
    public let throughputGuidance: Int
    public let availabilityFloor: Double
    
    public init(
        cpuTier: String = "M2 Pro",
        expectedP95LatencyMs: Int = 200,
        throughputGuidance: Int = 1000,
        availabilityFloor: Double = 99.9
    ) {
        self.cpuTier = cpuTier
        self.expectedP95LatencyMs = expectedP95LatencyMs
        self.throughputGuidance = throughputGuidance
        self.availabilityFloor = availabilityFloor
    }
}
