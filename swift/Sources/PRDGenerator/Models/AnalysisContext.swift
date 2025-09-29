import Foundation

/// Context object containing all information needed for analysis
/// Follows Single Responsibility: Only manages analysis context data
public struct AnalysisContext {
    public let requirements: String
    public let enrichedInput: String?
    public let technicalStack: [String]
    public let targetPlatforms: [String]
    public let constraints: [String]
    public let previousAnalysis: [String: Any]?
    public let metadata: AnalysisMetadata

    public init(
        requirements: String,
        enrichedInput: String? = nil,
        technicalStack: [String] = [],
        targetPlatforms: [String] = [],
        constraints: [String] = [],
        previousAnalysis: [String: Any]? = nil,
        metadata: AnalysisMetadata = AnalysisMetadata()
    ) {
        self.requirements = requirements
        self.enrichedInput = enrichedInput
        self.technicalStack = technicalStack
        self.targetPlatforms = targetPlatforms
        self.constraints = constraints
        self.previousAnalysis = previousAnalysis
        self.metadata = metadata
    }
}

/// Metadata about the analysis request
public struct AnalysisMetadata {
    public let timestamp: Date
    public let requestId: UUID
    public let depth: AnalysisDepth

    public enum AnalysisDepth {
        case shallow
        case standard
        case deep
        case comprehensive
    }

    public init(
        timestamp: Date = Date(),
        requestId: UUID = UUID(),
        depth: AnalysisDepth = .standard
    ) {
        self.timestamp = timestamp
        self.requestId = requestId
        self.depth = depth
    }
}