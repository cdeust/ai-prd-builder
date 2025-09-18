import Foundation

/// A complete chain of thoughts leading to a conclusion
public struct ThoughtChain {
    public let id: UUID
    public let problem: String
    public let thoughts: [Thought]
    public let conclusion: String
    public let confidence: Float
    public let alternatives: [Alternative]
    public let assumptions: [Assumption]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        problem: String,
        thoughts: [Thought],
        conclusion: String,
        confidence: Float,
        alternatives: [Alternative],
        assumptions: [Assumption],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.problem = problem
        self.thoughts = thoughts
        self.conclusion = conclusion
        self.confidence = confidence
        self.alternatives = alternatives
        self.assumptions = assumptions
        self.timestamp = timestamp
    }

    public struct Alternative {
        public let description: String
        public let probability: Float
        public let pros: [String]
        public let cons: [String]

        public init(
            description: String,
            probability: Float,
            pros: [String],
            cons: [String]
        ) {
            self.description = description
            self.probability = probability
            self.pros = pros
            self.cons = cons
        }
    }
}