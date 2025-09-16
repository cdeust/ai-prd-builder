import Foundation

/// Constants for Reasoning Engine operations
public enum ReasoningConstants {

    // MARK: - Iterations and Paths
    public enum Iterations {
        public static let selfConsistencyThreshold = 3
        public static let minPaths = 1
        public static let maxPaths = 3
        public static let pathReductionFactor = 6
        public static let constraintApplicationThreshold = 2
        public static let exampleRequestThreshold = 3
    }

    // MARK: - Confidence Values
    public enum Confidence {
        public static let lowConfidenceThreshold: Float = 0.6
        public static let thoughtCountBonus: Float = 0.05
        public static let assumptionBonus: Float = 0.05
        public static let iterationBonus: Float = 0.02
        public static let alternativePathBonus: Float = 0.1
        public static let maxConfidence: Float = 1.0
        public static let minThoughtCount = 3
        public static let maxAssumptionCount = 3
    }

    // MARK: - Reasoning Approaches
    public enum Approaches {
        public static let all = [
            "systematic analysis",
            "first principles thinking",
            "comparative analysis",
            "user-centric perspective",
            "technical feasibility focus",
            "business value analysis",
            "risk assessment approach",
            "iterative refinement"
        ]

        public static let refinedSuffix = " (refined)"
    }

    // MARK: - Constraints
    public enum Constraints {
        public static let focusOnEvidence = "Focus on concrete evidence"
        public static let provideExamples = "Provide specific examples"
        public static let quantifyResults = "Quantify where possible"

        public static let iterationConstraints = [
            focusOnEvidence,
            provideExamples,
            quantifyResults
        ]
    }

    // MARK: - Problem Building
    public enum ProblemBuilding {
        public static let lowConfidenceMessage = "\n\nThe previous analysis had low confidence. Let's reconsider the problem using %@."
        public static let buildingOnMessage = "\n\nBuilding on: "
        public static let approachMessage = "\n\nApproach: %@"
        public static let stepByStepMessage = "\n\nLet's think step by step."
        public static let stepByStepWithExamplesMessage = "\n\nLet's think step by step with concrete examples."
        public static let conclusionPrefixLength = 200
    }

    // MARK: - String Limits
    public enum StringLimits {
        public static let conclusionPrefixLength = 200
    }
}