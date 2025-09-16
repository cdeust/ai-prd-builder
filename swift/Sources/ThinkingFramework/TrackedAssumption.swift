import Foundation

/// A tracked assumption with validation status
public struct TrackedAssumption {
    public let id: UUID
    public let statement: String
    public let madeAt: Date
    public let context: String
    public let confidence: Float
    public let category: Category
    public var status: ValidationStatus
    public var evidence: [String]
    public var dependencies: [UUID] // Other assumptions this depends on
    public var impact: ImpactAssessment?

    public init(
        id: UUID = UUID(),
        statement: String,
        madeAt: Date = Date(),
        context: String,
        confidence: Float,
        category: Category,
        status: ValidationStatus = .unverified,
        evidence: [String] = [],
        dependencies: [UUID] = [],
        impact: ImpactAssessment? = nil
    ) {
        self.id = id
        self.statement = statement
        self.madeAt = madeAt
        self.context = context
        self.confidence = confidence
        self.category = category
        self.status = status
        self.evidence = evidence
        self.dependencies = dependencies
        self.impact = impact
    }

    public enum Category {
        case technical      // About code/system behavior
        case business      // About requirements/domain
        case user         // About user behavior
        case performance  // About system performance
        case security    // About security aspects
        case data       // About data structure/flow
    }

    public enum ValidationStatus {
        case unverified
        case verified
        case invalidated
        case partial
        case needsReview
    }

    public struct ImpactAssessment {
        public let scope: ImpactScope
        public let severity: Severity
        public let affectedComponents: [String]
        public let mitigation: String?

        public init(
            scope: ImpactScope,
            severity: Severity,
            affectedComponents: [String],
            mitigation: String?
        ) {
            self.scope = scope
            self.severity = severity
            self.affectedComponents = affectedComponents
            self.mitigation = mitigation
        }

        public enum ImpactScope {
            case local      // Affects single component
            case module     // Affects module/package
            case system     // Affects entire system
            case critical   // Core functionality affected
        }

        public enum Severity {
            case low
            case medium
            case high
            case critical
        }
    }
}