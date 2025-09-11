import Foundation

// MARK: - Generic PRD Models (Domain-Agnostic)

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

/// Generic acceptance clause
public struct AcceptanceClause: Codable, Equatable {
    public var title: String
    public var given: String
    public var when: String
    public var then: [String]
    public var performance: String?
    public var observability: [String]?
    
    public init(title: String, given: String, when: String, then: [String], performance: String? = nil, observability: [String]? = nil) {
        self.title = title
        self.given = given
        self.when = when
        self.then = then
        self.performance = performance
        self.observability = observability
    }
}

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

/// Risk item
public struct RiskItem: Codable, Equatable {
    public var name: String
    public var description: String
    public var probability: String    // Low/Medium/High
    public var impact: String         // Low/Medium/High/Critical
    public var mitigation: String
    public var owner: String?
    public var earlyWarning: String?
    
    public init(name: String, description: String, probability: String = "Medium", impact: String = "Medium", 
                mitigation: String, owner: String? = nil, earlyWarning: String? = nil) {
        self.name = name
        self.description = description
        self.probability = probability
        self.impact = impact
        self.mitigation = mitigation
        self.owner = owner
        self.earlyWarning = earlyWarning
    }
}

/// Generic PRD structure
public struct GenericPRD: Codable, Equatable {
    public var executiveSummary: String
    public var problemStatement: String
    public var targetUsers: [String]
    public var functionalRequirements: [String]
    public var nonFunctionalRequirements: [String]
    public var acceptanceCriteria: [AcceptanceClause]
    public var successMetrics: [Metric]
    public var dependencies: [String]
    public var timeline: TimelineWindow
    public var risks: [RiskItem]
    public var observability: [String]
    
    public init(
        executiveSummary: String = "",
        problemStatement: String = "",
        targetUsers: [String] = [],
        functionalRequirements: [String] = [],
        nonFunctionalRequirements: [String] = [],
        acceptanceCriteria: [AcceptanceClause] = [],
        successMetrics: [Metric] = [],
        dependencies: [String] = [],
        timeline: TimelineWindow = TimelineWindow(start: "", end: "", rationale: nil),
        risks: [RiskItem] = [],
        observability: [String] = []
    ) {
        self.executiveSummary = executiveSummary
        self.problemStatement = problemStatement
        self.targetUsers = targetUsers
        self.functionalRequirements = functionalRequirements
        self.nonFunctionalRequirements = nonFunctionalRequirements
        self.acceptanceCriteria = acceptanceCriteria
        self.successMetrics = successMetrics
        self.dependencies = dependencies
        self.timeline = timeline
        self.risks = risks
        self.observability = observability
    }
}

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

// MARK: - Validation Rules

public struct QuestionSpecification {
    public let requireNumbers: Bool
    public let minWords: Int
    
    public static let specifications: [String: QuestionSpecification] = [
        "deal_breakers": QuestionSpecification(requireNumbers: false, minWords: 6),
        "users_count": QuestionSpecification(requireNumbers: true, minWords: 4),
        "success_metric": QuestionSpecification(requireNumbers: true, minWords: 6)
    ]
}