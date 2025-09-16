import Foundation

/// Constants for PRD Generation
public enum PRDGeneratorConstants {

    // MARK: - Phase Numbers
    public enum Phases {
        public static let phase1 = 1
        public static let phase2 = 2
        public static let phase3 = 3
        public static let phase4 = 4
        public static let phase5 = 5
        public static let phase6 = 6
    }

    // MARK: - Feature Management
    public enum FeatureManagement {
        public static let minimumFeatureNameLength = 3
        public static let maximumFeatureNameLength = 50
        public static let minimumLineLength = 15
        public static let minimumConfidenceThreshold: Float = 0.7
        public static let defaultPriority = 0
    }

    // MARK: - Iteration Values
    public enum Iterations {
        public static let firstIteration = 1
        public static let iterationOffset = 1
    }

    // MARK: - Formatting
    public enum Formatting {
        public static let defaultIndentLevel = 1
        public static let indentSpaces = "  "
    }

    // MARK: - Assumptions
    public enum Assumptions {
        public static let defaultAssumptionCount = 0
        public static let noAssumptionsPresent = 0
        public static let defaultConfidenceValue: Float = 0.5
    }

    // MARK: - Array Operations
    public enum ArrayOperations {
        public static let firstElementIndex = 0
        public static let incrementValue = 1
        public static let minimumCount = 1
        public static let dropFirstValue = 1
        public static let colonPresenceMinLength = 2
    }

    // MARK: - Parsing
    public enum Parsing {
        public static let confidenceCharacters = "0123456789%$"
        public static let separatorCharacters: [Character] = ["-", "—", "_", "="]
    }

    // MARK: - Phase Messages
    public enum PhaseMessages {
        public static let phase1 = "Phase 1: Initial Overview with assumption tracking"
        public static let phase2 = "Phase 2: Enhanced Feature Details with assumption validation"
        public static let phase2FeatureProgress = "Feature %d/%d: %@"
        public static let phase3 = "Phase 3: OpenAPI Contract Specification"
        public static let phase4 = "Phase 4: Test Specifications (Apple ecosystem)"
        public static let phase5 = "Phase 5: Technical Requirements"
        public static let phase6 = "Phase 6: Deployment (Apple ecosystem)"
    }

    // MARK: - Research Notes
    public enum ResearchNotes {
        public static let year2025 = "2025"
        public static let bestPracticeComment = "best practice"
        public static let simplifyComment = "avoid over-engineering per 2025 research"
    }
}