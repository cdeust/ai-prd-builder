import Foundation

/// Constants for analysis, validation, and context detection
public enum PRDAnalysisConstants {

    // MARK: - Analysis Messages
    public enum AnalysisMessages {
        public static let analyzingCompleteness = "\n🔍 Analyzing requirements and technical stack for completeness..."
        public static let confidenceTooLow = "\n⚠️ Initial analysis confidence is too low (%d%). The requirements are too vague to generate a meaningful PRD."
        public static let clarificationIdentified = "\n🤔 I've identified some areas that need clarification for a complete PRD:"
        public static let confidenceLevels = "\n📊 **Confidence Levels:**"
        public static let requirementsConfidence = "  - Requirements: %d%%"
        public static let stackConfidence = "  - Technical Stack: %d%%"
        public static let requirementsClarificationsHeader = "\n📋 **Requirements Clarifications:**"
        public static let stackClarificationsHeader = "\n🔧 **Technical Stack Clarifications:**"
        public static let collectingClarifications = "\n📝 Let's clarify these points:"
        public static let reanalyzing = "\n🔄 Re-analyzing with provided clarifications..."
        public static let confidenceImproved = "✅ Confidence improved: %d%% → %d%%"
        public static let essentialInfoRequired = "\n🔴 **Essential Information Required:**"
        public static let cannotProceedWithoutInfo = "\nI cannot proceed without this information. Please provide answers:"
        public static let foundAssumptions = "       Found %d assumptions"
        public static let missingInfoHeader = "\n   Missing information:"
        public static let missingInfoItem = "   • %@"
        public static let lowConfidenceFormat = "Low confidence (%d%%) detected for %@"
    }

    // MARK: - Validation Messages
    public enum ValidationMessages {
        public static let noDataModelChanges = "No data model changes required"
        public static let usesExistingAPI = "Uses existing API operations"
        public static let noAdditionalConstraints = "No additional constraints. Follows existing system standards."
    }

    // MARK: - Question Categories
    public enum QuestionCategories {
        public static let language = ["language", "programming", "code", "develop"]
        public static let testing = ["test", "testing", "qa", "quality"]
        public static let database = ["database", "storage", "data", "persist"]
        public static let deployment = ["deploy", "pipeline", "ci/cd", "cicd", "continuous", "integration", "delivery"]
        public static let security = ["security", "auth", "compliance", "privacy", "gdpr", "encryption"]
        public static let performance = ["performance", "speed", "latency", "throughput", "scale"]
        public static let integration = ["integrate", "api", "service", "connect", "third-party"]
    }

    // MARK: - Essential Questions
    public enum EssentialQuestions {
        public static let primaryLanguage = "primary programming language"
        public static let deploymentTarget = "deployment target"
        public static let userBase = "target users"
        public static let coreFeature = "core functionality"
    }

    // MARK: - Weak Language Indicators
    public enum WeakLanguageIndicators {
        public static let vague = ["something", "stuff", "things", "various", "etc", "and so on"]
        public static let uncertain = ["maybe", "perhaps", "possibly", "might", "could", "should"]
        public static let incomplete = ["tbd", "todo", "later", "figure out", "not sure"]
        public static let assumptions = ["probably", "likely", "assume", "guess", "think"]
    }

    // MARK: - Stack Context Formatting
    public enum StackFormatting {
        public static let stackContextTag = "\n\n<stack_context>\nLanguage: %@\nDatabase: %@\nSecurity: %@\n</stack_context>"
        public static let testContextTag = "\n\n<test_context>Test Framework: %@\n</test_context>"
        public static let cicdContextTag = "\n\n<cicd_context>\nPipeline: %@\nDeployment: %@\n</cicd_context>"
        public static let useXCTestFormat = "Use XCTest format"
        public static let useFrameworkFormat = "Use %@ format"
        public static let stackDescription = "Language: %@, Database: %@, Security: %@"
    }

    // MARK: - Guideline Markers
    public enum GuidelineMarkers {
        public static let markers = ["guidelines:", "design guidelines:", "ux guidelines:", "ui specs:", "design specs:"]
    }

    // MARK: - Clipboard Indicators
    public enum ClipboardIndicators {
        public static let clipboard = "<clipboard"
        public static let imageMarker = "[image:"
        public static let pastedImage = "[image:"
        public static let clipboardRef = "<clipboard:image>"
    }

    // MARK: - Task Type Keywords
    public enum TaskTypeKeywords {
        // Greenfield indicators
        public static let greenfield = [
            "new app", "new application", "new project", "new system",
            "build a", "create a new", "from scratch", "greenfield",
            "mvp for", "prototype for", "initial version"
        ]

        // Incremental indicators
        public static let incremental = [
            "add", "integrate", "enhance", "improve", "extend",
            "update", "modify", "change", "implement", "feature",
            "to existing", "current system", "our app", "the application"
        ]

        // Bug fix indicators
        public static let bugFix = [
            "fix", "bug", "issue", "problem", "broken", "error",
            "not working", "crash", "fails", "incorrect", "wrong"
        ]

        // Refactor indicators
        public static let refactor = [
            "refactor", "optimize", "clean up", "improve performance",
            "reduce", "simplify", "reorganize", "restructure"
        ]

        // Configuration indicators
        public static let configuration = [
            "configure", "setup", "deploy", "ci/cd", "pipeline",
            "environment", "settings", "config", "initialization"
        ]
    }
}