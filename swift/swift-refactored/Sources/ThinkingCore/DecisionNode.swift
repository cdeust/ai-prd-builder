import Foundation

/// A node in the decision tree
public class DecisionNode {
    public let id: UUID
    public let question: String
    public let context: String
    public var options: [Option]
    public var selectedOption: Option?
    public var reasoning: String?
    public let depth: Int
    public weak var parent: DecisionNode?

    public init(
        id: UUID = UUID(),
        question: String,
        context: String,
        depth: Int = 0,
        parent: DecisionNode? = nil
    ) {
        self.id = id
        self.question = question
        self.context = context
        self.options = []
        self.depth = depth
        self.parent = parent
    }

    public struct Option {
        public let id: UUID
        public let description: String
        public let pros: [String]
        public let cons: [String]
        public let probability: Float
        public let risk: RiskLevel
        public var childNode: DecisionNode?

        public init(
            id: UUID = UUID(),
            description: String,
            pros: [String],
            cons: [String],
            probability: Float,
            risk: RiskLevel,
            childNode: DecisionNode? = nil
        ) {
            self.id = id
            self.description = description
            self.pros = pros
            self.cons = cons
            self.probability = probability
            self.risk = risk
            self.childNode = childNode
        }

        public enum RiskLevel {
            case low
            case medium
            case high
            case critical
        }
    }

    /// Add an option to this decision node
    public func addOption(
        description: String,
        pros: [String],
        cons: [String],
        probability: Float,
        risk: Option.RiskLevel
    ) -> Option {
        let option = Option(
            description: description,
            pros: pros,
            cons: cons,
            probability: probability,
            risk: risk
        )
        options.append(option)
        return option
    }
}