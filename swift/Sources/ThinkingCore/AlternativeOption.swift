import Foundation

/// Represents an alternative option when confidence is low
public struct AlternativeOption {
    public let id: UUID
    public let description: String
    public let pros: [String]
    public let cons: [String]
    public let probabilityOfSuccess: Float
    public let recommendationReason: String?
    public let estimatedEffort: EffortLevel?
    public let riskLevel: RiskLevel?

    public init(
        id: UUID = UUID(),
        description: String,
        pros: [String],
        cons: [String],
        probabilityOfSuccess: Float,
        recommendationReason: String? = nil,
        estimatedEffort: EffortLevel? = nil,
        riskLevel: RiskLevel? = nil
    ) {
        self.id = id
        self.description = description
        self.pros = pros
        self.cons = cons
        self.probabilityOfSuccess = min(max(probabilityOfSuccess, 0), 1) // Clamp between 0 and 1
        self.recommendationReason = recommendationReason
        self.estimatedEffort = estimatedEffort
        self.riskLevel = riskLevel
    }

    /// Effort level for implementing the alternative
    public enum EffortLevel: String, CaseIterable {
        case trivial = "Trivial"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"

        public var timeEstimate: String {
            switch self {
            case .trivial: return "< 1 day"
            case .low: return "1-3 days"
            case .medium: return "3-7 days"
            case .high: return "1-2 weeks"
            case .veryHigh: return "> 2 weeks"
            }
        }
    }

    /// Risk level associated with the alternative
    public enum RiskLevel: String, CaseIterable {
        case minimal = "Minimal"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case critical = "Critical"

        public var color: String {
            switch self {
            case .minimal: return "🟢"
            case .low: return "🟡"
            case .moderate: return "🟠"
            case .high: return "🔴"
            case .critical: return "⚫"
            }
        }
    }

    /// Calculate a weighted score for ranking alternatives
    public var score: Float {
        let successWeight: Float = 0.4
        let prosWeight: Float = 0.3
        let consWeight: Float = 0.2
        let effortWeight: Float = 0.1

        let prosScore = Float(pros.count) / 10.0 // Normalize to 0-1 (assuming max 10 pros)
        let consScore = 1.0 - (Float(cons.count) / 10.0) // Inverse, fewer cons is better

        let effortScore: Float
        switch estimatedEffort {
        case .trivial: effortScore = 1.0
        case .low: effortScore = 0.8
        case .medium: effortScore = 0.6
        case .high: effortScore = 0.4
        case .veryHigh: effortScore = 0.2
        case .none: effortScore = 0.5 // Neutral if unknown
        }

        return (probabilityOfSuccess * successWeight) +
               (prosScore * prosWeight) +
               (consScore * consWeight) +
               (effortScore * effortWeight)
    }

    /// Generate a recommendation based on the alternative's properties
    public var recommendation: String {
        if let reason = recommendationReason {
            return reason
        }

        if probabilityOfSuccess > 0.7 && cons.count <= 2 {
            return "Highly recommended - high success probability with minimal drawbacks"
        } else if probabilityOfSuccess > 0.5 && pros.count > cons.count {
            return "Recommended - benefits outweigh risks"
        } else if probabilityOfSuccess < 0.3 {
            return "Not recommended - low probability of success"
        } else if cons.count > pros.count * 2 {
            return "Not recommended - too many disadvantages"
        } else {
            return "Consider carefully - balanced trade-offs"
        }
    }

    /// Format the alternative as a readable string
    public var formattedDescription: String {
        var output = "Alternative: \(description)\n"
        output += "Success Probability: \(String(format: "%.1f%%", probabilityOfSuccess * 100))\n"

        if let effort = estimatedEffort {
            output += "Effort: \(effort.rawValue) (\(effort.timeEstimate))\n"
        }

        if let risk = riskLevel {
            output += "Risk: \(risk.color) \(risk.rawValue)\n"
        }

        if !pros.isEmpty {
            output += "Pros:\n"
            for pro in pros {
                output += "  ✓ \(pro)\n"
            }
        }

        if !cons.isEmpty {
            output += "Cons:\n"
            for con in cons {
                output += "  ✗ \(con)\n"
            }
        }

        output += "Recommendation: \(recommendation)\n"
        output += "Score: \(String(format: "%.2f", score))"

        return output
    }
}

// MARK: - Comparable for sorting alternatives
extension AlternativeOption: Comparable {
    public static func < (lhs: AlternativeOption, rhs: AlternativeOption) -> Bool {
        return lhs.score < rhs.score
    }

    public static func == (lhs: AlternativeOption, rhs: AlternativeOption) -> Bool {
        return lhs.id == rhs.id
    }
}