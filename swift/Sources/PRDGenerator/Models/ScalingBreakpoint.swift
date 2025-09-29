import Foundation

/// Represents points where system architecture needs to change for scale
/// Single Responsibility: Only models scaling limitations and breakpoints
public struct ScalingBreakpoint: Codable, Identifiable {
    public let id: UUID
    public let metric: ScalingMetric
    public let threshold: Threshold
    public let impact: Impact
    public let mitigation: Mitigation
    public let detectedAt: Date

    public init(
        id: UUID = UUID(),
        metric: ScalingMetric,
        threshold: Threshold,
        impact: Impact,
        mitigation: Mitigation,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.metric = metric
        self.threshold = threshold
        self.impact = impact
        self.mitigation = mitigation
        self.detectedAt = detectedAt
    }

    /// Complexity added if this breakpoint is hit
    public var complexityMultiplier: Double {
        switch impact.severity {
        case 1...3: return 1.5
        case 4...6: return 2.0
        case 7...8: return 3.0
        case 9...10: return 5.0
        default: return 1.0
        }
    }
}

// MARK: - Scaling Metric

extension ScalingBreakpoint {
    public struct ScalingMetric: Codable {
        public let name: String
        public let unit: String
        public let measurementType: MeasurementType
        public let currentValue: Double?

        public enum MeasurementType: String, Codable {
            case users = "Users"
            case requests = "Requests"
            case data = "Data"
            case connections = "Connections"
            case transactions = "Transactions"
            case bandwidth = "Bandwidth"
            case storage = "Storage"
            case compute = "Compute"

            public var icon: String {
                switch self {
                case .users: return "👥"
                case .requests: return "📡"
                case .data: return "💾"
                case .connections: return "🔌"
                case .transactions: return "💳"
                case .bandwidth: return "📊"
                case .storage: return "🗄️"
                case .compute: return "🖥️"
                }
            }
        }

        public init(
            name: String,
            unit: String,
            measurementType: MeasurementType,
            currentValue: Double? = nil
        ) {
            self.name = name
            self.unit = unit
            self.measurementType = measurementType
            self.currentValue = currentValue
        }

        public var formattedValue: String {
            guard let value = currentValue else { return "Unknown" }
            return "\(Int(value)) \(unit)"
        }
    }
}

// MARK: - Threshold

extension ScalingBreakpoint {
    public struct Threshold: Codable {
        public let value: Double
        public let unit: String
        public let condition: Condition

        public enum Condition: String, Codable {
            case exceeds = "Exceeds"
            case reaches = "Reaches"
            case approaches = "Approaches"
            case sustains = "Sustains"
        }

        public init(value: Double, unit: String, condition: Condition = .exceeds) {
            self.value = value
            self.unit = unit
            self.condition = condition
        }

        public var description: String {
            "\(condition.rawValue) \(Int(value)) \(unit)"
        }
    }
}

// MARK: - Impact

extension ScalingBreakpoint {
    public struct Impact: Codable {
        public let description: String
        public let severity: Int // 1-10
        public let affectedComponents: [String]
        public let userExperience: UserExperienceImpact

        public enum UserExperienceImpact: String, Codable {
            case none = "None"
            case minor = "Minor"
            case degraded = "Degraded"
            case major = "Major"
            case failure = "Failure"

            public var color: String {
                switch self {
                case .none: return "🟢"
                case .minor: return "🟡"
                case .degraded: return "🟠"
                case .major: return "🔴"
                case .failure: return "⚫"
                }
            }
        }

        public init(
            description: String,
            severity: Int,
            affectedComponents: [String],
            userExperience: UserExperienceImpact
        ) {
            self.description = description
            self.severity = min(10, max(1, severity))
            self.affectedComponents = affectedComponents
            self.userExperience = userExperience
        }
    }
}

// MARK: - Mitigation

extension ScalingBreakpoint {
    public struct Mitigation: Codable {
        public let strategy: String
        public let requiredChanges: [RequiredChange]
        public let estimatedComplexity: Int // Story points
        public let preventive: Bool

        public struct RequiredChange: Codable {
            public let component: String
            public let changeType: ChangeType
            public let description: String

            public enum ChangeType: String, Codable {
                case architecture = "Architecture"
                case infrastructure = "Infrastructure"
                case codeRefactor = "Code Refactor"
                case configuration = "Configuration"
                case database = "Database"
                case caching = "Caching"
                case algorithm = "Algorithm"
            }
        }

        public init(
            strategy: String,
            requiredChanges: [RequiredChange],
            estimatedComplexity: Int,
            preventive: Bool = false
        ) {
            self.strategy = strategy
            self.requiredChanges = requiredChanges
            self.estimatedComplexity = estimatedComplexity
            self.preventive = preventive
        }
    }
}