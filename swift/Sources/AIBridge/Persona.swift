import Foundation

public protocol PersonaProfile {
    var name: String { get }
    var availabilitySLO: Double { get }      // e.g., 99.9 or 99.99
    var securityEmphasis: Bool { get }       // compliance posture emphasis
    var latencySensitivityMs: Int { get }    // p95 user-facing target
    var adoptionAggressiveness: Int { get }  // 1..3 (1=conservative, 3=aggressive)
}
