import Foundation

/// Represents technical challenges that could impact the project
/// Single Responsibility: Only models technical challenges and risks
public struct TechnicalChallenge: Codable, Identifiable {
    public let id: UUID
    public let category: Category
    public let title: String
    public let description: String
    public let relatedRequirement: String?  // The exact quoted requirement text that causes this challenge
    public let probability: Probability
    public let impact: Impact
    public let detectionPoint: DetectionPoint
    public let preventiveMeasures: [PreventiveMeasure]
    public let identifiedAt: Date

    public init(
        id: UUID = UUID(),
        category: Category,
        title: String,
        description: String,
        relatedRequirement: String? = nil,
        probability: Probability,
        impact: Impact,
        detectionPoint: DetectionPoint,
        preventiveMeasures: [PreventiveMeasure] = [],
        identifiedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.relatedRequirement = relatedRequirement
        self.probability = probability
        self.impact = impact
        self.detectionPoint = detectionPoint
        self.preventiveMeasures = preventiveMeasures
        self.identifiedAt = identifiedAt
    }

    /// Risk score combining probability and impact
    public var riskScore: Int {
        probability.score * impact.severity.score
    }

    /// Priority based on risk score
    public var priority: Priority {
        switch riskScore {
        case 0...25: return .low
        case 26...50: return .medium
        case 51...75: return .high
        default: return .critical
        }
    }

    public enum Priority: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"

        public var emoji: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .critical: return "🔴"
            }
        }
    }
}

// MARK: - Category

extension TechnicalChallenge {
    public enum Category: String, Codable, CaseIterable {
        case performance = "Performance"
        case security = "Security"
        case scalability = "Scalability"
        case integration = "Integration"
        case compliance = "Compliance"
        case complexity = "Complexity"
        case maintenance = "Maintenance"
        case compatibility = "Compatibility"
        case reliability = "Reliability"
        case usability = "Usability"

        public var icon: String {
            switch self {
            case .performance: return "⚡"
            case .security: return "🔒"
            case .scalability: return "📈"
            case .integration: return "🔗"
            case .compliance: return "📋"
            case .complexity: return "🧩"
            case .maintenance: return "🔧"
            case .compatibility: return "🔄"
            case .reliability: return "✅"
            case .usability: return "👤"
            }
        }
    }
}

// MARK: - Probability

extension TechnicalChallenge {
    public struct Probability: Codable {
        public let value: Double // 0.0 - 1.0
        public let confidence: Double // 0.0 - 1.0
        public let rationale: String

        public init(value: Double, confidence: Double = 0.8, rationale: String = "") {
            self.value = min(1.0, max(0.0, value))
            self.confidence = min(1.0, max(0.0, confidence))
            self.rationale = rationale
        }

        public var level: Level {
            switch value {
            case 0..<0.25: return .veryLow
            case 0.25..<0.5: return .low
            case 0.5..<0.75: return .medium
            case 0.75..<0.9: return .high
            default: return .veryHigh
            }
        }

        public var score: Int {
            switch level {
            case .veryLow: return 1
            case .low: return 2
            case .medium: return 3
            case .high: return 4
            case .veryHigh: return 5
            }
        }

        public enum Level: String {
            case veryLow = "Very Low"
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case veryHigh = "Very High"
        }

        public var percentage: String {
            "\(Int(value * 100))%"
        }
    }
}

// MARK: - Impact

extension TechnicalChallenge {
    public struct Impact: Codable {
        public let severity: Severity
        public let scope: Scope
        public let duration: Duration
        public let description: String

        public enum Severity: String, Codable {
            case minimal = "Minimal"
            case low = "Low"
            case moderate = "Moderate"
            case high = "High"
            case critical = "Critical"

            public var score: Int {
                switch self {
                case .minimal: return 1
                case .low: return 2
                case .moderate: return 3
                case .high: return 4
                case .critical: return 5
                }
            }
        }

        public enum Scope: String, Codable {
            case isolated = "Isolated"      // Single component
            case limited = "Limited"        // Few components
            case moderate = "Moderate"      // Multiple components
            case widespread = "Widespread"  // Most components
            case system = "System-wide"     // Entire system
        }

        public enum Duration: String, Codable {
            case temporary = "Temporary"
            case shortTerm = "Short-term"
            case mediumTerm = "Medium-term"
            case longTerm = "Long-term"
            case permanent = "Permanent"
        }

        public init(
            severity: Severity,
            scope: Scope,
            duration: Duration,
            description: String
        ) {
            self.severity = severity
            self.scope = scope
            self.duration = duration
            self.description = description
        }
    }
}

// MARK: - Detection Point

extension TechnicalChallenge {
    public enum DetectionPoint: String, Codable {
        case planning = "Planning"
        case design = "Design"
        case development = "Development"
        case testing = "Testing"
        case staging = "Staging"
        case deployment = "Deployment"
        case production = "Production"
        case scale = "At Scale"

        public var phase: String {
            switch self {
            case .planning, .design: return "Pre-Development"
            case .development, .testing: return "Development"
            case .staging, .deployment: return "Pre-Production"
            case .production, .scale: return "Production"
            }
        }

        public var costToFix: String {
            switch self {
            case .planning: return "1x"
            case .design: return "3x"
            case .development: return "5x"
            case .testing: return "10x"
            case .staging: return "15x"
            case .deployment: return "25x"
            case .production: return "50x"
            case .scale: return "100x"
            }
        }
    }
}

// MARK: - Preventive Measure

extension TechnicalChallenge {
    public struct PreventiveMeasure: Codable {
        public let action: String
        public let complexity: Int // Story points
        public let effectiveness: Effectiveness
        public let requiredExpertise: [String]

        public enum Effectiveness: String, Codable {
            case low = "Low"
            case moderate = "Moderate"
            case high = "High"
            case veryHigh = "Very High"

            public var reductionPercentage: String {
                switch self {
                case .low: return "10-25%"
                case .moderate: return "25-50%"
                case .high: return "50-75%"
                case .veryHigh: return "75-95%"
                }
            }
        }

        public init(
            action: String,
            complexity: Int,
            effectiveness: Effectiveness,
            requiredExpertise: [String] = []
        ) {
            self.action = action
            self.complexity = complexity
            self.effectiveness = effectiveness
            self.requiredExpertise = requiredExpertise
        }
    }
}