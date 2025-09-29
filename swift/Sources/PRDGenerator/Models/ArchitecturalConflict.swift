import Foundation

/// Represents a conflict between architectural requirements
/// Single Responsibility: Only models architectural conflicts
public struct ArchitecturalConflict: Codable, Equatable {
    public let id: UUID
    public let requirement1: String
    public let requirement2: String
    public let conflictType: ConflictType
    public let severity: Severity
    public let resolution: ResolutionStrategy
    public let realWorldExamples: [RealWorldExample]

    public init(
        id: UUID = UUID(),
        requirement1: String,
        requirement2: String,
        conflictType: ConflictType,
        severity: Severity,
        resolution: ResolutionStrategy,
        realWorldExamples: [RealWorldExample] = []
    ) {
        self.id = id
        self.requirement1 = requirement1
        self.requirement2 = requirement2
        self.conflictType = conflictType
        self.severity = severity
        self.resolution = resolution
        self.realWorldExamples = realWorldExamples
    }
}

// MARK: - Nested Types

extension ArchitecturalConflict {
    public enum ConflictType: String, Codable, CaseIterable {
        case mutuallyExclusive = "mutually_exclusive"
        case performanceVsFeature = "performance_vs_feature"
        case securityVsUsability = "security_vs_usability"
        case scaleVsSimplicity = "scale_vs_simplicity"
        case costVsQuality = "cost_vs_quality"
        case realtimeVsOffline = "realtime_vs_offline"
        case privacyVsFunctionality = "privacy_vs_functionality"

        public var description: String {
            switch self {
            case .mutuallyExclusive: return "Requirements cannot coexist"
            case .performanceVsFeature: return "Feature impacts performance"
            case .securityVsUsability: return "Security reduces usability"
            case .scaleVsSimplicity: return "Scale requires complexity"
            case .costVsQuality: return "Quality increases cost"
            case .realtimeVsOffline: return "Real-time conflicts with offline"
            case .privacyVsFunctionality: return "Privacy limits functionality"
            }
        }
    }

    public enum Severity: Int, Codable, Comparable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public var emoji: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .critical: return "🔴"
            }
        }
    }

    public struct ResolutionStrategy: Codable, Equatable {
        public let approach: String
        public let tradeoffs: [String]
        public let recommendation: String
        public let alternativeOptions: [String]
        public let decisionCriteria: [String]

        public init(
            approach: String,
            tradeoffs: [String],
            recommendation: String,
            alternativeOptions: [String] = [],
            decisionCriteria: [String] = []
        ) {
            self.approach = approach
            self.tradeoffs = tradeoffs
            self.recommendation = recommendation
            self.alternativeOptions = alternativeOptions
            self.decisionCriteria = decisionCriteria
        }
    }

    public struct RealWorldExample: Codable, Equatable {
        public let company: String
        public let product: String
        public let solution: String
        public let outcome: String

        public init(
            company: String,
            product: String,
            solution: String,
            outcome: String
        ) {
            self.company = company
            self.product = product
            self.solution = solution
            self.outcome = outcome
        }
    }
}