import Foundation

/// Represents complexity scoring for features/stories
/// Single Responsibility: Only manages complexity calculations
public struct ComplexityScore: Codable {
    public let totalPoints: Int // Fibonacci: 1,2,3,5,8,13,21,34,55
    public let breakdown: [ComponentComplexity]
    public let factors: [ComplexityFactor]
    public let confidence: Double
    public let analysisDate: Date

    public init(
        totalPoints: Int,
        breakdown: [ComponentComplexity],
        factors: [ComplexityFactor],
        confidence: Double,
        analysisDate: Date = Date()
    ) {
        self.totalPoints = totalPoints
        self.breakdown = breakdown
        self.factors = factors
        self.confidence = confidence
        self.analysisDate = analysisDate
    }

    /// Determines if this story/epic needs breakdown
    public var needsBreakdown: Bool {
        totalPoints > 13
    }

    /// Suggested number of stories to break into
    public var suggestedSplitCount: Int {
        if totalPoints <= 13 { return 1 }
        if totalPoints <= 21 { return 2 }
        if totalPoints <= 34 { return 3 }
        return max(4, totalPoints / 13)
    }

    /// Risk level based on complexity
    public var riskLevel: RiskLevel {
        switch totalPoints {
        case 0...5: return .low
        case 6...13: return .medium
        case 14...21: return .high
        default: return .veryHigh
        }
    }

    public enum RiskLevel: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"

        public var color: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .veryHigh: return "🔴"
            }
        }
    }
}

// MARK: - Component Complexity

extension ComplexityScore {
    public struct ComponentComplexity: Codable {
        public let component: String
        public let points: Int
        public let rationale: String
        public let dependencies: [String]

        public init(
            component: String,
            points: Int,
            rationale: String,
            dependencies: [String] = []
        ) {
            self.component = component
            self.points = points
            self.rationale = rationale
            self.dependencies = dependencies
        }

        /// Validates if points follow Fibonacci sequence
        public var isValidFibonacci: Bool {
            let fibonacciNumbers = [1, 2, 3, 5, 8, 13, 21, 34, 55]
            return fibonacciNumbers.contains(points)
        }
    }
}

// MARK: - Complexity Factor

extension ComplexityScore {
    public struct ComplexityFactor: Codable {
        public let name: String
        public let category: Category
        public let impact: Impact
        public let description: String
        public let mitigation: String?

        public enum Category: String, Codable {
            case technical = "Technical"
            case business = "Business"
            case integration = "Integration"
            case unknown = "Unknown"
        }

        public enum Impact: Int, Codable {
            case minimal = 1
            case low = 2
            case moderate = 3
            case high = 4
            case extreme = 5

            public var multiplier: Double {
                switch self {
                case .minimal: return 1.0
                case .low: return 1.25
                case .moderate: return 1.5
                case .high: return 2.0
                case .extreme: return 3.0
                }
            }
        }

        public init(
            name: String,
            category: Category,
            impact: Impact,
            description: String,
            mitigation: String? = nil
        ) {
            self.name = name
            self.category = category
            self.impact = impact
            self.description = description
            self.mitigation = mitigation
        }
    }
}