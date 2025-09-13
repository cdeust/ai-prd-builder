import Foundation

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
