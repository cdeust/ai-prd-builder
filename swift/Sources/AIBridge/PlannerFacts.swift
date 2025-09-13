import Foundation

// MARK: - Planner Facts Structure

public struct PlannerFacts: Codable {
    public var goals: [String]?
    public var mustHaves: [String]?
    public var nonFunctionals: [String]?
    public var metrics: [Metric]?
    public var dependencies: [String]?
    public var risks: [RiskItem]?
    public var timelineHint: String?
    
    enum CodingKeys: String, CodingKey {
        case goals
        case mustHaves = "must_haves"
        case nonFunctionals = "non_functionals"
        case metrics
        case dependencies
        case risks
        case timelineHint = "timeline_hint"
    }
}
